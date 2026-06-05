import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config_service.dart';

typedef LocalIpCandidatesLoader = Future<List<String>> Function();
typedef PortProbe =
    Future<bool> Function(String ip, int port, Duration timeout);
typedef DiscoveryAvailabilityChecker = bool Function();

class LanServerDiscoveryService {
  LanServerDiscoveryService({
    http.Client Function()? httpClientFactory,
    LocalIpCandidatesLoader? localIpCandidatesLoader,
    PortProbe? portProbe,
    DiscoveryAvailabilityChecker? isDiscoveryAvailable,
    int maxParallelRequests = 20,
    Duration requestTimeout = const Duration(milliseconds: 800),
    Duration portProbeTimeout = const Duration(milliseconds: 120),
  }) : _httpClientFactory = httpClientFactory ?? http.Client.new,
       _localIpCandidatesLoader =
           localIpCandidatesLoader ?? _defaultLocalIpCandidatesLoader,
       _portProbe = portProbe ?? _defaultPortProbe,
       _isDiscoveryAvailable = isDiscoveryAvailable ?? _defaultDiscoveryGuard,
       _maxParallelRequests = maxParallelRequests,
       _requestTimeout = requestTimeout,
       _portProbeTimeout = portProbeTimeout;

  static const String healthPath = '/api/Auth/health';
  final http.Client Function() _httpClientFactory;
  final LocalIpCandidatesLoader _localIpCandidatesLoader;
  final PortProbe _portProbe;
  final DiscoveryAvailabilityChecker _isDiscoveryAvailable;
  final int _maxParallelRequests;
  final Duration _requestTimeout;
  final Duration _portProbeTimeout;

  Future<List<String>> getLocalIps() async {
    final candidates = await _localIpCandidatesLoader();
    return candidates.where(_isPrivateIpv4).toList(growable: false);
  }

  Future<String?> getLocalIp() async {
    final candidates = await getLocalIps();
    return candidates.isEmpty ? null : candidates.first;
  }

