namespace UniYouth.Api.Application.Services.AttendanceSupport;

internal static class AttendanceErrorCodes
{
    public const string QrNotFound = "ATTENDANCE_QR_NOT_FOUND";
    public const string QrInactive = "ATTENDANCE_QR_INACTIVE";
    public const string QrNotStarted = "ATTENDANCE_QR_NOT_STARTED";
    public const string QrExpired = "ATTENDANCE_QR_EXPIRED";
    public const string QrScanLimitReached = "ATTENDANCE_QR_SCAN_LIMIT_REACHED";
    public const string EventNotFound = "ATTENDANCE_EVENT_NOT_FOUND";
    public const string EventNotOngoing = "ATTENDANCE_EVENT_NOT_ONGOING";
    public const string NotRegistered = "ATTENDANCE_NOT_REGISTERED";
    public const string RegistrationCancelled = "ATTENDANCE_REGISTRATION_CANCELLED";
    public const string AlreadyCheckedIn = "ATTENDANCE_ALREADY_CHECKED_IN";
    public const string FaceRetryLimitReached = "ATTENDANCE_FACE_RETRY_LIMIT_REACHED";
    public const string GpsOutOfRange = "ATTENDANCE_GPS_OUT_OF_RANGE";
    public const string FaceMismatch = "ATTENDANCE_FACE_MISMATCH";
    public const string FaceReview = "ATTENDANCE_FACE_REVIEW";
    public const string FaceNoFace = "ATTENDANCE_FACE_NO_FACE";
    public const string FaceMultipleFaces = "ATTENDANCE_FACE_MULTIPLE_FACES";
    public const string FaceBlurry = "ATTENDANCE_FACE_BLURRY";
    public const string FaceInvalidPayload = "ATTENDANCE_FACE_INVALID_PAYLOAD";
    public const string FaceProfileMissing = "ATTENDANCE_FACE_PROFILE_MISSING";
    public const string FacePayloadMissing = "ATTENDANCE_FACE_PAYLOAD_MISSING";
    public const string FaceTechnical = "ATTENDANCE_FACE_TECHNICAL_ERROR";
}
