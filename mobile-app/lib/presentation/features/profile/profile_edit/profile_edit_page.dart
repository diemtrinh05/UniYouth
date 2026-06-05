import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../core/utils/validators/profile_validators.dart';
import '../../../../../domain/usecases/profile/get_my_profile_usecase.dart';
import '../../../../../domain/usecases/profile/get_position_options_usecase.dart';
import '../../../../../domain/usecases/profile/update_my_profile_usecase.dart';
import 'state/profile_edit_notifier.dart';
import 'state/profile_edit_provider.dart';
import 'state/profile_edit_state.dart';

const _kBlue = Color(0xFF1565C0);
const _kBlueDark = Color(0xFF0D47A1);
const _kBlueMid = Color(0xFF1976D2);
const _kBlueSky = Color(0xFF42A5F5);
const _kBlueLight = Color(0xFFE3F2FD);
const _kBg = Color(0xFFF0F7FF);
const _kTextDark = Color(0xFF0D1B2A);
const _kTextMid = Color(0xFF546E7A);
const _kError = Color(0xFFC62828);

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.initialProfile,
    required this.getPositionOptionsUseCase,
    required this.updateMyProfileUseCase,
  });

  final MyProfile initialProfile;
  final GetPositionOptionsUseCase getPositionOptionsUseCase;
  final UpdateMyProfileUseCase updateMyProfileUseCase;

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarUrlController;
  late final TextEditingController _addressController;
  late final TextEditingController _unitNameController;
  late final TextEditingController _instituteNameController;
  late final ProfileEditNotifierDependencies _profileEditDependencies;
  late final StateNotifierProvider<ProfileEditNotifier, ProfileEditState>
  _profileEditStateProvider;

  List<PositionOption> _positionOptions = const [];
  bool _isLoadingPositions = true;
  String? _positionOptionsError;
  int? _selectedPositionId;

  ProfileEditState get _profileEditState => ref.read(_profileEditStateProvider);
  bool get _isSubmitting => _profileEditState.isSubmitting;
  bool? get _gender => _profileEditState.gender;
  DateTime? get _dateOfBirth => _profileEditState.dateOfBirth;
  DateTime? get _joinDate => _profileEditState.joinDate;
  String? get _dateOfBirthError => _profileEditState.dateOfBirthError;
  String? get _submitMessage => _profileEditState.submitMessage;
  String? get _fullNameBackendError => _profileEditState.fullNameBackendError;
  String? get _phoneBackendError => _profileEditState.phoneBackendError;
  String? get _avatarUrlBackendError => _profileEditState.avatarUrlBackendError;
  String? get _addressBackendError => _profileEditState.addressBackendError;
  String? get _instituteIdBackendError =>
      _profileEditState.instituteIdBackendError;
  String? get _positionIdBackendError =>
      _profileEditState.positionIdBackendError;
  String? get _genderBackendError => _profileEditState.genderBackendError;
  String? get _dateOfBirthBackendError =>
      _profileEditState.dateOfBirthBackendError;
  String? get _joinDateBackendError => _profileEditState.joinDateBackendError;

  PositionOption? get _selectedPosition {
    for (final option in _positionOptions) {
      if (option.positionId == _selectedPositionId) {
        return option;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _fullNameController = TextEditingController(
      text: (profile.fullName ?? '').trim(),
    );
    _phoneController = TextEditingController(
      text: (profile.phone ?? '').trim(),
    );
    _avatarUrlController = TextEditingController(
      text: (profile.avatarUrl ?? '').trim(),
    );
    _addressController = TextEditingController(
      text: (profile.address ?? '').trim(),
    );
    _unitNameController = TextEditingController(
      text: (profile.unitName ?? '').trim(),
    );
    _instituteNameController = TextEditingController(
      text: (profile.instituteName ?? '').trim(),
    );
    _selectedPositionId = profile.positionId;

    _profileEditDependencies = ProfileEditNotifierDependencies(
      initialProfile: widget.initialProfile,
      updateMyProfileUseCase: widget.updateMyProfileUseCase,
    );
    _profileEditStateProvider = profileEditNotifierByDependenciesProvider(
      _profileEditDependencies,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadPositionOptions();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    _addressController.dispose();
    _unitNameController.dispose();
    _instituteNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPositionOptions() async {
    setState(() {
      _isLoadingPositions = true;
      _positionOptionsError = null;
    });

    try {
      final options = await widget.getPositionOptionsUseCase();
      if (!mounted) {
        return;
      }

      setState(() {
        _positionOptions = options;
        final hasSelected = options.any(
          (option) => option.positionId == _selectedPositionId,
        );
        if (!hasSelected) {
          _selectedPositionId = null;
        }
        _syncDerivedOrganizationFields();
        _isLoadingPositions = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _positionOptionsError =
            'Không tải được danh sách chức vụ. Vui lòng thử lại.';
        _syncDerivedOrganizationFields();
        _isLoadingPositions = false;
      });
    }
  }

  void _syncDerivedOrganizationFields() {
    final selectedPosition = _selectedPosition;
    if (selectedPosition == null) {
      _unitNameController.text = (widget.initialProfile.unitName ?? '').trim();
      _instituteNameController.text =
          (widget.initialProfile.instituteName ?? '').trim();
      return;
    }

    _unitNameController.text = selectedPosition.unitName.trim();
    _instituteNameController.text = (selectedPosition.instituteName ?? '')
        .trim();
  }

  String? _validateFullName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Họ và tên là bắt buộc';
    }
    if (text.length < 2) {
      return 'Họ và tên tối thiểu 2 ký tự';
    }
    if (text.length > 100) {
      return 'Họ và tên tối đa 100 ký tự';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    final text = (value ?? '').trim();
    if (text.length > 255) {
      return 'Địa chỉ tối đa 255 ký tự';
    }
    return null;
  }

  bool _validateDateOfBirthBeforeSubmit() {
    return ref
        .read(_profileEditStateProvider.notifier)
        .validateDateOfBirthBeforeSubmit();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) {
      return;
    }
    ref
        .read(_profileEditStateProvider.notifier)
        .setDateOfBirth(DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    ref
        .read(_profileEditStateProvider.notifier)
        .setJoinDate(DateTime(picked.year, picked.month, picked.day));
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Chưa chọn';
    }
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final isValid = _formKey.currentState?.validate() ?? false;
    final isDateValid = _validateDateOfBirthBeforeSubmit();
    if (!isValid || !isDateValid) {
      return;
    }

    final didSucceed = await ref
        .read(_profileEditStateProvider.notifier)
        .submit(
          fullNameText: _fullNameController.text,
          phoneText: _phoneController.text,
          avatarUrlText: _avatarUrlController.text,
          addressText: _addressController.text,
          positionId: _selectedPositionId,
          instituteId: _selectedPosition?.instituteId,
        );
    if (!mounted) {
      return;
    }
    if (didSucceed) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
      _profileEditStateProvider.select(
        (state) => (
          state.isSubmitting,
          state.gender,
          state.dateOfBirth,
          state.joinDate,
          state.dateOfBirthError,
          state.submitMessage,
          state.fullNameBackendError,
          state.phoneBackendError,
          state.avatarUrlBackendError,
          state.addressBackendError,
          state.instituteIdBackendError,
          state.positionIdBackendError,
          state.genderBackendError,
          state.dateOfBirthBackendError,
          state.joinDateBackendError,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: _kBg,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: _kTextDark,
              elevation: 0,
              title: const Text(
                'Chỉnh sửa hồ sơ',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: _kTextDark,
                ),
              ),
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  const expandedHeight = 130.0;
                  final topPadding = MediaQuery.of(context).padding.top;
                  final collapsedHeight = topPadding + kToolbarHeight;
                  final t =
                      ((constraints.maxHeight - collapsedHeight) /
                              (expandedHeight - collapsedHeight))
                          .clamp(0.0, 1.0);

                  return FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kBlueDark, _kBlueMid],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Opacity(
                              opacity: t,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Chỉnh sửa hồ sơ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cập nhật thông tin cá nhân của bạn',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(
                      icon: Icons.person_rounded,
                      title: 'Thông tin cơ bản',
                    ),
                    const SizedBox(height: 12),
                    _FormCard(
                      children: [
                        _StyledField(
                          controller: _fullNameController,
                          label: 'Họ và tên *',
                          icon: Icons.badge_rounded,
                          backendErrorText: _fullNameBackendError,
                          onChanged: (_) {
                            if (_fullNameBackendError == null) {
                              return;
                            }
                            ref
                                .read(_profileEditStateProvider.notifier)
                                .clearBackendError(
                                  ProfileEditBackendField.fullName,
                                );
                          },
                          validator: _validateFullName,
                        ),
                        const _FieldDivider(),
                        _StyledField(
                          controller: _phoneController,
                          label: 'Số điện thoại',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          backendErrorText: _phoneBackendError,
                          onChanged: (_) {
                            if (_phoneBackendError == null) {
                              return;
                            }
                            ref
                                .read(_profileEditStateProvider.notifier)
                                .clearBackendError(
                                  ProfileEditBackendField.phone,
                                );
                          },
                          validator: ProfileValidators.validatePhone,
                        ),
                        const _FieldDivider(),
                        _GenderPicker(
                          value: _gender,
                          errorText: _genderBackendError,
                          onChanged: (value) {
                            ref
                                .read(_profileEditStateProvider.notifier)
                                .setGender(value);
                          },
                        ),
                        const _FieldDivider(),
                        _DatePickerTile(
                          label: 'Ngày sinh *',
                          icon: Icons.cake_rounded,
                          value: _formatDate(_dateOfBirth),
                          errorText:
                              _dateOfBirthBackendError ?? _dateOfBirthError,
                          onTap: _pickDateOfBirth,
                        ),
                        const _FieldDivider(),
                        _StyledField(
                          controller: _addressController,
                          label: 'Địa chỉ',
                          icon: Icons.home_rounded,
                          maxLines: 2,
                          backendErrorText: _addressBackendError,
                          onChanged: (_) {
                            if (_addressBackendError == null) {
                              return;
                            }
                            ref
                                .read(_profileEditStateProvider.notifier)
                                .clearBackendError(
                                  ProfileEditBackendField.address,
                                );
                          },
                          validator: _validateAddress,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionHeader(
                      icon: Icons.school_rounded,
                      title: 'Thông tin học tập',
                    ),
                    const SizedBox(height: 12),
                    _FormCard(
                      children: [
                        _PositionDropdownField(
                          label: 'Chức vụ',
                          icon: Icons.work_rounded,
                          items: _positionOptions,
                          value: _selectedPositionId,
                          isLoading: _isLoadingPositions,
                          loadError: _positionOptionsError,
                          backendErrorText: _positionIdBackendError,
                          onRetry: _loadPositionOptions,
                          onChanged: (value) {
                            setState(() {
                              _selectedPositionId = value;
                              _syncDerivedOrganizationFields();
                            });
                            ref
                                .read(_profileEditStateProvider.notifier)
                                .clearBackendError(
                                  ProfileEditBackendField.positionId,
                                );
                            ref
                                .read(_profileEditStateProvider.notifier)
                                .clearBackendError(
                                  ProfileEditBackendField.instituteId,
                                );
                          },
                        ),
                        const _FieldDivider(),
                        _ReadOnlyInfoTile(
                          controller: _unitNameController,
                          label: 'Đơn vị',
                          icon: Icons.business_rounded,
                        ),
                        const _FieldDivider(),
                        _ReadOnlyInfoTile(
                          controller: _instituteNameController,
                          label: 'Viện',
                          icon: Icons.account_balance_rounded,
                          errorText: _instituteIdBackendError,
                        ),
                        const _FieldDivider(),
                        _DatePickerTile(
                          label: 'Ngày tham gia',
                          icon: Icons.event_available_rounded,
                          value: _formatDate(_joinDate),
                          errorText: _joinDateBackendError,
                          onTap: _pickJoinDate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionHeader(
                      icon: Icons.image_rounded,
                      title: 'Ảnh đại diện',
                    ),
                    const SizedBox(height: 12),
                    _FormCard(
                      children: [
                        _StyledField(
                          controller: _avatarUrlController,
                          label: 'URL ảnh đại diện',
                          icon: Icons.link_rounded,
                          keyboardType: TextInputType.url,
                          backendErrorText: _avatarUrlBackendError,
                          onChanged: (_) {
                            if (_avatarUrlBackendError == null) {
                              return;
                            }
                            ref
                                .read(_profileEditStateProvider.notifier)
                                .clearBackendError(
                                  ProfileEditBackendField.avatarUrl,
                                );
                          },
                          validator: ProfileValidators.validateAvatarUrl,
                        ),
                      ],
                    ),
                    if (_submitMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kError.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _kError.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: _kError,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _submitMessage!,
                                style: const TextStyle(
                                  color: _kError,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _isSubmitting || _isLoadingPositions
                          ? null
                          : _submit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: (_isSubmitting || _isLoadingPositions)
                              ? null
                              : const LinearGradient(
                                  colors: [_kBlue, _kBlueSky],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: (_isSubmitting || _isLoadingPositions)
                              ? _kBlueLight
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: (_isSubmitting || _isLoadingPositions)
                              ? null
                              : [
                                  BoxShadow(
                                    color: _kBlue.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: (_isSubmitting || _isLoadingPositions)
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: _kBlue,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.save_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Lưu thay đổi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _kBlueLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _kBlue, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _kTextDark,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: _kBlueLight,
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.backendErrorText,
    this.onChanged,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final String? backendErrorText;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        readOnly: readOnly,
        style: TextStyle(
          fontSize: 14,
          color: readOnly ? _kTextMid : _kTextDark,
          fontWeight: readOnly ? FontWeight.w600 : FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: _kTextMid),
          prefixIcon: Icon(icon, size: 19, color: _kBlue),
          errorText: backendErrorText,
          border: InputBorder.none,
          errorStyle: const TextStyle(fontSize: 11, color: _kError),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _PositionDropdownField extends StatelessWidget {
  const _PositionDropdownField({
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.isLoading,
    required this.loadError,
    required this.onChanged,
    required this.onRetry,
    this.backendErrorText,
  });

  final String label;
  final IconData icon;
  final List<PositionOption> items;
  final int? value;
  final bool isLoading;
  final String? loadError;
  final ValueChanged<int?> onChanged;
  final Future<void> Function() onRetry;
  final String? backendErrorText;

  @override
  Widget build(BuildContext context) {
    final effectiveError = loadError ?? backendErrorText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: _kTextMid),
          prefixIcon: Icon(icon, size: 19, color: _kBlue),
          border: InputBorder.none,
          errorText: effectiveError,
          errorStyle: const TextStyle(fontSize: 11, color: _kError),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: items.any((item) => item.positionId == value)
                      ? value
                      : null,
                  isExpanded: true,
                  hint: Text(
                    isLoading ? 'Đang tải chức vụ...' : 'Chọn chức vụ',
                    style: const TextStyle(fontSize: 14, color: _kTextMid),
                  ),
                  items: items
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item.positionId,
                          child: Text(
                            item.positionName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _kTextDark,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: isLoading ? null : onChanged,
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
              )
            else if (loadError != null)
              TextButton(onPressed: onRetry, child: const Text('Tải lại')),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyInfoTile extends StatelessWidget {
  const _ReadOnlyInfoTile({
    required this.controller,
    required this.label,
    required this.icon,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _StyledField(
      controller: controller,
      label: label,
      icon: icon,
      readOnly: true,
      backendErrorText: errorText,
    );
  }
}

class _GenderPicker extends StatelessWidget {
  const _GenderPicker({
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final bool? value;
  final ValueChanged<bool?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wc_rounded, size: 19, color: _kBlue),
              const SizedBox(width: 12),
              const Text(
                'Giới tính',
                style: TextStyle(fontSize: 13, color: _kTextMid),
              ),
              const Spacer(),
              _GenderOption(
                label: 'Nam',
                icon: Icons.male_rounded,
                selected: value == true,
                color: const Color(0xFF1565C0),
                onTap: () => onChanged(value == true ? null : true),
              ),
              const SizedBox(width: 8),
              _GenderOption(
                label: 'Nữ',
                icon: Icons.female_rounded,
                selected: value == false,
                color: const Color(0xFFAD1457),
                onTap: () => onChanged(value == false ? null : false),
              ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 31),
              child: Text(
                errorText!,
                style: const TextStyle(fontSize: 11, color: _kError),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : _kBlueLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : _kTextMid),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? color : _kTextMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: _kBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontSize: 12, color: _kTextMid),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          color: value == 'Chưa chọn' ? _kTextMid : _kTextDark,
                          fontWeight: value == 'Chưa chọn'
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _kBlueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Chọn',
                    style: TextStyle(
                      fontSize: 11,
                      color: _kBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (errorText != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 31),
                child: Text(
                  errorText!,
                  style: const TextStyle(fontSize: 11, color: _kError),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
