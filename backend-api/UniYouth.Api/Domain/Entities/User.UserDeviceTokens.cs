namespace UniYouth.Api.Domain.Entities;

public partial class User
{
    public virtual ICollection<UserDeviceToken> UserDeviceTokens { get; set; } = new List<UserDeviceToken>();
}

