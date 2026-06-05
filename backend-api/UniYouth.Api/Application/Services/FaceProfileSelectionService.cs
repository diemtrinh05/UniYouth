using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;

namespace UniYouth.Api.Application.Services;

public interface IFaceProfileSelectionService
{
    Task<FaceProfileSelectionResult> ResolveActiveProfileAsync(int userId, CancellationToken cancellationToken = default);
}

public sealed class FaceProfileSelectionResult
{
    public const string ProfileMissingStatus = "ProfileMissing";

    public FaceProfile? FaceProfile { get; init; }

    public string? FaceVerificationStatus { get; init; } = ProfileMissingStatus;

    public bool CleanupApplied { get; init; }

    public IReadOnlyList<int> DeactivatedFaceProfileIds { get; init; } = Array.Empty<int>();

    public bool HasUsableProfile => FaceProfile is not null;
}

public sealed class FaceProfileSelectionService : IFaceProfileSelectionService
{
    private readonly UniYouthDbContext _context;
    private readonly ILogger<FaceProfileSelectionService> _logger;

    public FaceProfileSelectionService(
        UniYouthDbContext context,
        ILogger<FaceProfileSelectionService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<FaceProfileSelectionResult> ResolveActiveProfileAsync(
        int userId,
        CancellationToken cancellationToken = default)
    {
        var activeProfiles = await _context.FaceProfiles
            .Where(profile => profile.UserID == userId && profile.IsActive == true)
            .OrderByDescending(profile => profile.UpdatedDate)
            .ThenByDescending(profile => profile.CreatedDate)
            .ThenByDescending(profile => profile.FaceProfileID)
            .ToListAsync(cancellationToken);

        if (activeProfiles.Count == 0)
        {
            _logger.LogInformation(
                "Face profile missing for user {UserId}: no active FaceProfile found.",
                userId);

            return CreateProfileMissingResult();
        }

        var selectedProfile = activeProfiles[0];
        var deactivatedProfileIds = new List<int>();

        if (activeProfiles.Count > 1)
        {
            var now = DateTime.Now;

            foreach (var duplicateProfile in activeProfiles.Skip(1))
            {
                duplicateProfile.IsActive = false;
                duplicateProfile.UpdatedDate = now;
                deactivatedProfileIds.Add(duplicateProfile.FaceProfileID);
            }

            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogWarning(
                "Detected {DuplicateCount} active FaceProfiles for user {UserId}. Kept FaceProfileID {SelectedFaceProfileId}, deactivated {DeactivatedFaceProfileIds}.",
                activeProfiles.Count,
                userId,
                selectedProfile.FaceProfileID,
                string.Join(", ", deactivatedProfileIds));
        }

        if (!IsUsable(selectedProfile))
        {
            _logger.LogWarning(
                "Face profile missing for user {UserId}: FaceProfileID {FaceProfileId} is active but not usable.",
                userId,
                selectedProfile.FaceProfileID);

            return CreateProfileMissingResult(deactivatedProfileIds);
        }

        return new FaceProfileSelectionResult
        {
            FaceProfile = selectedProfile,
            FaceVerificationStatus = string.Empty,
            CleanupApplied = deactivatedProfileIds.Count > 0,
            DeactivatedFaceProfileIds = deactivatedProfileIds
        };
    }

    private static bool IsUsable(FaceProfile profile)
    {
        return profile.IsActive == true
            && profile.FaceEmbedding is { Length: > 0 };
    }

    private static FaceProfileSelectionResult CreateProfileMissingResult(IReadOnlyList<int>? deactivatedProfileIds = null)
    {
        return new FaceProfileSelectionResult
        {
            FaceProfile = null,
            FaceVerificationStatus = FaceProfileSelectionResult.ProfileMissingStatus,
            CleanupApplied = deactivatedProfileIds is { Count: > 0 },
            DeactivatedFaceProfileIds = deactivatedProfileIds ?? Array.Empty<int>()
        };
    }
}
