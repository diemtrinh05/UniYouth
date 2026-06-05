import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniyouth_app/services/network/lan_server_discovery_service.dart';

void main() {
  group('LanServerDiscoveryService', () {
    test('returns first private IPv4 as local IP', () async {
      final service = LanServerDiscoveryService(
        localIpCandidatesLoader: () async => <String>[
          '8.8.8.8',
          '169.254.1.10',
          '192.168.1.25',
        ],
        isDiscoveryAvailable: () => true,
      );

      final localIp = await service.getLocalIp();

      expect(localIp, '192.168.1.25');
    });

    test('validates server from health JSON response', () async {
      final service = LanServerDiscoveryService(
        isDiscoveryAvailable: () => true,
        portProbe: (ip, port, timeout) async => true,
        httpClientFactory: () => MockClient((request) async {
          expect(request.url.path, LanServerDiscoveryService.healthPath);
          return http.Response(
            '{"success":true,"message":"OK","data":{"status":"healthy","service":"Authentication"}}',
            200,
          );
        }),
      );

      final isServer = await service.testServer('192.168.1.12');

      expect(isServer, isTrue);
    });

    test(
      'scanSubnet finds matching server before scanning every host',
      () async {
        var requestCount = 0;
        final service = LanServerDiscoveryService(
          localIpCandidatesLoader: () async => <String>['192.168.1.25'],
          isDiscoveryAvailable: () => true,
          portProbe: (ip, port, timeout) async => ip == '192.168.1.12',
          maxParallelRequests: 1,
          httpClientFactory: () => MockClient((request) async {
            requestCount++;
            expect(request.url.path, LanServerDiscoveryService.healthPath);
            if (request.url.host == '192.168.1.12') {
              return http.Response(
                '{"success":true,"message":"OK","data":{"status":"healthy"}}',
                200,
              );
            }
            return http.Response('not-found', 404);
          }),
        );

        final result = await service.scanSubnet();

        expect(result.isSuccess, isTrue);
        expect(result.localIp, '192.168.1.25');
        expect(result.serverIp, '192.168.1.12');
        expect(result.baseUrl, 'http://192.168.1.12:5160');
        expect(requestCount, lessThan(254));
      },
    );

    test('scanSubnet returns not found when no server matches', () async {
      final service = LanServerDiscoveryService(
        localIpCandidatesLoader: () async => <String>['192.168.1.25'],
        isDiscoveryAvailable: () => true,
        portProbe: (ip, port, timeout) async => false,
        maxParallelRequests: 1,
        httpClientFactory: () => MockClient((request) async {
          return http.Response('not-found', 404);
        }),
      );

      final result = await service.scanSubnet();

      expect(result.isSuccess, isFalse);
      expect(result.message, 'No API server found in network');
    });

    test('rejects unhealthy JSON response', () async {
      final service = LanServerDiscoveryService(
        isDiscoveryAvailable: () => true,
        portProbe: (ip, port, timeout) async => true,
        httpClientFactory: () => MockClient((request) async {
          return http.Response(
            '{"success":false,"message":"Unavailable","data":{"status":"unhealthy"}}',
            200,
          );
        }),
      );

      final isServer = await service.testServer('192.168.1.12');

      expect(isServer, isFalse);
    });

    test(
      'scanSubnet checks all private subnets from local interfaces',
      () async {
        final service = LanServerDiscoveryService(
          localIpCandidatesLoader: () async => <String>[
            '10.0.0.8',
            '192.168.1.25',
          ],
          isDiscoveryAvailable: () => true,
          portProbe: (ip, port, timeout) async => ip == '192.168.1.12',
          maxParallelRequests: 1,
          httpClientFactory: () => MockClient((request) async {
            if (request.url.host == '192.168.1.12') {
              return http.Response(
                '{"success":true,"message":"OK","data":{"status":"healthy"}}',
                200,
              );
            }
            return http.Response('not-found', 404);
          }),
        );

        final result = await service.scanSubnet();

        expect(result.isSuccess, isTrue);
        expect(result.serverIp, '192.168.1.12');
      },
    );
  });
}
