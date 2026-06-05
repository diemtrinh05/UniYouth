class AttendanceQrScanPageArgs {
  const AttendanceQrScanPageArgs({
    this.popOnSuccess = false,
    this.enableFaceVerification = false,
  });

  final bool popOnSuccess;
  final bool enableFaceVerification;
}
