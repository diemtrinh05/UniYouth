import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/config/api_config_service.dart';
import '../../services/network/lan_server_discovery_service.dart';
import '../app/providers/app_provider_graph.dart';

class DevApiConfigScreen extends ConsumerStatefulWidget {
  const DevApiConfigScreen({super.key});

  @override
  ConsumerState<DevApiConfigScreen> createState() => _DevApiConfigScreenState();
}

class _DevApiConfigScreenState extends ConsumerState<DevApiConfigScreen> {
  static const Color _kBackground = Color(0xFFF0F6FF);
  static const Color _kSurface = Colors.white;
  static const Color _kTitle = Color(0xFF0F172A);
  static const Color _kTextMuted = Color(0xFF64748B);
  static const Color _kPrimary = Color(0xFF3B82F6);
  static const Color _kSecondary = Color(0xFF8B5CF6);
  static const Color _kSuccess = Color(0xFF0F9D58);
  static const Color _kWarning = Color(0xFFE53935);
  static const Color _kInfoBg = Color(0xFFF7FAFF);
  static final RegExp _ipv4Pattern = RegExp(
    r'^(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}$',
  );

  late final TextEditingController _serverIpController;
  String? _serverIpError;
  String? _connectionMessage;
  String? _discoveryMessage;
  String? _localIp;
  String? _discoveredServerIp;
  bool _isSaving = false;
  bool _isTesting = false;
  bool _isDiscovering = false;

  ApiConfigService get _apiConfigService => ref.read(apiConfigServiceProvider);
  LanServerDiscoveryService get _discoveryService =>
      ref.read(lanServerDiscoveryServiceProvider);

  @override
  void initState() {
    super.initState();
    _serverIpController = TextEditingController(
      text: _apiConfigService.savedServerIp,
    );
    _serverIpController.addListener(_handleServerIpChanged);
  }

  @override
  void dispose() {
    _serverIpController.removeListener(_handleServerIpChanged);
    _serverIpController.dispose();
    super.dispose();
  }

  String get _previewBaseUrl {
    return _apiConfigService.previewBaseUrl(_serverIpController.text);
  }

  void _handleServerIpChanged() {
    setState(() {
      _serverIpError = _validateServerIp(_serverIpController.text);
      _connectionMessage = null;
      if (!_isDiscovering) {
        _discoveryMessage = null;
      }
    });
  }

  String? _validateServerIp(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (_ipv4Pattern.hasMatch(normalized)) {
      return null;
    }
    return 'Nhập IPv4 hợp lệ hoặc để trống để dùng localhost.';
  }

