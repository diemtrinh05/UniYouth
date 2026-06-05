IF OBJECT_ID(N'dbo.SupportConversations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SupportConversations
    (
        ConversationID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SupportConversations PRIMARY KEY,
        StudentUserID INT NOT NULL,
        AssignedToUserID INT NULL,
        Subject NVARCHAR(255) NOT NULL,
        Status TINYINT NOT NULL CONSTRAINT DF_SupportConversations_Status DEFAULT (1),
        Priority TINYINT NOT NULL CONSTRAINT DF_SupportConversations_Priority DEFAULT (1),
        LastMessageAt DATETIME2(0) NULL,
        ClosedAt DATETIME2(0) NULL,
        CreatedDate DATETIME2(0) NOT NULL CONSTRAINT DF_SupportConversations_CreatedDate DEFAULT (SYSDATETIME()),
        UpdatedDate DATETIME2(0) NOT NULL CONSTRAINT DF_SupportConversations_UpdatedDate DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_SupportConversations_Students FOREIGN KEY (StudentUserID) REFERENCES dbo.Users(UserID),
        CONSTRAINT FK_SupportConversations_AssignedTo FOREIGN KEY (AssignedToUserID) REFERENCES dbo.Users(UserID),
        CONSTRAINT CK_SupportConversations_Status CHECK (Status IN (1, 2, 3)),
        CONSTRAINT CK_SupportConversations_Priority CHECK (Priority IN (1, 2, 3))
    );
END;
GO

IF OBJECT_ID(N'dbo.SupportMessages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SupportMessages
    (
        MessageID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SupportMessages PRIMARY KEY,
        ConversationID INT NOT NULL,
        SenderUserID INT NOT NULL,
        MessageType TINYINT NOT NULL CONSTRAINT DF_SupportMessages_MessageType DEFAULT (1),
        Content NVARCHAR(MAX) NOT NULL,
        AttachmentUrl NVARCHAR(500) NULL,
        IsDeleted BIT NOT NULL CONSTRAINT DF_SupportMessages_IsDeleted DEFAULT (0),
        CreatedDate DATETIME2(0) NOT NULL CONSTRAINT DF_SupportMessages_CreatedDate DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_SupportMessages_Conversations FOREIGN KEY (ConversationID) REFERENCES dbo.SupportConversations(ConversationID),
        CONSTRAINT FK_SupportMessages_Senders FOREIGN KEY (SenderUserID) REFERENCES dbo.Users(UserID),
        CONSTRAINT CK_SupportMessages_MessageType CHECK (MessageType IN (1, 2))
    );
END;
GO

IF OBJECT_ID(N'dbo.SupportMessageReads', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SupportMessageReads
    (
        ReadID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SupportMessageReads PRIMARY KEY,
        MessageID INT NOT NULL,
        UserID INT NOT NULL,
        ReadAt DATETIME2(0) NOT NULL CONSTRAINT DF_SupportMessageReads_ReadAt DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_SupportMessageReads_Messages FOREIGN KEY (MessageID) REFERENCES dbo.SupportMessages(MessageID),
        CONSTRAINT FK_SupportMessageReads_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
        CONSTRAINT UQ_SupportMessageReads_MessageID_UserID UNIQUE (MessageID, UserID)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SupportConversations_StudentUserID_Status' AND object_id = OBJECT_ID(N'dbo.SupportConversations'))
BEGIN
    CREATE INDEX IX_SupportConversations_StudentUserID_Status
    ON dbo.SupportConversations(StudentUserID, Status, LastMessageAt DESC);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SupportConversations_AssignedToUserID_Status' AND object_id = OBJECT_ID(N'dbo.SupportConversations'))
BEGIN
    CREATE INDEX IX_SupportConversations_AssignedToUserID_Status
    ON dbo.SupportConversations(AssignedToUserID, Status, LastMessageAt DESC);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SupportConversations_Status_LastMessageAt' AND object_id = OBJECT_ID(N'dbo.SupportConversations'))
BEGIN
    CREATE INDEX IX_SupportConversations_Status_LastMessageAt
    ON dbo.SupportConversations(Status, LastMessageAt DESC);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SupportMessages_ConversationID_CreatedDate' AND object_id = OBJECT_ID(N'dbo.SupportMessages'))
BEGIN
    CREATE INDEX IX_SupportMessages_ConversationID_CreatedDate
    ON dbo.SupportMessages(ConversationID, CreatedDate, MessageID);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SupportMessages_SenderUserID' AND object_id = OBJECT_ID(N'dbo.SupportMessages'))
BEGIN
    CREATE INDEX IX_SupportMessages_SenderUserID
    ON dbo.SupportMessages(SenderUserID);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SupportMessageReads_UserID' AND object_id = OBJECT_ID(N'dbo.SupportMessageReads'))
BEGIN
    CREATE INDEX IX_SupportMessageReads_UserID
    ON dbo.SupportMessageReads(UserID);
END;
GO

