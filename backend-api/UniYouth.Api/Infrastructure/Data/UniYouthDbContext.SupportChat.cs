using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Domain.Entities;

namespace UniYouth.Api.Infrastructure.Data;

public partial class UniYouthDbContext
{
    public virtual DbSet<SupportConversation> SupportConversations { get; set; } = null!;

    public virtual DbSet<SupportMessage> SupportMessages { get; set; } = null!;

    public virtual DbSet<SupportMessageRead> SupportMessageReads { get; set; } = null!;

    private static void ConfigureSupportChat(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<SupportConversation>(entity =>
        {
            entity.HasKey(e => e.ConversationID).HasName("PK_SupportConversations");

            entity.ToTable("SupportConversations");

            entity.HasIndex(e => new { e.StudentUserID, e.Status, e.LastMessageAt }, "IX_SupportConversations_StudentUserID_Status");
            entity.HasIndex(e => new { e.AssignedToUserID, e.Status, e.LastMessageAt }, "IX_SupportConversations_AssignedToUserID_Status");
            entity.HasIndex(e => new { e.Status, e.LastMessageAt }, "IX_SupportConversations_Status_LastMessageAt");

            entity.Property(e => e.Subject).HasMaxLength(255);
            entity.Property(e => e.Status).HasDefaultValue((byte)1);
            entity.Property(e => e.Priority).HasDefaultValue((byte)1);
            entity.Property(e => e.LastMessageAt).HasColumnType("datetime2(0)");
            entity.Property(e => e.ClosedAt).HasColumnType("datetime2(0)");
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(sysdatetime())")
                .HasColumnType("datetime2(0)");
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(sysdatetime())")
                .HasColumnType("datetime2(0)");

            entity.HasOne(d => d.StudentUser).WithMany(p => p.SupportConversationStudentUsers)
                .HasForeignKey(d => d.StudentUserID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SupportConversations_Students");

            entity.HasOne(d => d.AssignedToUser).WithMany(p => p.SupportConversationAssignedToUsers)
                .HasForeignKey(d => d.AssignedToUserID)
                .HasConstraintName("FK_SupportConversations_AssignedTo");
        });

        modelBuilder.Entity<SupportMessage>(entity =>
        {
            entity.HasKey(e => e.MessageID).HasName("PK_SupportMessages");

            entity.ToTable("SupportMessages");

            entity.HasIndex(e => new { e.ConversationID, e.CreatedDate, e.MessageID }, "IX_SupportMessages_ConversationID_CreatedDate");
            entity.HasIndex(e => e.SenderUserID, "IX_SupportMessages_SenderUserID");

            entity.Property(e => e.MessageType).HasDefaultValue((byte)1);
            entity.Property(e => e.AttachmentUrl).HasMaxLength(500);
            entity.Property(e => e.IsDeleted).HasDefaultValue(false);
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(sysdatetime())")
                .HasColumnType("datetime2(0)");

            entity.HasOne(d => d.Conversation).WithMany(p => p.SupportMessages)
                .HasForeignKey(d => d.ConversationID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SupportMessages_Conversations");

            entity.HasOne(d => d.SenderUser).WithMany(p => p.SupportMessages)
                .HasForeignKey(d => d.SenderUserID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SupportMessages_Senders");
        });

        modelBuilder.Entity<SupportMessageRead>(entity =>
        {
            entity.HasKey(e => e.ReadID).HasName("PK_SupportMessageReads");

            entity.ToTable("SupportMessageReads");

            entity.HasIndex(e => new { e.MessageID, e.UserID }, "UQ_SupportMessageReads_MessageID_UserID")
                .IsUnique();
            entity.HasIndex(e => e.UserID, "IX_SupportMessageReads_UserID");

            entity.Property(e => e.ReadAt)
                .HasDefaultValueSql("(sysdatetime())")
                .HasColumnType("datetime2(0)");

            entity.HasOne(d => d.Message).WithMany(p => p.SupportMessageReads)
                .HasForeignKey(d => d.MessageID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SupportMessageReads_Messages");

            entity.HasOne(d => d.User).WithMany(p => p.SupportMessageReads)
                .HasForeignKey(d => d.UserID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SupportMessageReads_Users");
        });
    }
}

