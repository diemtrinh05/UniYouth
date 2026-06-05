import 'package:flutter_riverpod/legacy.dart';

import 'password_reset_otp_flow_notifier.dart';
import 'password_reset_otp_flow_state.dart';

final passwordResetOtpFlowNotifierProvider =
    StateNotifierProvider<
      PasswordResetOtpFlowNotifier,
      PasswordResetOtpFlowState
    >((ref) {
      return PasswordResetOtpFlowNotifier();
    });
