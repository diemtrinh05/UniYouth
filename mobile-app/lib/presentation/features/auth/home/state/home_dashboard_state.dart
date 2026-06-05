class HomeDashboardState {
  const HomeDashboardState({
    this.fullName,
    this.avatarUrl,
    this.hasActiveFaceProfile = false,
    this.isLoadingProfile = true,
    this.isLoggingOut = false,
  });

  final String? fullName;
  final String? avatarUrl;
  final bool hasActiveFaceProfile;
  final bool isLoadingProfile;
  final bool isLoggingOut;

  HomeDashboardState copyWith({
    String? fullName,
    bool clearFullName = false,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    bool? hasActiveFaceProfile,
    bool? isLoadingProfile,
    bool? isLoggingOut,
  }) {
    return HomeDashboardState(
      fullName: clearFullName ? null : (fullName ?? this.fullName),
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      hasActiveFaceProfile: hasActiveFaceProfile ?? this.hasActiveFaceProfile,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }
}