  Future<bool> testServer(String ip, {http.Client? client}) async {
    final httpClient = client ?? _httpClientFactory();
    try {
      final isPortOpen = await _portProbe(
        ip,
        ApiConfigService.devServerPort,
        _portProbeTimeout,
      );
      if (!isPortOpen) {
        return false;
      }

      final response = await httpClient
          .get(
            Uri.parse(
              'http://$ip:${ApiConfigService.devServerPort}$healthPath',
            ),
          )
          .timeout(_requestTimeout);
      if (_isValidServerResponse(response)) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<LanServerDiscoveryResult> scanSubnet({
    void Function(LanServerDiscoveryProgress progress)? onProgress,
  }) async {
    if (!_isDiscoveryAvailable()) {
      return const LanServerDiscoveryResult(
        isSuccess: false,
        message: 'LAN discovery is not available.',
      );
    }

    final localIps = await getLocalIps();
    if (localIps.isEmpty) {
      return const LanServerDiscoveryResult(
        isSuccess: false,
        message: 'Unable to determine local IP address.',
      );
    }

    final subnetPrefixes = <String>{};
    for (final localIp in localIps) {
      final subnetPrefix = _extractSubnetPrefix(localIp);
      if (subnetPrefix != null) {
        subnetPrefixes.add(subnetPrefix);
      }
    }

    if (subnetPrefixes.isEmpty) {
      return LanServerDiscoveryResult(
        isSuccess: false,
        localIp: localIps.first,
        message: 'Unable to determine subnet from local IP.',
      );
    }

    final candidateIps = <String>[];
    for (final subnetPrefix in subnetPrefixes) {
      for (var index = 1; index <= 254; index++) {
        candidateIps.add('$subnetPrefix.$index');
      }
    }

    final localIp = localIps.first;
    final client = _httpClientFactory();
    var nextIndex = 0;
    var scannedCount = 0;
    String? foundIp;

    Future<void> worker() async {
      while (foundIp == null) {
        if (nextIndex >= candidateIps.length) {
          return;
        }

        final ip = candidateIps[nextIndex];
        nextIndex++;

        if (ip == localIp) {
          scannedCount++;
          onProgress?.call(
            LanServerDiscoveryProgress(
              localIp: localIp,
              currentIp: ip,
              scannedCount: scannedCount,
              totalCount: candidateIps.length,
            ),
          );
          continue;
        }

        final isServer = await testServer(ip, client: client);
        scannedCount++;
        onProgress?.call(
          LanServerDiscoveryProgress(
            localIp: localIp,
            currentIp: ip,
            scannedCount: scannedCount,
            totalCount: candidateIps.length,
          ),
        );
        if (isServer && foundIp == null) {
          foundIp = ip;
          return;
        }
      }
    }

    final workers = List<Future<void>>.generate(
      _resolveWorkerCount(candidateIps.length),
      (_) => worker(),
    );

    await Future.wait(workers);
    client.close();

    final resolvedFoundIp = foundIp;
    if (resolvedFoundIp != null && resolvedFoundIp.isNotEmpty) {
      return LanServerDiscoveryResult(
        isSuccess: true,
        localIp: localIp,
        serverIp: resolvedFoundIp,
        baseUrl: 'http://$resolvedFoundIp:${ApiConfigService.devServerPort}',
        scannedCount: scannedCount,
        message: 'Server found: $resolvedFoundIp',
      );
    }

    return LanServerDiscoveryResult(
      isSuccess: false,
      localIp: localIp,
      scannedCount: scannedCount,
      message: 'No API server found in network',
    );
  }

  int _resolveWorkerCount(int totalIps) {
    if (totalIps <= 0) {
      return 1;
    }
    if (_maxParallelRequests < 1) {
      return 1;
    }
    return _maxParallelRequests < totalIps ? _maxParallelRequests : totalIps;
  }

  bool _isValidServerResponse(http.Response response) {
    if (response.statusCode != 200) {
      return false;
    }

    final rawBody = response.body.trim();
    if (rawBody.isEmpty) {
      return true;
    }

    final Object? decodedBody;
    try {
      decodedBody = jsonDecode(rawBody);
    } on FormatException {
      return true;
    }

    if (decodedBody is! Map) {
      return true;
    }

    final typedBody = decodedBody.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final rawSuccess = typedBody['success'];
    if (rawSuccess is bool) {
      return rawSuccess;
    }
    if (rawSuccess is String) {
      final normalizedSuccess = rawSuccess.trim().toLowerCase();
      if (normalizedSuccess == 'true') {
        return true;
      }
      if (normalizedSuccess == 'false') {
        return false;
      }
    }

    final rawData = typedBody['data'];
    if (rawData is Map) {
      final typedData = rawData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final rawStatus = typedData['status'];
      if (rawStatus is String) {
        return rawStatus.trim().toLowerCase() == 'healthy';
      }
    }

    return true;
  }

  String? _extractSubnetPrefix(String ip) {
    final segments = ip.split('.');
    if (segments.length != 4) {
      return null;
    }
    if (!_isPrivateIpv4(ip)) {
      return null;
    }
    return '${segments[0]}.${segments[1]}.${segments[2]}';
  }

  bool _isPrivateIpv4(String ip) {
    final segments = ip.split('.');
    if (segments.length != 4) {
      return false;
    }

    final octets = <int>[];
    for (final segment in segments) {
      final value = int.tryParse(segment);
      if (value == null || value < 0 || value > 255) {
        return false;
      }
      octets.add(value);
    }

    if (octets[0] == 10) {
      return true;
    }
    if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) {
      return true;
    }
    if (octets[0] == 192 && octets[1] == 168) {
      return true;
    }
    return false;
  }

  static Future<List<String>> _defaultLocalIpCandidatesLoader() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );

    final addresses = <String>[];
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        addresses.add(address.address);
      }
    }
    return addresses;
  }

  static Future<bool> _defaultPortProbe(
    String ip,
    int port,
    Duration timeout,
  ) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      await socket?.close();
    }
  }

  static bool _defaultDiscoveryGuard() => true;
}

class LanServerDiscoveryProgress {
  const LanServerDiscoveryProgress({
    required this.localIp,
    required this.currentIp,
    required this.scannedCount,
    required this.totalCount,
  });

  final String localIp;
  final String currentIp;
  final int scannedCount;
  final int totalCount;
}

class LanServerDiscoveryResult {
  const LanServerDiscoveryResult({
    required this.isSuccess,
    required this.message,
    this.localIp,
    this.serverIp,
    this.baseUrl,
    this.scannedCount = 0,
  });

  final bool isSuccess;
  final String message;
  final String? localIp;
  final String? serverIp;
  final String? baseUrl;
  final int scannedCount;
}
