import '../../../../../../domain/usecases/profile/get_my_profile_usecase.dart';

class ProfileViewState {
  const ProfileViewState({
    this.isLoading = true,
    this.isUploadingAvatar = false,
    this.isDeletingAvatar = false,
    this.isEnrollingFace = false,
    this.errorMessage,
    this.profile,
    this.feedbackMessage,
  });

  final bool isLoading;
  final bool isUploadingAvatar;
  final bool isDeletingAvatar;
  final bool isEnrollingFace;
  final String? errorMessage;
  final MyProfile? profile;
  final String? feedbackMessage;

  ProfileViewState copyWith({
    bool? isLoading,
    bool? isUploadingAvatar,
    bool? isDeletingAvatar,
    bool? isEnrollingFace,
    String? errorMessage,
    bool clearErrorMessage = false,
    MyProfile? profile,
    bool clearProfile = false,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return ProfileViewState(
      isLoading: isLoading ?? this.isLoading,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      isDeletingAvatar: isDeletingAvatar ?? this.isDeletingAvatar,
      isEnrollingFace: isEnrollingFace ?? this.isEnrollingFace,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      profile: clearProfile ? null : (profile ?? this.profile),
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }
}