  Future<void> _saveServerIp() async {
    final validationError = _validateServerIp(_serverIpController.text);
    if (validationError != null) {
      setState(() {
        _serverIpError = validationError;
        _connectionMessage = validationError;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _connectionMessage = null;
    });

    try {
      final baseUrl = await _apiConfigService.saveServerIp(
        _serverIpController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _connectionMessage = 'Đã lưu. Base URL hiện tại: $baseUrl';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu máy chủ API: $baseUrl')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _connectionMessage = 'Lưu thất bại: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _testApi() async {
    final validationError = _validateServerIp(_serverIpController.text);
    if (validationError != null) {
      setState(() {
        _serverIpError = validationError;
        _connectionMessage = validationError;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _connectionMessage = null;
    });

    final result = await _apiConfigService.testConnection(
      serverIp: _serverIpController.text,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _connectionMessage = '${result.message}\n${result.baseUrl}';
      _isTesting = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _autoDiscoverServer() async {
    setState(() {
      _isDiscovering = true;
      _connectionMessage = null;
      _discoveryMessage = 'Đang quét mạng...';
      _localIp = null;
      _discoveredServerIp = null;
    });

    final result = await _discoveryService.scanSubnet(
      onProgress: (progress) {
        if (!mounted) {
          return;
        }
        setState(() {
          _localIp = progress.localIp;
          _discoveryMessage =
              'Đang quét mạng... (${progress.scannedCount}/${progress.totalCount})\nHiện tại: ${progress.currentIp}';
        });
      },
    );

    if (!mounted) {
      return;
    }

    if (result.isSuccess && result.serverIp != null) {
      final baseUrl = await _apiConfigService.saveServerIp(result.serverIp!);
      if (!mounted) {
        return;
      }
      _serverIpController.text = result.serverIp!;
      setState(() {
        _localIp = result.localIp;
        _discoveredServerIp = result.serverIp;
        _discoveryMessage = 'Đã tìm thấy và lưu máy chủ.';
        _connectionMessage = 'Đã lưu. Base URL hiện tại: $baseUrl';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tìm thấy máy chủ: ${result.serverIp}'),
        ),
      );
    } else {
      setState(() {
        _localIp = result.localIp;
        _discoveryMessage = result.message;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }

    if (mounted) {
      setState(() {
        _isDiscovering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSaving || _isTesting || _isDiscovering;

    return Scaffold(
      backgroundColor: _kBackground,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPrimary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kSecondary.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPrimary.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: IconButton.styleFrom(
                        backgroundColor: _kSurface.withValues(alpha: 0.92),
                        foregroundColor: _kTitle,
                        shadowColor: _kPrimary.withValues(alpha: 0.12),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Cấu hình API Dev',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _kTitle,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildHeroCard(),
                const SizedBox(height: 18),
                _buildSectionCard(
                  title: 'Server IP',
                  subtitle:
                      'Nhập IP backend hoặc để trống để dùng localhost.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildServerIpField(isBusy),
                      const SizedBox(height: 16),
                      _buildInfoPanel(
                        label: 'Base URL',
                        value: _previewBaseUrl,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Tự động tìm máy chủ',
                  subtitle:
                      'Quét mạng LAN hiện tại để tự động tìm UniYouth API.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isDiscovering) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            backgroundColor: _kPrimary.withValues(alpha: 0.12),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              _kPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (_localIp != null)
                            _buildInfoChip('IP thiết bị', _localIp!),
                          if (_discoveredServerIp != null)
                            _buildInfoChip(
                              'Máy chủ tìm thấy',
                              _discoveredServerIp!,
                            ),
                        ],
                      ),
                      if (_discoveryMessage != null) ...[
                        if (_localIp != null || _discoveredServerIp != null)
                          const SizedBox(height: 14),
                        _buildStatusCard(
                          message: _discoveryMessage!,
                          type: _resolveStatusType(_discoveryMessage!),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildPrimaryButton(
                  label: 'Lưu',
                  isLoading: _isSaving,
                  onPressed: isBusy ? null : _saveServerIp,
                ),
                const SizedBox(height: 12),
                _buildSecondaryButton(
                  label: 'Tự động tìm máy chủ',
                  icon: Icons.wifi_tethering_rounded,
                  isLoading: _isDiscovering,
                  onPressed: isBusy ? null : _autoDiscoverServer,
                ),
                const SizedBox(height: 12),
                _buildSecondaryButton(
                  label: 'Kiểm tra API',
                  icon: Icons.cloud_done_rounded,
                  isLoading: _isTesting,
                  onPressed: isBusy ? null : _testApi,
                ),
                if (_connectionMessage != null) ...[
                  const SizedBox(height: 18),
                  _buildStatusCard(
                    message: _connectionMessage!,
                    type: _resolveStatusType(_connectionMessage!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _kSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kPrimary, _kSecondary],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.settings_ethernet_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thiết lập mạng phát triển',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kTitle,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Nhập IP thủ công hoặc để ứng dụng tự tìm backend trong mạng LAN.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: _kTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kTitle,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: _kTextMuted,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildServerIpField(bool isBusy) {
    return TextField(
      controller: _serverIpController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: !isBusy,
      style: const TextStyle(
        fontSize: 15,
        color: _kTitle,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: '192.168.1.12',
        errorText: _serverIpError,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 12),
          child: Icon(Icons.router_rounded, color: _kPrimary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(),
        filled: true,
        fillColor: _kInfoBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: _kTitle.withValues(alpha: 0.32),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _kTitle.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kWarning, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kWarning, width: 1.8),
        ),
        errorStyle: const TextStyle(
          fontSize: 12,
          color: _kWarning,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoPanel({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kInfoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: _kTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: _kTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Để trống IP để dùng localhost hoặc API_BASE_URL từ dart-define.',
            style: TextStyle(fontSize: 12, height: 1.45, color: _kTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kInfoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: _kTextMuted,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: onPressed == null
                ? const LinearGradient(
                    colors: [Color(0xFFCBD5E1), Color(0xFFCBD5E1)],
                  )
                : const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [_kPrimary, _kSecondary],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: onPressed == null
                ? const []
                : [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                ),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimary,
          backgroundColor: _kSurface.withValues(alpha: 0.92),
          side: BorderSide(color: _kPrimary.withValues(alpha: 0.16)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String message,
    required _StatusCardType type,
  }) {
    final Color accent;
    final Color background;
    final IconData icon;

    switch (type) {
      case _StatusCardType.success:
        accent = _kSuccess;
        background = const Color(0xFFEFFAF3);
        icon = Icons.check_circle_rounded;
      case _StatusCardType.error:
        accent = _kWarning;
        background = const Color(0xFFFFF1F1);
        icon = Icons.error_outline_rounded;
      case _StatusCardType.info:
        accent = _kPrimary;
        background = const Color(0xFFF1F6FF);
        icon = Icons.info_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusCardType _resolveStatusType(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('success') ||
        normalized.contains('saved') ||
        normalized.contains('found') ||
        normalized.contains('thành công') ||
        normalized.contains('đã lưu') ||
        normalized.contains('đã tìm thấy')) {
      return _StatusCardType.success;
    }
    if (normalized.contains('failed') ||
        normalized.contains('error') ||
        normalized.contains('not found') ||
        normalized.contains('thất bại') ||
        normalized.contains('lỗi') ||
        normalized.contains('không tìm thấy')) {
      return _StatusCardType.error;
    }
    return _StatusCardType.info;
  }
}

enum _StatusCardType { success, error, info }
