using UniYouth.Api.Application.Services.AttendanceSupport;
using UniYouth.Api.Contracts.DTOs.Attendance;

namespace UniYouth.Api.Tests.Attendance;

public class AttendanceBiometricServiceTests
{
    [Fact]
    public void BuildFaceProbeCandidates_RemovesDuplicatePayloads()
    {
        var request = new CheckInRequestDto
        {
            FaceImageBase64 = "abc",
            FaceImageMimeType = "image/jpeg",
            Liveness = new LivenessCheckDto
            {
                MimeType = "image/jpeg",
                Frames =
                [
                    new LivenessFrameDto { FrameIndex = 0, ImageBase64 = "abc", CapturedAtMs = 0 },
                    new LivenessFrameDto { FrameIndex = 1, ImageBase64 = "def", CapturedAtMs = 200 }
                ]
            }
        };

        var candidates = AttendanceBiometricService.BuildFaceProbeCandidates(request);

        Assert.Equal(2, candidates.Count);
        Assert.Equal("primary", candidates[0].Source);
        Assert.Equal("liveness-1", candidates[1].Source);
    }

    [Fact]
    public void SelectBestFaceVerificationOutcome_PrefersMatchedThenHigherQuality()
    {
        var outcomes = new[]
        {
            new FaceVerificationOutcome { FaceVerificationStatus = "Review", QualityScore = 0.99, FaceConfidence = 0.95 },
            new FaceVerificationOutcome { FaceVerificationStatus = "Matched", QualityScore = 0.70, FaceConfidence = 0.80 },
            new FaceVerificationOutcome { FaceVerificationStatus = "Matched", QualityScore = 0.90, FaceConfidence = 0.70 }
        };

        var selected = AttendanceBiometricService.SelectBestFaceVerificationOutcome(outcomes);

        Assert.Equal("Matched", selected.FaceVerificationStatus);
        Assert.Equal(0.90, selected.QualityScore);
    }
}
