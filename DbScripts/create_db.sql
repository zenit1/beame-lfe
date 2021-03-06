USE [LfeData]
GO
/****** Object:  User [LfeUser]    Script Date: 15/08/2017 14:29:06 ******/
CREATE USER [LfeUser] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[db_owner]
GO
/****** Object:  FullTextCatalog [CoursesCatalog]    Script Date: 15/08/2017 14:29:06 ******/
CREATE FULLTEXT CATALOG [CoursesCatalog]WITH ACCENT_SENSITIVITY = OFF

GO
/****** Object:  UserDefinedFunction [dbo].[f_GuidFix]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
In service of the logger
The function converts from string to GUID, in case the string is empty it returns null
Come as solutuin to problematic casting of empty strings that come from the logger                     */
CREATE FUNCTION [dbo].[f_GuidFix]
	(/* the actual guid as string 
	It seems that maximum length of it is 38
	may be a problem if get converted in another type
	*/ 
		@Guid nvarchar(40) = NULL
	)
RETURNS uniqueidentifier
AS
BEGIN
/* compare the empty string*/
Declare @empty  varchar(1) = '';

	/* compare*/
	if (@Guid = @empty)
	/*  if empty string return NULL becouse it suppose to be null in the logger call */
		RETURN NULL
	else 
	/* Its not null? so let cast it to GUID*/
		RETURN CAST(@Guid AS uniqueidentifier)

		/* never get here*/
		return null
	END


GO
/****** Object:  UserDefinedFunction [dbo].[fn_BASE_GetUrlHostName]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-11-20
-- Description:	Extract host from given url
-- =============================================
CREATE FUNCTION [dbo].[fn_BASE_GetUrlHostName]
(
	@WebUrl NVARCHAR(1000)
)
RETURNS NVARCHAR(100)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @HostName NVARCHAR(100),
			@Protocol VARCHAR(10), 
			@RawUrl NVARCHAR(1000)

	SELECT @Protocol = SUBSTRING(@WebUrl, 0,CHARINDEX('://', @WebUrl) + 3)
	SELECT @RawUrl = SUBSTRING(@WebUrl, CHARINDEX('://', @WebUrl) + 3, 999)
	SELECT @HostName = @Protocol + CASE WHEN CHARINDEX('/', @RawUrl) > 0 THEN SUBSTRING(@RawUrl,0,CHARINDEX('/', @RawUrl)) ELSE @RawUrl END

	
	RETURN @HostName

END

GO
/****** Object:  UserDefinedFunction [dbo].[fn_BILL_GetItemPrice]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-5-25
-- Description:	Get item price
-- =============================================
CREATE FUNCTION [dbo].[fn_BILL_GetItemPrice]
(
	@ItemId INT
	,@ItemTypeId TINYINT
	,@CurrencyId SMALLINT	
	,@PriceTypeId TINYINT
	,@PeriodTypeID TINYINT = NULL
)
RETURNS MONEY
AS
BEGIN
	DECLARE @Price MONEY

		SELECT TOP(1) @Price = Price
		FROM [dbo].[BILL_ItemsPriceList]
		WHERE (ItemId = @ItemId)
				AND (ItemTypeId = @ItemTypeId)
				AND (CurrencyId = @CurrencyId)
				AND (PriceTypeId = @PriceTypeId)
				AND ((@PeriodTypeID IS NULL AND PeriodTypeId IS NULL) OR (@PeriodTypeID IS NOT NULL AND PeriodTypeId=@PeriodTypeID))
				AND (IsDeleted = 0)
		ORDER BY PriceLineId DESC
	
	RETURN @Price

END

GO
/****** Object:  UserDefinedFunction [dbo].[fn_USER_CountByRole]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-18
-- Description:	Count users by role
-- =============================================
CREATE FUNCTION [dbo].[fn_USER_CountByRole]
    (
      @RoleName NVARCHAR(256)
    )
RETURNS INT
AS
    BEGIN
	
        DECLARE @Count INT

	
        SELECT  @Count = COUNT(u.UserId)
        FROM    webpages_UsersInRoles AS u
                INNER JOIN webpages_Roles AS r ON u.RoleId = r.RoleId
        WHERE   ( r.RoleName = @RoleName )
	
        RETURN @Count

    END

GO
/****** Object:  UserDefinedFunction [dbo].[fn_USER_IsAdmin]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-10-22
-- Description:	Check if User is admin
-- =============================================
CREATE FUNCTION [dbo].[fn_USER_IsAdmin]
(
	@UserId INT
)
RETURNS BIT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @IsAdmin BIT,
			@SystemRoleId INT = 1,
			@AdminRoleId INT  = 2 ,
			@TesterRoleId INT = 64

	
	IF EXISTS(SELECT        1
				FROM dbo.webpages_UsersInRoles AS r INNER JOIN
                         dbo.UserProfile AS u ON r.UserId = u.UserId
					WHERE (r.RoleId  IN (@SystemRoleId,@AdminRoleId,@TesterRoleId) )
							AND (u.RefUserId = @UserId))
		SET @IsAdmin = 1
	ELSE
		SET @IsAdmin = 0

	RETURN @IsAdmin

END

GO
/****** Object:  UserDefinedFunction [dbo].[fn_WS_IsStoreAffiliate]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-10-22
-- Description:	Check if store Affiliate
-- =============================================
CREATE FUNCTION [dbo].[fn_WS_IsStoreAffiliate] ( @StoreId INT )
RETURNS BIT
AS
    BEGIN

        DECLARE @Total INT ,
                @IsAffiliate BIT 

        SELECT  @Total = ISNULL(s.items, 0)
        FROM    dbo.WebStores AS ws
                LEFT OUTER JOIN ( SELECT    COUNT(wi.ItemId) AS items ,
                                            wi.StoreID
                                  FROM      dbo.vw_WS_Items AS wi
                                  WHERE     ( wi.AuthorID <> wi.OwnerUserID )
                                  GROUP BY  wi.StoreID
                                ) AS s ON s.StoreID = ws.StoreID
        WHERE   ( ws.StoreId = @StoreId )
	
	

        IF ( @Total > 0 )
            SET @IsAffiliate = 1
        ELSE
            SET @IsAffiliate = 0

        RETURN @IsAffiliate

    END

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CHIMP_GetAuthorSubscribers]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alexander Shnirman	
-- Create date: 24.08.2014 
-- Description:	Gets all Subscribers for author
-- =============================================
CREATE FUNCTION [dbo].[tvf_CHIMP_GetAuthorSubscribers]
(
	@authorId INT
)
RETURNS 
	@ResultTable TABLE (
		UserId INT NOT NULL, 
		Email NVARCHAR(150) NOT NULL, 
		AddOn DATETIME NOT NULL,
		StatusId TINYINT NOT NULL,
		FirstName NVARCHAR(50) NULL,
		LastName NVARCHAR(50) NULL
	)
AS
BEGIN

	INSERT @ResultTable	

		SELECT	u.Id AS UserId,
				u.Email ,
				MIN(uc.AddOn) AS AddOn,
				MIN(uc.StatusId) AS StatusId,
				u.FirstName,
				u.LastName
		
		FROM    dbo.USER_Courses AS uc
				INNER JOIN dbo.Users AS u ON uc.UserId = u.Id
				INNER JOIN dbo.Courses AS c ON uc.CourseId = c.Id
		
		WHERE   c.AuthorUserId = @authorId 
				AND u.Email NOT IN (SELECT Email FROM CHIMP_Rejects WHERE UserId = @authorId)
		
		GROUP BY  u.Id ,
				u.Email ,
				u.FirstName,
				u.LastName

	
	RETURN 
END

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CHIMP_GetItemSubscribers]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alexander Shnirman	
-- Create date: 24.08.2014 
-- Description:	Gets Subscribers per course or bundle
-- =============================================
CREATE FUNCTION [dbo].[tvf_CHIMP_GetItemSubscribers]
(
	@itemId INT,
	@itemType INT -- 1: course, 2: bundle
)
RETURNS 
	@ResultTable TABLE (
		UserId INT NOT NULL, 
		Email NVARCHAR(150) NOT NULL, 
		AddOn DATETIME NOT NULL,
		StatusId TINYINT NOT NULL,
		FirstName NVARCHAR(50) NULL,
		LastName NVARCHAR(50) NULL
	)
AS
BEGIN
	DECLARE @authorId INT;

	IF (@itemType = 1)
	BEGIN
		SELECT @authorId = AuthorUserId FROM Courses WHERE Id = @itemId

		INSERT @ResultTable	
				SELECT c.UserId, u.Email, MIN(c.AddOn) AddOn, c.StatusId,u.FirstName,u.LastName
				FROM USER_Courses c	
					INNER JOIN Users u ON c.UserId = u.Id
				WHERE CourseId = @itemId 
					  AND u.Email NOT IN (SELECT Email FROM CHIMP_Rejects WHERE UserId = @authorId)
				GROUP BY c.UserId, c.CourseId, u.Email, c.StatusId,u.FirstName,u.LastName
	END

	IF (@itemType = 2)
	BEGIN
		SELECT @authorId = AuthorId FROM CRS_Bundles WHERE BundleId = @itemId

		INSERT @ResultTable	
				SELECT b.UserId, u.Email, MIN(b.AddOn) AddOn, b.StatusId,u.FirstName,u.LastName
				FROM USER_Bundles b	
					INNER JOIN Users u ON b.UserId = u.Id
				WHERE BundleId = @itemId 
					  AND u.Email NOT IN (SELECT Email FROM CHIMP_Rejects WHERE UserId = @authorId)
				GROUP BY b.UserId, b.BundleId, u.Email, b.StatusId,u.FirstName,u.LastName -- just in case
	END

	
	RETURN 
END

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CHIMP_GetMissingSegments]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alexander Shnirman	
-- Create date: 20.08.2014
-- =============================================
CREATE FUNCTION [dbo].[tvf_CHIMP_GetMissingSegments]
(
	@userId INT,
	@listId INT
)
RETURNS 
	@ResultTable TABLE (
		ListId INT NOT NULL, 
		SegmentTypeId TINYINT NOT NULL, 
		[Uid] VARCHAR(100), 
		ItemTypeId INT,
		ItemId INT,
		ItemName NVARCHAR(256)
	)
AS
BEGIN
DECLARE 
		@DYNAMIC_SEGMENT_TYPE INT = 3, -- value "Item" from table [dbo].[CHIMP_SegmentTypesLOV]	
		@COURSE_TYPE INT = 1,
		@BUNDLE_TYPE INT = 2

	--SELECT @listId = ListId FROM CHIMP_UserLists WHERE UserId = @userId
	IF (@listId IS NULL OR @userId IS NULL) RETURN;

	
	INSERT @ResultTable

				-- GETS ALL MISSING STATIC SEGMENTS 
		SELECT  @listId ListId ,
				t.SegmentTypeId ,
				s.Uid ,
				NULL AS ItemTypeId,
				s.CourseId AS ItemId,
				NULL AS ItemName
		FROM    CHIMP_SegmentTypesLOV t
				LEFT OUTER JOIN CHIMP_ListSegments s ON t.SegmentTypeId = s.SegmentTypeId
														AND s.ListId = @listId
		WHERE   t.IsStatic = 1
				AND s.SegmentId IS NULL

				UNION ALL

				-- GETS ALL MISSING DYNAMIC SEGMENTS FOR COURSES
		SELECT  @listId ListId ,
				@DYNAMIC_SEGMENT_TYPE SegmentTypeId ,
				s.Uid ,
				@COURSE_TYPE AS ItemTypeId,
				c.Id AS ItemId ,
				c.CourseName AS ItemName
		FROM    Courses c
				LEFT OUTER JOIN CHIMP_ListSegments s ON c.Id = s.CourseId
		WHERE   c.AuthorUserId = @userId
				AND s.SegmentId IS NULL

				UNION ALL

				-- GETS ALL MISSING DYNAMIC BUNDLES FOR COURSES
		SELECT  @listId ListId ,
				@DYNAMIC_SEGMENT_TYPE SegmentTypeId ,
				s.Uid ,
				@BUNDLE_TYPE AS ItemTypeId,
				b.BundleId AS ItemId,
				b.BundleName AS ItemName
		FROM    CRS_Bundles b
				LEFT OUTER JOIN CHIMP_ListSegments s ON b.BundleId = s.BundleId
		WHERE   b.AuthorId = @userId
				AND s.SegmentId IS NULL

	
	RETURN 
END

GO
/****** Object:  Table [dbo].[ADMIN_DeletedVideosLog]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ADMIN_DeletedVideosLog](
	[BcIdentifier] [varchar](50) NOT NULL,
	[Path] [nvarchar](max) NULL,
	[AddOn] [datetime] NOT NULL,
	[RowId] [int] IDENTITY(1,1) NOT NULL,
	[DeletedFromBcOn] [datetime] NULL,
 CONSTRAINT [PK_ADMIN_DeletedVideosLog] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ADMIN_RegistrationSourcesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ADMIN_RegistrationSourcesLOV](
	[RegistrationTypeId] [tinyint] NOT NULL,
	[RegistrationTypeCode] [varchar](50) NOT NULL,
	[RegistrationTypeName] [nvarchar](50) NOT NULL,
	[IncludeInStats] [bit] NOT NULL,
 CONSTRAINT [PK_User_RegistrationTypesLOV] PRIMARY KEY CLUSTERED 
(
	[RegistrationTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ADMIN_StatusesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ADMIN_StatusesLOV](
	[StatusId] [tinyint] NOT NULL,
	[StatusCode] [varchar](50) NOT NULL,
	[StatusName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_ADMIN_StatusesLOV] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApiSessions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApiSessions](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Created] [datetime] NOT NULL,
	[ExpiryTime] [datetime] NULL,
	[Token] [nvarchar](255) NOT NULL,
	[UserId] [int] NOT NULL,
 CONSTRAINT [PK_ApiSessions] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[APP_PluginInstallations]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[APP_PluginInstallations](
	[InstallationId] [int] IDENTITY(1,1) NOT NULL,
	[TypeId] [tinyint] NOT NULL,
	[UId] [varchar](100) NOT NULL,
	[Domain] [nvarchar](256) NULL,
	[Version] [decimal](18, 0) NULL,
	[UserId] [int] NULL,
	[CreatedBy] [int] NULL,
	[AddOn] [datetime] NOT NULL,
	[UpdatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_APP_PluginInstallations] PRIMARY KEY CLUSTERED 
(
	[InstallationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[APP_PluginInstallationStores]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[APP_PluginInstallationStores](
	[RowId] [int] IDENTITY(1,1) NOT NULL,
	[StoreId] [int] NOT NULL,
	[InstallationId] [int] NOT NULL,
	[PageUrl] [nvarchar](256) NULL,
	[CreatedBy] [int] NULL,
	[AddOn] [datetime] NOT NULL,
 CONSTRAINT [PK_APP_PluginInstallationStores] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[APP_PluginLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[APP_PluginLOV](
	[Id] [tinyint] NOT NULL,
	[TypeCode] [varchar](50) NOT NULL,
	[TypeName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_APP_PluginLOV] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BASE_CurrencyLib]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BASE_CurrencyLib](
	[CurrencyId] [smallint] IDENTITY(1,1) NOT NULL,
	[CurrencyCode] [varchar](50) NOT NULL,
	[CurrencyName] [nvarchar](50) NULL,
	[ISO] [char](3) NULL,
	[CountryId] [smallint] NULL,
	[Symbol] [nvarchar](3) NULL,
	[OrderIndex] [smallint] NULL,
	[IsActive] [bit] NOT NULL,
	[KeepDecimal] [bit] NOT NULL,
	[InsertDate] [datetime] NOT NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_BASE_CurrencyLib] PRIMARY KEY CLUSTERED 
(
	[CurrencyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BASE_ItemTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BASE_ItemTypesLOV](
	[ItemTypeId] [tinyint] NOT NULL,
	[TypeCode] [varchar](50) NOT NULL,
	[TypeName] [nvarchar](128) NOT NULL,
 CONSTRAINT [PK_BASE_ItemTypesLOV] PRIMARY KEY CLUSTERED 
(
	[ItemTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BASE_JobStatusesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BASE_JobStatusesLOV](
	[StatusId] [tinyint] NOT NULL,
	[StatusCode] [varchar](50) NOT NULL,
	[StatusName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_DROP_JobStatusesLOV] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BILL_ItemsPriceList]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BILL_ItemsPriceList](
	[PriceLineId] [int] IDENTITY(1,1) NOT NULL,
	[ItemId] [int] NOT NULL,
	[ItemTypeId] [tinyint] NOT NULL,
	[PriceTypeId] [tinyint] NOT NULL,
	[PeriodTypeId] [tinyint] NULL,
	[CurrencyId] [smallint] NOT NULL,
	[Price] [money] NOT NULL,
	[Name] [nvarchar](512) NULL,
	[NumOfPeriodUnits] [tinyint] NULL,
	[IsDeleted] [bit] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateOn] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_BILL_ItemsPriceList] PRIMARY KEY CLUSTERED 
(
	[PriceLineId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BILL_ItemsPriceRevisions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BILL_ItemsPriceRevisions](
	[RevisionId] [int] IDENTITY(1,1) NOT NULL,
	[PriceLineId] [int] NOT NULL,
	[Price] [money] NOT NULL,
	[FromDate] [datetime] NOT NULL,
	[ToDate] [datetime] NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_BILL_ItemsPriceRevisioons] PRIMARY KEY CLUSTERED 
(
	[RevisionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BILL_PaymentMethodsLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BILL_PaymentMethodsLOV](
	[MethodId] [tinyint] NOT NULL,
	[PaymentMethodCode] [varchar](50) NOT NULL,
	[PaymentMethodName] [varchar](50) NOT NULL,
 CONSTRAINT [PK_BILL_PaymentMethodsLOV] PRIMARY KEY CLUSTERED 
(
	[MethodId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BILL_PaymentTermsLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BILL_PaymentTermsLOV](
	[PaymentTermId] [tinyint] NOT NULL,
	[PaymentTermCode] [varchar](50) NOT NULL,
	[PaymentTermName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_BILL_PaymentTermsLOV] PRIMARY KEY CLUSTERED 
(
	[PaymentTermId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BILL_PayoutTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BILL_PayoutTypesLOV](
	[PayoutTypeId] [tinyint] NOT NULL,
	[TypeCode] [varchar](50) NOT NULL,
	[TypeName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_BILL_PayoutOptionsLOV] PRIMARY KEY CLUSTERED 
(
	[PayoutTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BILL_PeriodTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BILL_PeriodTypesLOV](
	[PeriodTypeId] [tinyint] NOT NULL,
	[PeriodTypeCode] [varchar](50) NOT NULL,
	[PeriodTypeName] [nvarchar](128) NOT NULL,
 CONSTRAINT [PK_BILL_PeriodTypesLOV] PRIMARY KEY CLUSTERED 
(
	[PeriodTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BILL_PricingTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BILL_PricingTypesLOV](
	[TypeId] [tinyint] NOT NULL,
	[TypeCode] [varchar](50) NOT NULL,
	[TypeName] [varchar](50) NOT NULL,
 CONSTRAINT [PK_BILL_BILL_PricingTypesLOV] PRIMARY KEY CLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Categories]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Categories](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CategoryName] [nvarchar](256) NOT NULL,
	[CategoryUrlName] [nvarchar](256) NULL,
	[CategoryDescription] [text] NULL,
	[IsOnHomePage] [int] NOT NULL,
	[Ordinal] [int] NOT NULL,
	[BannerImageUrl] [nvarchar](500) NULL,
	[Keywords] [text] NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Category_Name] UNIQUE NONCLUSTERED 
(
	[CategoryName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CERT_CertificateLib]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CERT_CertificateLib](
	[CertificateId] [int] IDENTITY(1,1) NOT NULL,
	[CourseId] [int] NOT NULL,
	[TemplateId] [tinyint] NOT NULL,
	[Title] [nvarchar](max) NOT NULL,
	[CourseName] [nvarchar](256) NOT NULL,
	[SitgnatureUrl] [nvarchar](max) NULL,
	[PresentedBy] [nvarchar](1024) NULL,
	[Description] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_QZ_CertificateLib] PRIMARY KEY CLUSTERED 
(
	[CertificateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CERT_StudentCertificates]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CERT_StudentCertificates](
	[StudentCertificateId] [uniqueidentifier] NOT NULL,
	[CertificateId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[TemplateId] [tinyint] NOT NULL,
	[Title] [nvarchar](max) NOT NULL,
	[CourseName] [nvarchar](256) NOT NULL,
	[SitgnatureUrl] [nvarchar](max) NULL,
	[PresentedBy] [nvarchar](1024) NULL,
	[Description] [nvarchar](max) NULL,
	[SendOn] [datetime] NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_CERT_StudentCertificates] PRIMARY KEY CLUSTERED 
(
	[StudentCertificateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CERT_TemplatesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CERT_TemplatesLOV](
	[TemplateId] [tinyint] NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[ImageName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AddOn] [datetime] NOT NULL,
 CONSTRAINT [PK_QZ_CertificateTemplatesLOV] PRIMARY KEY CLUSTERED 
(
	[TemplateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ChapterLinks]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChapterLinks](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CourseChapterId] [int] NOT NULL,
	[LinkText] [nvarchar](500) NOT NULL,
	[LinkType] [int] NOT NULL,
	[LinkHref] [nvarchar](500) NOT NULL,
	[Ordinal] [int] NOT NULL,
	[Created] [datetime] NOT NULL,
	[LastModified] [datetime] NULL,
 CONSTRAINT [PK_ChapterLinks] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ChapterVideos]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChapterVideos](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CourseChapterId] [int] NOT NULL,
	[VideoTitle] [nvarchar](50) NOT NULL,
	[VideoSummary] [ntext] NULL,
	[VideoSupplierIdentifier] [nvarchar](255) NOT NULL,
	[IsOpen] [int] NOT NULL,
	[Ordinal] [int] NOT NULL,
	[Created] [datetime] NOT NULL,
	[LastModified] [datetime] NULL,
	[FbObjectId] [bigint] NULL,
 CONSTRAINT [PK_ChapterVideos] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CHIMP_ListSegments]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CHIMP_ListSegments](
	[SegmentId] [int] IDENTITY(1,1) NOT NULL,
	[ListId] [int] NOT NULL,
	[Name] [varchar](1024) NULL,
	[SegmentTypeId] [tinyint] NOT NULL,
	[Uid] [varchar](128) NOT NULL,
	[CourseId] [int] NULL,
	[BundleId] [int] NULL,
	[TotalSubscribers] [int] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[SubscribersLastUpdate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_CHIMP_ListSegments] PRIMARY KEY CLUSTERED 
(
	[SegmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CHIMP_Rejects]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CHIMP_Rejects](
	[RowId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[Email] [nvarchar](150) NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[Message] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_CHIMP_Rejects] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_CHIMP_Rejects] UNIQUE NONCLUSTERED 
(
	[Email] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CHIMP_SegmentTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CHIMP_SegmentTypesLOV](
	[SegmentTypeId] [tinyint] NOT NULL,
	[TypeCode] [varchar](50) NOT NULL,
	[TypeName] [varchar](50) NOT NULL,
	[IsStatic] [bit] NOT NULL,
 CONSTRAINT [PK_CHIMP_SegmentTypesLOV] PRIMARY KEY CLUSTERED 
(
	[SegmentTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CHIMP_UserLists]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CHIMP_UserLists](
	[ListId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[ApiKey] [varchar](128) NOT NULL,
	[Uid] [varchar](128) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TotalSubscribers] [int] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[SubscribersLastUpdate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_CHIMP_UserLists] PRIMARY KEY CLUSTERED 
(
	[ListId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CouponInstances]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CouponInstances](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CouponId] [int] NOT NULL,
	[CouponCode] [nvarchar](50) NOT NULL,
	[UsageLimit] [int] NOT NULL,
	[salesforce_id] [nvarchar](50) NULL,
	[salesforce_checksum] [nvarchar](50) NULL,
	[AddOn] [datetime] NOT NULL,
	[UpdateDate] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_CouponInstances] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Coupons]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Coupons](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CouponName] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](250) NULL,
	[OwnerUserId] [int] NULL,
	[CourseId] [int] NULL,
	[BundleId] [int] NULL,
	[CouponTypeId] [tinyint] NOT NULL,
	[CouponTypeAmount] [float] NULL,
	[AutoGenerate] [bit] NOT NULL,
	[SubscriptionMonths] [tinyint] NULL,
	[ExpirationDate] [datetime] NULL,
	[StoreId] [int] NULL,
	[salesforce_id] [nvarchar](50) NULL,
	[salesforce_checksum] [nvarchar](50) NULL,
	[AddOn] [datetime] NOT NULL,
	[UpdateDate] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_Coupons] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CourseCategories]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CourseCategories](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CourseId] [int] NOT NULL,
	[CategoryId] [int] NOT NULL,
 CONSTRAINT [PK_CourseCategories] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CourseChapters]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CourseChapters](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CourseId] [int] NOT NULL,
	[ChapterName] [nvarchar](50) NOT NULL,
	[ChapterDescriptionHTML] [text] NOT NULL,
	[ChapterOrdinal] [int] NOT NULL,
	[Created] [datetime] NOT NULL,
	[LastModified] [datetime] NULL,
 CONSTRAINT [PK_CourseChapters] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CourseLinks]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CourseLinks](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CourseId] [int] NOT NULL,
	[Title] [nvarchar](50) NOT NULL,
	[LinkText] [nvarchar](500) NOT NULL,
	[LinkHref] [nvarchar](500) NOT NULL,
	[LinkImageUrl] [nvarchar](500) NULL,
	[Ordinal] [int] NOT NULL,
 CONSTRAINT [PK_CourseLinks] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Courses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Courses](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[uid] [uniqueidentifier] NOT NULL,
	[ProvisionUid] [uniqueidentifier] NULL,
	[CourseName] [nvarchar](256) NOT NULL,
	[CourseUrlName] [nvarchar](256) NULL,
	[Description] [nvarchar](max) NULL,
	[AuthorUserId] [int] NOT NULL,
	[IsFreeCourse] [bit] NOT NULL,
	[IsDownloadEnabled] [bit] NOT NULL,
	[AffiliateCommission] [decimal](5, 2) NOT NULL,
	[SmallImage] [nvarchar](255) NULL,
	[OverviewVideoIdentifier] [nvarchar](255) NOT NULL,
	[MetaTags] [nvarchar](max) NULL,
	[Rating] [int] NULL,
	[ClassRoomId] [int] NULL,
	[DisplayOtherLearnersTab] [bit] NOT NULL,
	[FbObjectId] [bigint] NULL,
	[FbObjectPublished] [bit] NOT NULL,
	[StatusId] [smallint] NOT NULL,
	[Created] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[PublishDate] [datetime] NULL,
 CONSTRAINT [PK_Courses] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CRS_Assets]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_Assets](
	[AssetId] [int] IDENTITY(1,1) NOT NULL,
	[CourseId] [int] NOT NULL,
	[AssetTypeId] [tinyint] NOT NULL,
	[Title] [nvarchar](2048) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[AssetUrl] [nvarchar](2048) NULL,
	[BcIdentifier] [bigint] NULL,
	[RefId] [nvarchar](128) NULL,
	[OrderIndex] [smallint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_CRS_Assets] PRIMARY KEY CLUSTERED 
(
	[AssetId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CRS_AssetTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_AssetTypesLOV](
	[AssetTypeId] [tinyint] NOT NULL,
	[TypeCode] [varchar](50) NOT NULL,
	[TypeName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_CRS_AssetTypesLOV] PRIMARY KEY CLUSTERED 
(
	[AssetTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CRS_BundleCategories]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_BundleCategories](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BundleId] [int] NOT NULL,
	[CategoryId] [int] NOT NULL,
 CONSTRAINT [PK_BundleCategories] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CRS_BundleCourses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_BundleCourses](
	[BundleCourseId] [int] IDENTITY(1,1) NOT NULL,
	[BundleId] [int] NOT NULL,
	[CourseId] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[OrderIndex] [smallint] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NOT NULL,
 CONSTRAINT [PK_CRS_BundleCourses] PRIMARY KEY CLUSTERED 
(
	[BundleCourseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_CRS_BundleCourses_CourseBundle] UNIQUE NONCLUSTERED 
(
	[BundleId] ASC,
	[CourseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CRS_Bundles]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_Bundles](
	[BundleId] [int] IDENTITY(1,1) NOT NULL,
	[uid] [uniqueidentifier] NOT NULL,
	[ProvisionUid] [uniqueidentifier] NULL,
	[AuthorId] [int] NOT NULL,
	[BundleName] [nvarchar](512) NOT NULL,
	[BundleUrlName] [nvarchar](1024) NULL,
	[BundleDescription] [text] NULL,
	[Price] [money] NULL,
	[MonthlySubscriptionPrice] [money] NULL,
	[OverviewVideoIdentifier] [nvarchar](255) NOT NULL,
	[AffiliateCommission] [decimal](5, 2) NOT NULL,
	[MetaTags] [nvarchar](max) NULL,
	[BannerImage] [nvarchar](255) NULL,
	[FbObjectId] [bigint] NULL,
	[FbObjectPublished] [bit] NOT NULL,
	[StatusId] [smallint] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[PublishDate] [datetime] NULL,
 CONSTRAINT [PK_CourseBundles] PRIMARY KEY CLUSTERED 
(
	[BundleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CRS_ChapterLinkTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_ChapterLinkTypesLOV](
	[LinkTypeId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_CRS_ChapterLinkTypesLOV] PRIMARY KEY CLUSTERED 
(
	[LinkTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CRS_CouponTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_CouponTypesLOV](
	[CouponTypeId] [tinyint] NOT NULL,
	[TypeCode] [varchar](50) NOT NULL,
	[TypeName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_CRS_CouponTypesLOV] PRIMARY KEY CLUSTERED 
(
	[CouponTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CRS_CourseChangeLog]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_CourseChangeLog](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[Uid] [uniqueidentifier] NOT NULL,
	[LastUpdateOn] [datetime] NOT NULL,
 CONSTRAINT [PK_CourseChangeLog] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_CRS_CourseChangeLog_Uid] UNIQUE NONCLUSTERED 
(
	[Uid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CRS_WizardStepsLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_WizardStepsLOV](
	[StepId] [tinyint] NOT NULL,
	[StepCode] [varchar](50) NOT NULL,
	[StepName] [nvarchar](256) NOT NULL,
	[TooltipHTML] [ntext] NULL,
	[AddOn] [datetime] NOT NULL,
	[UpdatedOn] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_CRS_WizardSteps] PRIMARY KEY CLUSTERED 
(
	[StepId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DB_CustomEvents]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DB_CustomEvents](
	[RowId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[Uid] [varchar](100) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Date] [datetime] NOT NULL,
	[Color] [varchar](50) NOT NULL,
 CONSTRAINT [PK_DB_CustomEvents_1] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DROP_Jobs]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DROP_Jobs](
	[JobId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[AccessToken] [varchar](256) NOT NULL,
	[Path] [nvarchar](max) NOT NULL,
	[Name] [nvarchar](2048) NOT NULL,
	[CourseId] [int] NULL,
	[StatusId] [tinyint] NOT NULL,
	[Error] [nvarchar](max) NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_DROP_Jobs] PRIMARY KEY CLUSTERED 
(
	[JobId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DSC_ClassRoom]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DSC_ClassRoom](
	[ClassRoomId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AuthorId] [int] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[UpdatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_DSC_ClassRoom] PRIMARY KEY CLUSTERED 
(
	[ClassRoomId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DSC_Followers]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DSC_Followers](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[FollowerId] [int] NOT NULL,
	[ClassRoomId] [int] NOT NULL,
	[CourseId] [int] NULL,
	[CreatedBy] [int] NOT NULL,
	[AddOn] [datetime] NOT NULL,
 CONSTRAINT [PK_DSC_ClassRoomFollowers] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_DSC_ClassRoomFollowers_FollowerRoom] UNIQUE NONCLUSTERED 
(
	[ClassRoomId] ASC,
	[FollowerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DSC_Hashtags]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DSC_Hashtags](
	[HashtagId] [bigint] IDENTITY(1,1) NOT NULL,
	[HashTag] [nvarchar](256) NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NOT NULL,
 CONSTRAINT [PK_DSC_Topics] PRIMARY KEY CLUSTERED 
(
	[HashtagId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_DSC_HashTagName] UNIQUE NONCLUSTERED 
(
	[HashTag] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DSC_MessageHashtags]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DSC_MessageHashtags](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[MessageId] [bigint] NOT NULL,
	[HashtagId] [bigint] NOT NULL,
 CONSTRAINT [PK_DSC_MessageTopics] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DSC_MessageKindsLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DSC_MessageKindsLOV](
	[MessageKindId] [smallint] NOT NULL,
	[KindCode] [varchar](50) NOT NULL,
	[KindName] [nvarchar](256) NOT NULL,
 CONSTRAINT [PK_DSC_MessageKindsLOV] PRIMARY KEY CLUSTERED 
(
	[MessageKindId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DSC_Messages]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DSC_Messages](
	[MessageId] [bigint] IDENTITY(1,1) NOT NULL,
	[ClassRoomId] [int] NOT NULL,
	[CourseId] [int] NOT NULL,
	[MessageKindId] [smallint] NOT NULL,
	[ParentMessageId] [bigint] NULL,
	[Text] [nvarchar](max) NOT NULL,
	[HtmlMessage] [ntext] NULL,
	[HtmlVersion] [int] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[UpdatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[Uid] [uniqueidentifier] NOT NULL,
	[HtmlEmailMessage] [ntext] NULL,
 CONSTRAINT [PK_DSC_Messages] PRIMARY KEY CLUSTERED 
(
	[MessageId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_DSC_Messages_Uid] UNIQUE NONCLUSTERED 
(
	[Uid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DSC_MessageUsers]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DSC_MessageUsers](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[MessageId] [bigint] NOT NULL,
	[UserId] [int] NOT NULL,
 CONSTRAINT [PK_DSC_MessageUsers] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EMAIL_Messages]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EMAIL_Messages](
	[EmailId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[NotificationId] [bigint] NULL,
	[Subject] [nvarchar](512) NULL,
	[MessageFrom] [nvarchar](256) NULL,
	[ToEmail] [nvarchar](256) NULL,
	[ToName] [nvarchar](256) NULL,
	[MessageBoby] [ntext] NULL,
	[Status] [varchar](50) NOT NULL,
	[Error] [nvarchar](max) NULL,
	[AddOn] [datetime] NOT NULL,
	[SendOn] [datetime] NULL,
	[UpdateOn] [datetime] NULL,
 CONSTRAINT [PK_EMAIL_Messages] PRIMARY KEY CLUSTERED 
(
	[EmailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EMAIL_TemplateKindsLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EMAIL_TemplateKindsLOV](
	[TemplateKindId] [smallint] NOT NULL,
	[Code] [varchar](50) NOT NULL,
	[Name] [nvarchar](128) NOT NULL,
	[AddOn] [datetime] NOT NULL,
 CONSTRAINT [PK_EMAIL_TemplateKindsLOV] PRIMARY KEY CLUSTERED 
(
	[TemplateKindId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EMAIL_Templates]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EMAIL_Templates](
	[TemplateId] [smallint] IDENTITY(1,1) NOT NULL,
	[TemplateKindId] [smallint] NOT NULL,
	[Snippet] [ntext] NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateOn] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_EMAIL_Templates] PRIMARY KEY CLUSTERED 
(
	[TemplateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_EMAIL_Templates_Kind] UNIQUE NONCLUSTERED 
(
	[TemplateKindId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FACT_DailyStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FACT_DailyStats](
	[FactId] [int] IDENTITY(1,1) NOT NULL,
	[FactDate] [date] NOT NULL,
	[ItemsCreated] [int] NOT NULL,
	[ItemsPublished] [int] NOT NULL,
	[UsersCreated] [int] NOT NULL,
	[WixUsersCreated] [int] NOT NULL,
	[UserLogins] [int] NOT NULL,
	[AuthorLogins] [int] NOT NULL,
	[ReturnUsersLogins] [int] NOT NULL,
	[ItemsPurchased] [int] NOT NULL,
	[FreeItemsPurchased] [int] NOT NULL,
	[StoresCreated] [int] NOT NULL,
	[WixStoresCreated] [int] NOT NULL,
 CONSTRAINT [PK_FACT_DailyStats] PRIMARY KEY CLUSTERED 
(
	[FactId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FACT_DailyTotals]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FACT_DailyTotals](
	[FactId] [int] IDENTITY(1,1) NOT NULL,
	[FactDate] [date] NOT NULL,
	[TotalItems] [int] NOT NULL,
	[TotalPublished] [int] NOT NULL,
	[Attached2Stores] [int] NOT NULL,
	[Attached2WixStores] [int] NOT NULL,
	[TotalUsers] [int] NOT NULL,
	[TotalAuthors] [int] NOT NULL,
	[TotalLearners] [int] NOT NULL,
	[ItemsPurchased] [int] NOT NULL,
	[FreeItemsPurchased] [int] NOT NULL,
	[StoresCreated] [int] NOT NULL,
	[WixStoresCreated] [int] NOT NULL,
 CONSTRAINT [PK_FACT_Totals] PRIMARY KEY CLUSTERED 
(
	[FactId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FACT_DASH_DailyPlatformStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FACT_DASH_DailyPlatformStats](
	[FactId] [int] IDENTITY(1,1) NOT NULL,
	[FactDate] [date] NOT NULL,
	[RegistrationTypeId] [tinyint] NOT NULL,
	[TotalPlatformNew] [int] NOT NULL,
	[NewAuthors] [int] NOT NULL,
	[TotalAuhtors] [int] NOT NULL,
	[NewItems] [int] NOT NULL,
	[TotalItems] [int] NOT NULL,
	[NewStores] [int] NOT NULL,
	[TotalStores] [int] NOT NULL,
	[NewLearners] [int] NOT NULL,
	[TotalLearners] [int] NOT NULL,
	[NewSales] [int] NOT NULL,
	[TotalSales] [int] NOT NULL,
 CONSTRAINT [PK_FACT_DASH_DailyStats] PRIMARY KEY CLUSTERED 
(
	[FactId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FACT_DASH_DailySalesStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FACT_DASH_DailySalesStats](
	[FactId] [int] IDENTITY(1,1) NOT NULL,
	[FactDate] [date] NOT NULL,
	[CurrencyId] [smallint] NOT NULL,
	[TotalOneTimeSales] [money] NOT NULL,
	[TotalSubscriptionSales] [money] NOT NULL,
	[TotalRentalSales] [money] NOT NULL,
 CONSTRAINT [PK_FACT_DASH_DailySalesStats] PRIMARY KEY CLUSTERED 
(
	[FactId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FACT_DASH_DailyTotalStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FACT_DASH_DailyTotalStats](
	[FactId] [int] IDENTITY(1,1) NOT NULL,
	[FactDate] [date] NOT NULL,
	[NewAuthors] [int] NOT NULL,
	[NewCourses] [int] NOT NULL,
	[NewBundles] [int] NOT NULL,
	[NewStores] [int] NOT NULL,
	[NewLearners] [int] NOT NULL,
	[NumOfOneTimeSales] [int] NOT NULL,
	[NumOfSubscriptionSales] [int] NOT NULL,
	[NumOfRentalSales] [int] NOT NULL,
	[NumOfFreeSales] [int] NOT NULL,
	[NewMailchimpLists] [int] NOT NULL,
	[NewMBGJoined] [int] NOT NULL,
	[MBGCancelled] [int] NOT NULL,
 CONSTRAINT [PK_FACT_DASH_DailyTotalStats] PRIMARY KEY CLUSTERED 
(
	[FactId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FACT_EventAgg]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FACT_EventAgg](
	[FactId] [bigint] IDENTITY(1,1) NOT NULL,
	[EventCount] [int] NOT NULL,
	[EventTypeID] [smallint] NOT NULL,
	[EventDate] [date] NOT NULL,
	[WebStoreId] [int] NULL,
	[ItemId] [int] NULL,
	[ItemType] [varchar](50) NOT NULL,
	[ItemName] [nvarchar](256) NULL,
	[AuthorId] [int] NULL,
 CONSTRAINT [PK_FACT_Agg] PRIMARY KEY CLUSTERED 
(
	[FactId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FB_ActionsLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FB_ActionsLOV](
	[ActionId] [tinyint] NOT NULL,
	[Code] [varchar](50) NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[AddOn] [datetime] NOT NULL,
 CONSTRAINT [PK_FB_ActionsLOV] PRIMARY KEY CLUSTERED 
(
	[ActionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FB_PostInterface]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FB_PostInterface](
	[PostId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NULL,
	[FbUid] [bigint] NULL,
	[NotificationId] [bigint] NULL,
	[FbUserName] [nvarchar](128) NULL,
	[Title] [nvarchar](512) NULL,
	[Message] [nvarchar](max) NULL,
	[LinkedName] [nvarchar](512) NULL,
	[Caption] [nvarchar](512) NULL,
	[Description] [nvarchar](max) NULL,
	[ImageUrl] [nvarchar](1024) NULL,
	[Error] [varchar](max) NULL,
	[FbPostId] [varchar](128) NULL,
	[IsAppPagePost] [bit] NOT NULL,
	[ActionId] [tinyint] NULL,
	[CourseId] [int] NULL,
	[Status] [varchar](50) NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[PostOn] [datetime] NULL,
	[UpdateOn] [datetime] NULL,
	[ChapterVideoId] [int] NULL,
 CONSTRAINT [PK_FB_PostInterface] PRIMARY KEY CLUSTERED 
(
	[PostId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[GEO_CountriesLib]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GEO_CountriesLib](
	[CountryId] [smallint] NOT NULL,
	[CountryName] [nvarchar](128) NOT NULL,
	[A2] [varchar](2) NULL,
	[A3] [varchar](3) NULL,
	[CountryGroupId] [smallint] NULL,
	[OrderIndex] [smallint] NULL,
	[IsActive] [bit] NOT NULL,
	[InsertDate] [datetime] NOT NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_GEO_CountriesLib] PRIMARY KEY CLUSTERED 
(
	[CountryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[GEO_States]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GEO_States](
	[StateId] [smallint] NOT NULL,
	[StateName] [varchar](50) NOT NULL,
	[StateCode] [char](5) NULL,
	[CountryId] [smallint] NOT NULL,
	[InsertDate] [datetime] NOT NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_GEO_States] PRIMARY KEY CLUSTERED 
(
	[StateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LogTable]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LogTable](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Origin] [nvarchar](512) NULL,
	[LogLevel] [nvarchar](512) NULL,
	[Message] [nvarchar](max) NULL,
	[Exception] [nvarchar](max) NULL,
	[StackTrace] [nvarchar](max) NULL,
	[Logger] [nvarchar](512) NULL,
	[RecordGuidId] [uniqueidentifier] NULL,
	[RecordIntId] [int] NULL,
	[CreateDate] [datetime] NOT NULL,
	[RecordObjectType] [nvarchar](50) NULL,
	[IPAddress] [varchar](50) NULL,
	[HostName] [nvarchar](max) NULL,
	[UserId] [int] NULL,
	[SessionId] [varchar](50) NULL,
 CONSTRAINT [PK_LogTable] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PAYPAL_IpnLogs]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PAYPAL_IpnLogs](
	[RowId] [int] IDENTITY(1,1) NOT NULL,
	[recurring_payment_id] [varchar](128) NULL,
	[txn_type] [varchar](128) NULL,
	[txn_id] [varchar](50) NULL,
	[initial_payment_txn_id] [varchar](50) NULL,
	[initial_payment_amount] [money] NULL,
	[parent_txn_id] [varchar](50) NULL,
	[amount] [money] NULL,
	[mc_gross] [money] NULL,
	[mc_fee] [money] NULL,
	[response] [varchar](max) NOT NULL,
	[AddOn] [datetime] NOT NULL,
 CONSTRAINT [PK_PAYPAL_IpnLogs] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PAYPAL_PaymentRequests]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PAYPAL_PaymentRequests](
	[RequestId] [uniqueidentifier] NOT NULL,
	[Sid] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[PaymentMethodId] [tinyint] NOT NULL,
	[RequestTypeId] [tinyint] NOT NULL,
	[CreatePaymentId] [varchar](256) NULL,
	[ExecutionPaymentId] [varchar](256) NULL,
	[RecurringRequestToken] [varchar](128) NULL,
	[TransactionId] [varchar](128) NULL,
	[CourseId] [int] NULL,
	[BundleId] [int] NULL,
	[Amount] [money] NULL,
	[TrackingID] [varchar](50) NULL,
	[CouponCode] [nvarchar](50) NULL,
	[AddressId] [int] NULL,
	[InstrumentId] [uniqueidentifier] NULL,
	[Status] [varchar](50) NOT NULL,
	[Error] [nvarchar](max) NULL,
	[SourceRequestId] [uniqueidentifier] NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[PriceLineId] [int] NULL,
 CONSTRAINT [PK_PAYPAL_AccountPaymentRequests] PRIMARY KEY CLUSTERED 
(
	[RequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PAYPAL_RequestTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PAYPAL_RequestTypesLOV](
	[TypeId] [tinyint] NOT NULL,
	[RequestTypeCode] [varchar](50) NOT NULL,
	[RequestTypeName] [varchar](50) NOT NULL,
 CONSTRAINT [PK_BILL_RequestTypesLOV] PRIMARY KEY CLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PendingPayPalTransactions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PendingPayPalTransactions](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CourseId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[PayPalToken] [nvarchar](50) NOT NULL,
	[CouponCode] [nvarchar](50) NULL,
	[Created] [datetime] NULL,
	[MiscData] [nvarchar](50) NULL,
 CONSTRAINT [PK_PendingPayPalTransactions] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PO_BeneficiaryConditions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PO_BeneficiaryConditions](
	[ConditionId] [int] IDENTITY(1,1) NOT NULL,
	[RuleId] [int] NOT NULL,
	[PriceTypeId] [tinyint] NULL,
	[Minutes] [smallint] NULL,
	[LfePercent] [decimal](5, 2) NULL,
	[LfeCommission] [money] NULL,
	[IsDefault] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_PO_BeneficiaryConditions] PRIMARY KEY CLUSTERED 
(
	[ConditionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PO_PayoutExecutions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PO_PayoutExecutions](
	[ExecutionId] [int] IDENTITY(1,1) NOT NULL,
	[PayoutYear] [int] NOT NULL,
	[PayoutMonth] [int] NOT NULL,
	[StatusId] [tinyint] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateOn] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_PO_PayoutExecutions] PRIMARY KEY CLUSTERED 
(
	[ExecutionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_PO_PayoutExecutions_YearMonth] UNIQUE NONCLUSTERED 
(
	[PayoutYear] ASC,
	[PayoutMonth] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PO_PayoutStatusesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PO_PayoutStatusesLOV](
	[StatusId] [tinyint] NOT NULL,
	[StatusCode] [varchar](50) NOT NULL,
	[StatusName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_PO_PayoutStatusesLOV] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PO_RuleBeneficiaries]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PO_RuleBeneficiaries](
	[BeneficiaryId] [int] IDENTITY(1,1) NOT NULL,
	[ConditionId] [int] NOT NULL,
	[UserId] [int] NULL,
	[SharePercent] [decimal](5, 2) NULL,
	[FixedCommission] [money] NULL,
	[IsActive] [bit] NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_PO_RuleBeneficiaries] PRIMARY KEY CLUSTERED 
(
	[BeneficiaryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PO_Rules]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PO_Rules](
	[RuleId] [int] IDENTITY(1,1) NOT NULL,
	[RuleName] [nvarchar](2048) NOT NULL,
	[AuthorId] [int] NULL,
	[AffiliateUserId] [int] NULL,
	[StoreId] [int] NULL,
	[StoreOwnerId] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_PO_Rules] PRIMARY KEY CLUSTERED 
(
	[RuleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PO_UserPayoutStatments]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PO_UserPayoutStatments](
	[PayoutId] [int] IDENTITY(1,1) NOT NULL,
	[ExecutionId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[CurrencyId] [smallint] NOT NULL,
	[PayKey] [varchar](128) NULL,
	[TotalSales] [money] NOT NULL,
	[AuthorSales] [money] NOT NULL,
	[AffiliateSales] [money] NOT NULL,
	[TotalFees] [money] NOT NULL,
	[RefundProgramHold] [money] NOT NULL,
	[RefundProgramReleased] [money] NOT NULL,
	[AffiliateCommission] [money] NOT NULL,
	[AffiliateFees] [money] NOT NULL,
	[TotalRefunded] [money] NOT NULL,
	[TotalRefundedFees] [money] NOT NULL,
	[TotalBalance] [money] NOT NULL,
	[LfeCommissions] [money] NOT NULL,
	[Payout] [money] NOT NULL,
	[Author_total_sales] [money] NOT NULL,
	[Author_total_rgp_sales] [money] NOT NULL,
	[Author_total_non_rgp_sales] [money] NOT NULL,
	[Author_total_fees] [money] NOT NULL,
	[Author_total_rgp_fee] [money] NOT NULL,
	[Author_total_non_rgp_fee] [money] NOT NULL,
	[By_Affiliate_total_sales] [money] NOT NULL,
	[By_Affiliate_total_rgp_sales] [money] NOT NULL,
	[By_Affiliate_total_non_rgp_sales] [money] NOT NULL,
	[By_Affiliate_total_fees] [money] NOT NULL,
	[By_Affiliate_total_rgp_fee] [money] NOT NULL,
	[By_Affiliate_total_non_rgp_fee] [money] NOT NULL,
	[By_Affiliate_total_net_rgp_sales] [money] NOT NULL,
	[By_Affiliate_total_net_non_rgp_sales] [money] NOT NULL,
	[By_Affiliate_total_net_fees] [money] NOT NULL,
	[By_Affiliate_total_net_rgp_fee] [money] NOT NULL,
	[By_Affiliate_total_net_non_rgp_fee] [money] NOT NULL,
	[Affiliate_total_sales] [money] NOT NULL,
	[Affiliate_total_rgp_sales] [money] NOT NULL,
	[Affiliate_total_non_rgp_sales] [money] NOT NULL,
	[Affiliate_total_commission] [money] NOT NULL,
	[Affiliate_total_rgp_commission] [money] NOT NULL,
	[Affiliate_total_non_rgp_commission] [money] NOT NULL,
	[Affiliate_total_fees] [money] NOT NULL,
	[Affiliate_total_rgp_fee] [money] NOT NULL,
	[Affiliate_total_non_rgp_fee] [money] NOT NULL,
	[Affiliate_total_net_fees] [money] NOT NULL,
	[Affiliate_total_net_rgp_fee] [money] NOT NULL,
	[Affiliate_total_net_non_rgp_fee] [money] NOT NULL,
	[Author_Released_total_rgp_sales] [money] NOT NULL,
	[Author_Released_total_rgp_fee] [money] NOT NULL,
	[Affiliate_Released_total_net_rgp_sales] [money] NOT NULL,
	[Affiliate_Released_total_net_rgp_fee] [money] NOT NULL,
	[By_Affiliate_Released_total_rgp_commission] [money] NOT NULL,
	[By_Affiliate_Released_total_net_rgp_fee] [money] NOT NULL,
	[Author_total_refunded] [money] NOT NULL,
	[Author_fee_refunded] [money] NOT NULL,
	[Affiliate_total_refunded] [money] NOT NULL,
	[Affiliate_fee_refunded] [money] NOT NULL,
	[Affiliate_total_net_refunded] [money] NOT NULL,
	[Affiliate_fee_net_refunded] [money] NOT NULL,
	[By_Affiliate_total_refunded] [money] NOT NULL,
	[By_Affiliate_fee_refunded] [money] NOT NULL,
	[By_Affiliate_total_net_refunded] [money] NOT NULL,
	[By_Affiliate_fee_net_refunded] [money] NOT NULL,
	[PayoutTypeId] [tinyint] NULL,
	[PaypalEmail] [nvarchar](150) NULL,
	[PayoutAddressID] [int] NULL,
	[StatusId] [tinyint] NOT NULL,
	[ErrorMessage] [nvarchar](max) NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateOn] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[PaymentFee] [money] NULL,
 CONSTRAINT [PK_PO_UserPayoutStatments] PRIMARY KEY CLUSTERED 
(
	[PayoutId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_PO_UserPayoutStatments] UNIQUE NONCLUSTERED 
(
	[UserId] ASC,
	[ExecutionId] ASC,
	[CurrencyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[QZ_CourseQuizzes]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QZ_CourseQuizzes](
	[QuizId] [uniqueidentifier] NOT NULL,
	[Sid] [int] IDENTITY(1,1) NOT NULL,
	[CourseId] [int] NOT NULL,
	[Title] [nvarchar](2048) NOT NULL,
	[Description] [ntext] NULL,
	[Instructions] [ntext] NULL,
	[PassPercent] [tinyint] NULL,
	[ScoreRuleId] [tinyint] NOT NULL,
	[RandomOrder] [bit] NOT NULL,
	[AvailableAfter] [smallint] NULL,
	[IsMandatory] [bit] NOT NULL,
	[IsBackAllowed] [bit] NOT NULL,
	[Attempts] [tinyint] NULL,
	[TimeLimit] [smallint] NULL,
	[AttachCertificate] [bit] NOT NULL,
	[IsAttached] [bit] NOT NULL,
	[StatusId] [tinyint] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_QZ_CourseQuizzes_1] PRIMARY KEY CLUSTERED 
(
	[QuizId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_QZ_CourseQuizzes_Sid] UNIQUE NONCLUSTERED 
(
	[Sid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[QZ_QuestionAnswerOptions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QZ_QuestionAnswerOptions](
	[OptionId] [int] IDENTITY(1,1) NOT NULL,
	[QuestionId] [int] NOT NULL,
	[OptionText] [nvarchar](max) NOT NULL,
	[IsCorrect] [bit] NOT NULL,
	[Score] [tinyint] NULL,
	[OrderIndex] [smallint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_QZ_QustionAnswerOptions] PRIMARY KEY CLUSTERED 
(
	[OptionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[QZ_QuestionTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QZ_QuestionTypesLOV](
	[TypeId] [tinyint] NOT NULL,
	[TypeCode] [varchar](50) NOT NULL,
	[TypeName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_QZ_QuestionTypesLOV] PRIMARY KEY CLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[QZ_QuizQuestionsLib]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QZ_QuizQuestionsLib](
	[QuestionId] [int] IDENTITY(1,1) NOT NULL,
	[QuizId] [uniqueidentifier] NOT NULL,
	[TypeId] [tinyint] NOT NULL,
	[QuestionText] [ntext] NOT NULL,
	[Score] [tinyint] NULL,
	[Description] [ntext] NULL,
	[BcIdentifier] [bigint] NULL,
	[ImageUrl] [nvarchar](2048) NULL,
	[OrderIndex] [smallint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_QZ_QuizQuestionsLib] PRIMARY KEY CLUSTERED 
(
	[QuestionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[QZ_ScoreRulesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QZ_ScoreRulesLOV](
	[RuleId] [tinyint] NOT NULL,
	[RuleCode] [varchar](50) NOT NULL,
	[RuleName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_QZ_ScoreRulesLOV] PRIMARY KEY CLUSTERED 
(
	[RuleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[QZ_StatusesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QZ_StatusesLOV](
	[StatusId] [tinyint] NOT NULL,
	[StatusCode] [varchar](50) NOT NULL,
	[StatusName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_QZ_StatusesLOV] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[QZ_StudentQuizAnswers]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QZ_StudentQuizAnswers](
	[AnswerId] [int] IDENTITY(1,1) NOT NULL,
	[AttemptId] [uniqueidentifier] NOT NULL,
	[QuestionId] [int] NULL,
	[QuestionText] [ntext] NOT NULL,
	[OptionId] [int] NULL,
	[AnswerText] [nvarchar](max) NULL,
	[IsCorrect] [bit] NOT NULL,
	[Score] [tinyint] NULL,
	[OrderIndex] [int] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_QZ_StudentQuizAnswers] PRIMARY KEY CLUSTERED 
(
	[AnswerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[QZ_StudentQuizAttempts]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QZ_StudentQuizAttempts](
	[AttemptId] [uniqueidentifier] NOT NULL,
	[StudentQuizId] [uniqueidentifier] NOT NULL,
	[IsSuccess] [bit] NOT NULL,
	[Score] [decimal](6, 2) NULL,
	[StatusId] [tinyint] NOT NULL,
	[CurrentIndex] [int] NOT NULL,
	[StartOn] [datetime] NOT NULL,
	[FinishedOn] [datetime] NULL,
	[AddOn] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_StudentQuizAttempts] PRIMARY KEY CLUSTERED 
(
	[AttemptId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[QZ_StudentQuizStatusesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QZ_StudentQuizStatusesLOV](
	[StatusId] [tinyint] NOT NULL,
	[StatusCode] [varchar](50) NOT NULL,
	[StatusName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_QZ_UserQuizStatusesLOV] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[QZ_StudentQuizzes]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QZ_StudentQuizzes](
	[StudentQuizId] [uniqueidentifier] NOT NULL,
	[QuizId] [uniqueidentifier] NOT NULL,
	[UserId] [int] NOT NULL,
	[IsSuccess] [bit] NOT NULL,
	[Score] [decimal](6, 2) NULL,
	[LastAttemptStartDate] [datetime] NULL,
	[AvailableAttempts] [tinyint] NULL,
	[RequestSendOn] [datetime] NULL,
	[ResponseSendOn] [datetime] NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_QZ_StudentQuizzes] PRIMARY KEY CLUSTERED 
(
	[StudentQuizId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_ItemTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_ItemTypesLOV](
	[ItemTypeId] [tinyint] NOT NULL,
	[ItemTypeCode] [varchar](50) NOT NULL,
	[ItemTypeName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_SALE_ItemTypeesLOV] PRIMARY KEY CLUSTERED 
(
	[ItemTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_OrderLinePaymentRefunds]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_OrderLinePaymentRefunds](
	[RefundId] [int] IDENTITY(1,1) NOT NULL,
	[PaymentId] [int] NOT NULL,
	[TypeId] [tinyint] NOT NULL,
	[Amount] [money] NOT NULL,
	[RefundDate] [datetime] NOT NULL,
	[AddOn] [datetime] NULL,
 CONSTRAINT [PK_SALE_OrderLinePaymentRefunds] PRIMARY KEY CLUSTERED 
(
	[RefundId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_OrderLinePayments]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_OrderLinePayments](
	[PaymentId] [int] IDENTITY(1,1) NOT NULL,
	[OrderLineId] [int] NOT NULL,
	[TypeId] [tinyint] NOT NULL,
	[Amount] [money] NOT NULL,
	[Currency] [varchar](50) NOT NULL,
	[ScheduledDate] [datetime] NOT NULL,
	[PaymentDate] [datetime] NULL,
	[PaymentNumber] [smallint] NOT NULL,
	[StatusId] [tinyint] NULL,
	[AddOn] [datetime] NOT NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_SALE_OrderLinePayments] PRIMARY KEY CLUSTERED 
(
	[PaymentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_OrderLines]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_OrderLines](
	[LineId] [int] IDENTITY(1,1) NOT NULL,
	[OrderId] [uniqueidentifier] NOT NULL,
	[LineTypeId] [tinyint] NOT NULL,
	[PaymentTermId] [tinyint] NOT NULL,
	[ItemName] [nvarchar](max) NOT NULL,
	[SellerUserId] [int] NOT NULL,
	[CourseId] [int] NULL,
	[BundleId] [int] NULL,
	[CouponInstanceId] [int] NULL,
	[Price] [money] NOT NULL,
	[Discount] [money] NOT NULL,
	[Fee] [money] NOT NULL,
	[TotalPrice] [money] NOT NULL,
	[PaypalProfileID] [varchar](50) NULL,
	[Description] [nvarchar](max) NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[PriceLineId] [int] NULL,
	[IsUnderRGP] [bit] NOT NULL,
	[AffiliateCommission] [decimal](5, 2) NULL,
 CONSTRAINT [PK_SALE_OrderLines] PRIMARY KEY CLUSTERED 
(
	[LineId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_OrderLineTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_OrderLineTypesLOV](
	[TypeId] [tinyint] NOT NULL,
	[TypeCode] [varchar](50) NOT NULL,
	[TypeName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_SALE_OrderLineTypesLOV] PRIMARY KEY CLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_Orders]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_Orders](
	[OrderId] [uniqueidentifier] NOT NULL,
	[Sid] [int] IDENTITY(1,1) NOT NULL,
	[BuyerUserId] [int] NOT NULL,
	[SellerUserId] [int] NOT NULL,
	[WebStoreId] [int] NULL,
	[StatusId] [tinyint] NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[AddressId] [int] NULL,
	[PaymentMethodId] [tinyint] NOT NULL,
	[InstrumentId] [uniqueidentifier] NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[CancelledOn] [datetime] NULL,
 CONSTRAINT [PK_SALE_Orders] PRIMARY KEY CLUSTERED 
(
	[OrderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_OrderStatusesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_OrderStatusesLOV](
	[StatusId] [tinyint] NOT NULL,
	[StatusCode] [varchar](50) NOT NULL,
	[StatusName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_SALE_OrderStatusesLOV] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_PaymentStatusesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_PaymentStatusesLOV](
	[StatusId] [tinyint] NOT NULL,
	[StatusCode] [varchar](50) NOT NULL,
	[StatusName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_SALE_PaymentStatusesLOV] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_PaymentTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_PaymentTypesLOV](
	[TypeId] [tinyint] NOT NULL,
	[TypeCode] [varchar](50) NOT NULL,
	[TypeName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_SALE_PaymentTypesLOV] PRIMARY KEY CLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_RefundRequests]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_RefundRequests](
	[RequestId] [int] IDENTITY(1,1) NOT NULL,
	[ReferenceKey] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[PaymentId] [int] NOT NULL,
	[RefundId] [int] NULL,
	[StatusId] [tinyint] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[LastUpdate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[AuthorResponseOn] [datetime] NULL,
	[CompletedOn] [datetime] NULL,
	[Error] [varchar](1000) NULL,
 CONSTRAINT [PK_SALE_RefundRequests] PRIMARY KEY CLUSTERED 
(
	[RequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_RefundRequestStatusesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_RefundRequestStatusesLOV](
	[StatusId] [tinyint] NOT NULL,
	[StatusCode] [varchar](50) NOT NULL,
	[StatusName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_SALE_RefundRequestStatusesLOV] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_Transactions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_Transactions](
	[TransactionId] [int] IDENTITY(1,1) NOT NULL,
	[TransactionTypeId] [tinyint] NOT NULL,
	[OrderLineId] [int] NOT NULL,
	[PaymentId] [int] NULL,
	[RefundId] [int] NULL,
	[TransactionDate] [datetime] NOT NULL,
	[ExternalTransactionID] [nvarchar](200) NULL,
	[Amount] [money] NOT NULL,
	[Fee] [money] NOT NULL,
	[Remarks] [nvarchar](max) NULL,
	[RequestId] [uniqueidentifier] NULL,
	[SourceTransactionId] [int] NULL,
	[AddOn] [datetime] NOT NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_SALE_Transactions] PRIMARY KEY CLUSTERED 
(
	[TransactionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_TransactionTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_TransactionTypesLOV](
	[TransactionTypeId] [tinyint] NOT NULL,
	[TypeCode] [nvarchar](50) NOT NULL,
	[TypeName] [nvarchar](512) NULL,
 CONSTRAINT [PK_SALE_TransactionTypesLOV] PRIMARY KEY CLUSTERED 
(
	[TransactionTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SALE_UserAccessStatusesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SALE_UserAccessStatusesLOV](
	[StatusId] [tinyint] NOT NULL,
	[StatusCode] [varchar](50) NOT NULL,
	[StatusName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_BILL_SubscriptionStatusesLOV] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StatusLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StatusLOV](
	[StatusId] [smallint] NOT NULL,
	[StatusCode] [varchar](50) NOT NULL,
	[StatusName] [nvarchar](256) NOT NULL,
 CONSTRAINT [PK_CourseStatusLOV] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Tags]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tags](
	[id] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_Tags] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[upload]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[upload](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[filename] [varchar](256) NULL,
	[filesize] [varchar](64) NULL,
	[last_modified] [varchar](64) NULL,
	[upload_start] [datetime] NULL,
	[last_information] [datetime] NULL,
	[video_key] [varchar](256) NULL,
	[upload_id] [varchar](128) NULL,
	[chunks_uploaded] [text] NULL,
 CONSTRAINT [PK_upload] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[USER_Addresses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_Addresses](
	[AddressId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[CountryId] [smallint] NULL,
	[StateId] [smallint] NULL,
	[FirstName] [nvarchar](128) NULL,
	[LastName] [nvarchar](128) NULL,
	[CityName] [nvarchar](256) NULL,
	[Street1] [nvarchar](512) NULL,
	[Street2] [nvarchar](512) NULL,
	[PostalCode] [char](10) NULL,
	[Phone] [char](15) NULL,
	[CellPhone] [char](15) NULL,
	[Fax] [char](15) NULL,
	[Email] [nvarchar](128) NULL,
	[Region] [nvarchar](512) NULL,
	[Description] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[UpdateDate] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_CON_ContactsLib] PRIMARY KEY CLUSTERED 
(
	[AddressId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[USER_Bundles]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_Bundles](
	[UserBundleId] [int] IDENTITY(1,1) NOT NULL,
	[OrderLineId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[BundleId] [int] NOT NULL,
	[StatusId] [tinyint] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[UpdateDate] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_USER_Bundles] PRIMARY KEY CLUSTERED 
(
	[UserBundleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[USER_Courses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_Courses](
	[UserCourseId] [int] IDENTITY(1,1) NOT NULL,
	[OrderLineId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[CourseId] [int] NOT NULL,
	[UserBundleId] [int] NULL,
	[StatusId] [tinyint] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[ValidUntil] [datetime] NULL,
 CONSTRAINT [PK_USER_Courses] PRIMARY KEY CLUSTERED 
(
	[UserCourseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[USER_CourseWatchState]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_CourseWatchState](
	[RowId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[CourseId] [int] NOT NULL,
	[LastVideoID] [int] NULL,
	[LastChapterID] [int] NULL,
	[LastViewDate] [datetime] NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_USER_CourseWatchState] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_USER_CourseWatchState_UserCourse] UNIQUE NONCLUSTERED 
(
	[UserId] ASC,
	[CourseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[USER_Logins]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_Logins](
	[LoginId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[NetSessionId] [nvarchar](50) NOT NULL,
	[HostName] [nvarchar](2048) NULL,
	[LoginDate] [datetime] NOT NULL,
	[SignOutDate] [datetime] NULL,
 CONSTRAINT [PK_USER_Logins] PRIMARY KEY CLUSTERED 
(
	[LoginId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[USER_PaymentInstruments]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_PaymentInstruments](
	[InstrumentId] [uniqueidentifier] NOT NULL,
	[UserId] [int] NOT NULL,
	[AddressId] [int] NOT NULL,
	[PaymentMethodId] [tinyint] NOT NULL,
	[PaypalCcToken] [varchar](128) NULL,
	[PaypalAgreementToken] [varchar](128) NULL,
	[CreditCardType] [varchar](50) NULL,
	[DisplayName] [nvarchar](128) NULL,
	[IsActive] [bit] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_USER_PaymentInstruments] PRIMARY KEY CLUSTERED 
(
	[InstrumentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[USER_RefundProgramRevisions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_RefundProgramRevisions](
	[RevisionId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[FromDate] [datetime] NOT NULL,
	[ToDate] [datetime] NULL,
 CONSTRAINT [PK_USER_RefundProgramRevisions] PRIMARY KEY CLUSTERED 
(
	[RevisionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[USER_Videos]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_Videos](
	[VideoId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NULL,
	[BcIdentifier] [bigint] NOT NULL,
	[Name] [nvarchar](2048) NULL,
	[Attached2Chapter] [bit] NOT NULL,
	[PlaylistUrl] [nvarchar](2048) NULL,
	[S3Url] [nvarchar](2048) NULL,
	[ThumbUrl] [nvarchar](2048) NULL,
	[Duration] [varchar](50) NULL,
	[ShortDescription] [nvarchar](2048) NULL,
	[ReferenceId] [varchar](128) NULL,
	[VideoStillUrl] [nvarchar](2048) NULL,
	[Tags] [nvarchar](max) NULL,
	[PlaysTotal] [int] NOT NULL,
	[Length] [bigint] NOT NULL,
	[LastTranscodeDate] [datetime] NULL,
	[CreationDate] [datetime] NOT NULL,
	[InsertDate] [datetime] NOT NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_USER_Videos] PRIMARY KEY CLUSTERED 
(
	[VideoId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[USER_VideosRenditions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_VideosRenditions](
	[RenditionId] [bigint] NOT NULL,
	[VideoId] [int] NOT NULL,
	[Location] [nvarchar](2048) NULL,
	[S3Url] [nvarchar](2048) NULL,
	[CloudFrontPath] [nvarchar](2048) NULL,
	[AudioOnly] [bit] NOT NULL,
	[ControllerType] [nvarchar](256) NULL,
	[DisplayName] [nvarchar](max) NULL,
	[EncodingRate] [int] NULL,
	[FrameHeight] [int] NULL,
	[FrameWidth] [int] NULL,
	[ReferenceId] [nvarchar](512) NULL,
	[RemoteStreamName] [nvarchar](max) NULL,
	[RemoteUrl] [nvarchar](max) NULL,
	[Size] [bigint] NULL,
	[S3Size] [bigint] NULL,
	[UploadTimestampMillis] [bigint] NULL,
	[Url] [nvarchar](max) NULL,
	[VideoCodec] [varchar](50) NULL,
	[VideoContainer] [varchar](50) NULL,
	[VideoDuration] [bigint] NULL,
	[CreatedInS3] [bit] NOT NULL,
	[InsertDate] [datetime] NOT NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_USER_VideosRenditions] PRIMARY KEY CLUSTERED 
(
	[RenditionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[USER_VideoStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_VideoStats](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[BcIdentifier] [bigint] NOT NULL,
	[SessionId] [uniqueidentifier] NOT NULL,
	[ChapterId] [int] NULL,
	[StartDate] [datetime] NOT NULL,
	[StartPosition] [decimal](10, 3) NOT NULL,
	[StartReason] [varchar](50) NULL,
	[EndDate] [datetime] NULL,
	[EndPosition] [decimal](10, 3) NULL,
	[EndReason] [varchar](50) NULL,
	[TotalSeconds] [decimal](10, 3) NULL,
 CONSTRAINT [PK_USER_VideoStats] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserCourseReviews]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserCourseReviews](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[CourseId] [int] NOT NULL,
	[ReviewDate] [datetime] NULL,
	[ReviewRating] [int] NULL,
	[ReviewTitle] [nvarchar](50) NULL,
	[ReviewText] [text] NULL,
	[Approved] [bit] NOT NULL,
 CONSTRAINT [PK_UserCourseReviews] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserEventTypeOwnersLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserEventTypeOwnersLOV](
	[OwnerTypeId] [tinyint] NOT NULL,
	[OwnerCode] [varchar](10) NOT NULL,
 CONSTRAINT [PK_UserEventTypeOwnersLOV] PRIMARY KEY CLUSTERED 
(
	[OwnerTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserEventTypesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserEventTypesLOV](
	[TypeId] [smallint] NOT NULL,
	[TypeCode] [nvarchar](50) NOT NULL,
	[TypeName] [nvarchar](500) NULL,
	[OwnerTypeId] [tinyint] NULL,
 CONSTRAINT [PK_UserEventTypes] PRIMARY KEY CLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserNotifications]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserNotifications](
	[NotificationId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[MessageId] [bigint] NULL,
	[IsRead] [bit] NOT NULL,
	[EmailRequired] [bit] NOT NULL,
	[EmailSendOn] [datetime] NULL,
	[FbPostRequired] [bit] NOT NULL,
	[FbPostSendOn] [datetime] NULL,
	[AddOn] [datetime] NOT NULL,
	[ReadOn] [datetime] NULL,
 CONSTRAINT [PK_UserNotifications] PRIMARY KEY CLUSTERED 
(
	[NotificationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserProfile]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserProfile](
	[UserId] [int] IDENTITY(1,1) NOT NULL,
	[Email] [nvarchar](256) NOT NULL,
	[RefUserId] [int] NULL,
	[AddOn] [datetime] NOT NULL,
	[LastLogin] [datetime] NULL,
 CONSTRAINT [PK__UserProf__1788CC4C1E855E4E] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_UserProfile_UserId] UNIQUE NONCLUSTERED 
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Users]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ProvisionUid] [uniqueidentifier] NULL,
	[Email] [nvarchar](150) NOT NULL,
	[Nickname] [nvarchar](50) NOT NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[ActivationToken] [nvarchar](255) NULL,
	[ActivationExpiration] [datetime] NULL,
	[FacebookID] [varchar](20) NULL,
	[StatusType] [int] NOT NULL,
	[AffiliateCommission] [decimal](5, 2) NOT NULL,
	[PasswordDigest] [nvarchar](500) NULL,
	[PictureURL] [nvarchar](255) NULL,
	[BirthDate] [datetime] NULL,
	[Gender] [int] NULL,
	[BioHtml] [nvarchar](max) NULL,
	[AuthorPictureURL] [nvarchar](255) NULL,
	[AutoplayEnabled] [bit] NOT NULL,
	[UserTypeID] [int] NOT NULL,
	[LastLogin] [datetime] NULL,
	[salesforce_id] [nvarchar](50) NULL,
	[salesforce_checksum] [nvarchar](50) NULL,
	[DisplayActivitiesOnFB] [bit] NOT NULL,
	[ReceiveMonthlyNewsletterOnEmail] [bit] NOT NULL,
	[DisplayDiscussionFeedDailyOnFB] [bit] NOT NULL,
	[ReceiveDiscussionFeedDailyOnEmail] [bit] NOT NULL,
	[DisplayCourseNewsWeeklyOnFB] [bit] NOT NULL,
	[ReceiveCourseNewsWeeklyOnEmail] [bit] NOT NULL,
	[RegistrationTypeId] [tinyint] NOT NULL,
	[RegisterStoreId] [int] NULL,
	[FbAccessToken] [varchar](1024) NULL,
	[FbAccessTokenExpired] [date] NULL,
	[PayoutTypeId] [tinyint] NULL,
	[PayoutAddressID] [int] NULL,
	[PaypalEmail] [nvarchar](150) NULL,
	[Created] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[RegisterHostName] [nvarchar](2048) NULL,
	[JoinedToRefundProgram] [bit] NOT NULL,
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Users_Email] UNIQUE NONCLUSTERED 
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserS3FileInterface]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserS3FileInterface](
	[FileId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[FilePath] [nvarchar](2048) NULL,
	[ETag] [varchar](256) NULL,
	[ContentType] [varchar](128) NULL,
	[BcIdentifier] [bigint] NULL,
	[FileSize] [bigint] NULL,
	[Title] [nvarchar](2048) NULL,
	[Tags] [nvarchar](2048) NULL,
	[Status] [varchar](50) NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[UpdateOn] [datetime] NULL,
	[BcRefId] [nvarchar](2048) NULL,
	[Error] [nvarchar](max) NULL,
 CONSTRAINT [PK_UserS3FileInterface] PRIMARY KEY CLUSTERED 
(
	[FileId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UsersAgents]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UsersAgents](
	[UserAgentID] [int] IDENTITY(1,1) NOT NULL,
	[UserAgent] [varchar](500) NOT NULL,
 CONSTRAINT [PK_UsersAgents] PRIMARY KEY CLUSTERED 
(
	[UserAgentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserSessions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserSessions](
	[SessionId] [bigint] IDENTITY(1,1) NOT NULL,
	[NetSessionId] [nvarchar](50) NOT NULL,
	[UserID] [int] NULL,
	[IPAddress] [nvarchar](50) NULL,
	[HostName] [nvarchar](max) NULL,
	[HttpHeaders] [text] NULL,
	[salesforce_id] [nvarchar](50) NULL,
	[salesforce_checksum] [nvarchar](50) NULL,
	[EventDate] [datetime] NOT NULL,
 CONSTRAINT [PK_UserSessions] PRIMARY KEY CLUSTERED 
(
	[SessionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserSessionsEventLogs]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserSessionsEventLogs](
	[EventID] [bigint] IDENTITY(1,1) NOT NULL,
	[SessionId] [bigint] NOT NULL,
	[EventTypeID] [smallint] NOT NULL,
	[EventDate] [datetime] NOT NULL,
	[AdditionalData] [nvarchar](max) NULL,
	[AubsoluteUri] [nvarchar](max) NULL,
	[WebStoreId] [int] NULL,
	[CourseId] [int] NULL,
	[BundleId] [int] NULL,
	[ExportToFact] [bit] NOT NULL,
	[salesforce_id] [nvarchar](50) NULL,
	[salesforce_checksum] [nvarchar](50) NULL,
	[VideoBcIdentifier] [bigint] NULL,
	[HostName] [nvarchar](max) NULL,
 CONSTRAINT [PK_UserEvents] PRIMARY KEY CLUSTERED 
(
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserStatusTypes]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserStatusTypes](
	[Id] [int] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_UserStatusTypes] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UserTypes]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserTypes](
	[id] [int] NOT NULL,
	[name] [nvarchar](50) NULL,
 CONSTRAINT [PK_UserTypes] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[webpages_Membership]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[webpages_Membership](
	[UserId] [int] NOT NULL,
	[CreateDate] [datetime] NULL,
	[ConfirmationToken] [nvarchar](128) NULL,
	[IsConfirmed] [bit] NULL,
	[LastPasswordFailureDate] [datetime] NULL,
	[PasswordFailuresSinceLastSuccess] [int] NOT NULL,
	[Password] [nvarchar](128) NOT NULL,
	[PasswordChangedDate] [datetime] NULL,
	[PasswordSalt] [nvarchar](128) NOT NULL,
	[PasswordVerificationToken] [nvarchar](128) NULL,
	[PasswordVerificationTokenExpirationDate] [datetime] NULL,
 CONSTRAINT [PK__webpages__1788CC4C74444068] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[webpages_OAuthMembership]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[webpages_OAuthMembership](
	[Provider] [nvarchar](30) NOT NULL,
	[ProviderUserId] [nvarchar](100) NOT NULL,
	[UserId] [int] NOT NULL,
 CONSTRAINT [PK__webpages__F53FC0ED7073AF84] PRIMARY KEY CLUSTERED 
(
	[Provider] ASC,
	[ProviderUserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[webpages_Roles]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[webpages_Roles](
	[RoleId] [int] NOT NULL,
	[RoleName] [nvarchar](256) NOT NULL,
 CONSTRAINT [PK__webpages__8AFACE1A79FD19BE] PRIMARY KEY CLUSTERED 
(
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ__webpages__8A2B61607CD98669] UNIQUE NONCLUSTERED 
(
	[RoleName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[webpages_UsersInRoles]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[webpages_UsersInRoles](
	[UserId] [int] NOT NULL,
	[RoleId] [int] NOT NULL,
 CONSTRAINT [PK__webpages__AF2760AD00AA174D] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC,
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[WebStoreCategories]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WebStoreCategories](
	[WebStoreCategoryID] [int] IDENTITY(1,1) NOT NULL,
	[WebStoreID] [int] NOT NULL,
	[CategoryId] [int] NULL,
	[CategoryName] [nvarchar](50) NOT NULL,
	[CategoryUrlName] [nvarchar](50) NULL,
	[Description] [nvarchar](4000) NULL,
	[Ordinal] [int] NOT NULL,
	[IsPublic] [bit] NOT NULL,
	[IsAutoUpdate] [bit] NOT NULL,
	[AddOn] [datetime] NOT NULL,
 CONSTRAINT [PK_WebStoreCategories] PRIMARY KEY CLUSTERED 
(
	[WebStoreCategoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[WebStoreItems]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WebStoreItems](
	[WebstoreItemId] [int] IDENTITY(1,1) NOT NULL,
	[ItemTypeId] [tinyint] NOT NULL,
	[CourseId] [int] NULL,
	[BundleId] [int] NULL,
	[WebStoreCategoryID] [int] NOT NULL,
	[ItemName] [nvarchar](250) NOT NULL,
	[Description] [ntext] NULL,
	[Ordinal] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
 CONSTRAINT [PK_WebstoreCourses] PRIMARY KEY CLUSTERED 
(
	[WebstoreItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[WebStores]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WebStores](
	[StoreID] [int] IDENTITY(1,1) NOT NULL,
	[TrackingID] [varchar](50) NOT NULL,
	[StoreName] [nvarchar](256) NOT NULL,
	[GoogleAnalyticCode] [nvarchar](max) NULL,
	[MetaTags] [nvarchar](max) NULL,
	[Description] [nvarchar](max) NULL,
	[OwnerUserID] [int] NOT NULL,
	[uid] [uniqueidentifier] NOT NULL,
	[WixInstanceId] [uniqueidentifier] NULL,
	[BackgroundColor] [varchar](50) NULL,
	[FontColor] [varchar](50) NULL,
	[TabsFontColor] [varchar](50) NULL,
	[IsShowBorder] [bit] NULL,
	[IsShowTitleBar] [bit] NULL,
	[IsTransparent] [bit] NULL,
	[StatusId] [smallint] NOT NULL,
	[AddOn] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
	[UpdateOn] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[WixSiteUrl] [nvarchar](500) NULL,
	[DefaultCurrencyId] [smallint] NULL,
	[RegistrationSourceId] [tinyint] NULL,
	[SiteUrl] [nvarchar](max) NULL,
 CONSTRAINT [PK_WebStores] PRIMARY KEY CLUSTERED 
(
	[StoreID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[WebStoresChangeLog]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WebStoresChangeLog](
	[RowId] [int] IDENTITY(1,1) NOT NULL,
	[StoreId] [int] NOT NULL,
	[LastUpdateOn] [datetime] NULL,
	[UpdatedOn] [int] NULL,
 CONSTRAINT [PK_WebStoresChangeLog] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_WebStoresChangeLog_StoreId] UNIQUE NONCLUSTERED 
(
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[vw_USER_Statistics]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_USER_Statistics]
AS
SELECT        TOP (100) PERCENT u.Id AS UserId, u.Email, u.Nickname, u.FirstName, u.LastName, ISNULL(SUM(c.courses), 0) AS courses, ISNULL(SUM(b.bundles), 0) AS bundles, 
                         ISNULL(SUM(ch.chapters), 0) AS chapters, ISNULL(SUM(v.videos), 0) AS videos, ISNULL(SUM(s.logins), 0) AS logins, ISNULL(SUM(oh.purchases), 0) AS purchases, 
                         ISNULL(SUM(w.stores), 0) AS stores
FROM            (SELECT        COUNT(SessionId) AS logins, UserID
                          FROM            dbo.UserSessions
                          GROUP BY UserID) AS s RIGHT OUTER JOIN
                             (SELECT        o.BuyerUserId, COUNT(l.LineId) AS purchases
                               FROM            dbo.SALE_Orders AS o INNER JOIN
                                                         dbo.SALE_OrderLines AS l ON o.OrderId = l.OrderId
                               GROUP BY o.BuyerUserId) AS oh RIGHT OUTER JOIN
                         dbo.Users AS u ON oh.BuyerUserId = u.Id ON s.UserID = u.Id LEFT OUTER JOIN
                             (SELECT        COUNT(StoreID) AS stores, OwnerUserID
                               FROM            dbo.WebStores AS ws
                               GROUP BY OwnerUserID) AS w ON u.Id = w.OwnerUserID LEFT OUTER JOIN
                             (SELECT        crv.AuthorUserId, COUNT(DISTINCT cv.VideoSupplierIdentifier) AS videos
                               FROM            dbo.Courses AS crv INNER JOIN
                                                         dbo.CourseChapters AS ccv ON crv.Id = ccv.CourseId INNER JOIN
                                                         dbo.ChapterVideos AS cv ON ccv.Id = cv.CourseChapterId
                               GROUP BY crv.AuthorUserId) AS v ON u.Id = v.AuthorUserId LEFT OUTER JOIN
                             (SELECT        COUNT(cc.Id) AS chapters, cr.AuthorUserId
                               FROM            dbo.Courses AS cr INNER JOIN
                                                         dbo.CourseChapters AS cc ON cr.Id = cc.CourseId
                               GROUP BY cr.AuthorUserId) AS ch ON u.Id = ch.AuthorUserId LEFT OUTER JOIN
                             (SELECT        COUNT(BundleId) AS bundles, AuthorId
                               FROM            dbo.CRS_Bundles
                               GROUP BY AuthorId) AS b ON u.Id = b.AuthorId LEFT OUTER JOIN
                             (SELECT        COUNT(Id) AS courses, AuthorUserId
                               FROM            dbo.Courses
                               GROUP BY AuthorUserId) AS c ON u.Id = c.AuthorUserId
GROUP BY u.Id, u.Email, u.Nickname, u.FirstName, u.LastName

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetStatistic]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-2-27
-- Description:	Get user statistics
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetStatistic]
(	
	@UserId INT = NULL
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT [UserId]
		  ,[Email]
		  ,[Nickname]
		  ,[FirstName]
		  ,[LastName]
		  ,[courses]
		  ,[bundles]
		  ,[chapters]
		  ,[videos]
		  ,[logins]
		  ,[purchases]
		  ,[stores]
	  FROM [dbo].[vw_USER_Statistics]
	  WHERE (@UserId IS NULL OR UserId = @UserId)		
)

GO
/****** Object:  View [dbo].[vw_USER_UserLogins]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_USER_UserLogins]
AS
SELECT ISNULL(p.UserId, - 1) AS Id, u.Id AS UserId, u.Nickname, u.FirstName, u.LastName, u.FacebookID, u.BirthDate, u.Gender, ISNULL(m.IsConfirmed, 1) AS IsConfirmed, 
                  o.ProviderUserId, o.Provider, u.Email, u.PictureURL, u.AuthorPictureURL, ISNULL(p.LastLogin, us.LastLogin) AS LastLogin, u.StatusType, ISNULL(p.AddOn, u.Created) 
                  AS RegisterDate, rt.RegistrationTypeId, rt.RegistrationTypeCode, stat.courses, stat.bundles, stat.chapters, stat.videos, stat.logins, stat.purchases, stat.stores, 
                  u.RegisterStoreId, ws.StoreName AS RegisterStoreName, u.PayoutTypeId, pt.TypeCode AS PayoutTypeCode, u.PayoutAddressID, u.PaypalEmail, u.Created, 
                  u.RegisterHostName, u.JoinedToRefundProgram, u.ProvisionUid
FROM     dbo.Users AS u INNER JOIN
                  dbo.ADMIN_RegistrationSourcesLOV AS rt ON u.RegistrationTypeId = rt.RegistrationTypeId INNER JOIN
                  dbo.vw_USER_Statistics AS stat ON u.Id = stat.UserId LEFT OUTER JOIN
                  dbo.BILL_PayoutTypesLOV AS pt ON u.PayoutTypeId = pt.PayoutTypeId LEFT OUTER JOIN
                  dbo.WebStores AS ws ON u.RegisterStoreId = ws.StoreID LEFT OUTER JOIN
                      (SELECT MAX(EventDate) AS LastLogin, UserID
                       FROM      dbo.UserSessions
                       GROUP BY UserID) AS us ON u.Id = us.UserID LEFT OUTER JOIN
                  dbo.UserProfile AS p ON u.Id = p.RefUserId LEFT OUTER JOIN
                  dbo.webpages_Membership AS m ON p.UserId = m.UserId LEFT OUTER JOIN
                  dbo.webpages_OAuthMembership AS o ON p.UserId = o.UserId

GO
/****** Object:  View [dbo].[vw_USER_UsersLib]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_USER_UsersLib]
AS
SELECT p.UserId AS Id, u.Id AS UserId, p.Email, u.Nickname, u.FirstName, u.LastName, u.ActivationToken, u.ActivationExpiration, u.FacebookID, u.FbAccessToken, 
                  u.FbAccessTokenExpired, u.PictureURL, u.BirthDate, u.PasswordDigest, u.Gender, u.BioHtml, u.AuthorPictureURL, u.AutoplayEnabled, u.salesforce_id, 
                  u.salesforce_checksum, u.DisplayActivitiesOnFB, u.ReceiveMonthlyNewsletterOnEmail, u.DisplayDiscussionFeedDailyOnFB, u.ReceiveDiscussionFeedDailyOnEmail, 
                  u.DisplayCourseNewsWeeklyOnFB, u.ReceiveCourseNewsWeeklyOnEmail, u.Created, u.LastModified, ISNULL(m.IsConfirmed, 1) AS IsConfirmed, 
                  u.LastLogin AS LastLoginDate, o.ProviderUserId, o.Provider, rt.RegistrationTypeId, rt.RegistrationTypeCode, u.AffiliateCommission, u.RegisterStoreId, 
                  ws.StoreName AS RegisterStoreName, u.PayoutTypeId, pt.TypeCode AS PayoutTypeCode, u.PayoutAddressID, u.PaypalEmail, u.RegisterHostName, p.LastLogin, 
                  p.AddOn AS RegisterDate, u.JoinedToRefundProgram, u.ProvisionUid
FROM     dbo.Users AS u INNER JOIN
                  dbo.ADMIN_RegistrationSourcesLOV AS rt ON u.RegistrationTypeId = rt.RegistrationTypeId INNER JOIN
                  dbo.UserProfile AS p ON u.Id = p.RefUserId LEFT OUTER JOIN
                  dbo.BILL_PayoutTypesLOV AS pt ON u.PayoutTypeId = pt.PayoutTypeId LEFT OUTER JOIN
                  dbo.WebStores AS ws ON u.RegisterStoreId = ws.StoreID LEFT OUTER JOIN
                  dbo.webpages_Membership AS m ON p.UserId = m.UserId LEFT OUTER JOIN
                  dbo.webpages_OAuthMembership AS o ON p.UserId = o.UserId

GO
/****** Object:  View [dbo].[vw_USER_Authors]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_USER_Authors]
AS
SELECT        Id, UserId, Email, bundles, courses, stores, total, IsAuthor, Nickname, FirstName, LastName, ActivationToken, ActivationExpiration, FacebookID, FbAccessToken, 
                         FbAccessTokenExpired, PictureURL, BirthDate, PasswordDigest, Gender, BioHtml, AuthorPictureURL, AutoplayEnabled, salesforce_id, salesforce_checksum, 
                         DisplayActivitiesOnFB, ReceiveMonthlyNewsletterOnEmail, DisplayDiscussionFeedDailyOnFB, ReceiveDiscussionFeedDailyOnEmail, 
                         DisplayCourseNewsWeeklyOnFB, ReceiveCourseNewsWeeklyOnEmail, Created, LastModified, IsConfirmed, LastLoginDate, ProviderUserId, Provider, 
                         RegistrationTypeId, RegistrationTypeCode, AffiliateCommission
FROM            (SELECT        u.Id, u.UserId, u.Email, ISNULL(b.bundles, 0) AS bundles, ISNULL(c.courses, 0) AS courses, ISNULL(s.stores, 0) AS stores, ISNULL(b.bundles, 0) 
                                                    + ISNULL(c.courses, 0) + ISNULL(s.stores, 0) AS total, CAST(CASE RegistrationTypeCode WHEN 'WIX' THEN 1 ELSE CASE ISNULL(b.bundles, 0) 
                                                    + ISNULL(c.courses, 0) + ISNULL(s.stores, 0) WHEN 0 THEN 0 ELSE 1 END END AS BIT) AS IsAuthor, u.Nickname, u.FirstName, u.LastName, 
                                                    u.ActivationToken, u.ActivationExpiration, u.FacebookID, u.FbAccessToken, u.FbAccessTokenExpired, u.PictureURL, u.BirthDate, u.PasswordDigest, 
                                                    u.Gender, u.BioHtml, u.AuthorPictureURL, u.AutoplayEnabled, u.salesforce_id, u.salesforce_checksum, u.DisplayActivitiesOnFB, 
                                                    u.ReceiveMonthlyNewsletterOnEmail, u.DisplayDiscussionFeedDailyOnFB, u.ReceiveDiscussionFeedDailyOnEmail, 
                                                    u.DisplayCourseNewsWeeklyOnFB, u.ReceiveCourseNewsWeeklyOnEmail, u.Created, u.LastModified, u.IsConfirmed, u.LastLoginDate, 
                                                    u.ProviderUserId, u.Provider, u.RegistrationTypeId, u.RegistrationTypeCode, u.AffiliateCommission
                          FROM            dbo.vw_USER_UsersLib AS u LEFT OUTER JOIN
                                                        (SELECT        COUNT(BundleId) AS bundles, AuthorId
                                                          FROM            dbo.CRS_Bundles
                                                          GROUP BY AuthorId) AS b ON b.AuthorId = u.UserId LEFT OUTER JOIN
                                                        (SELECT        COUNT(StoreID) AS stores, OwnerUserID
                                                          FROM            dbo.WebStores AS ws
                                                          GROUP BY OwnerUserID) AS s ON s.OwnerUserID = u.UserId LEFT OUTER JOIN
                                                        (SELECT        COUNT(Id) AS courses, AuthorUserId
                                                          FROM            dbo.Courses
                                                          GROUP BY AuthorUserId) AS c ON c.AuthorUserId = u.UserId) AS a
WHERE        (IsAuthor = 1)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetUser]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-2-23
-- Description:	Get user view by email
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetUser]
(	
	@Email NVARCHAR(150)
)
RETURNS TABLE 
AS
RETURN 
(


	SELECT [Id]
		  ,[UserId]
		  ,[Email]
		  ,[Nickname]
		  ,[FirstName]
		  ,[LastName]
		  ,[ActivationToken]
		  ,[ActivationExpiration]
		  ,[FacebookID]
		  ,[FbAccessToken]
		  ,[FbAccessTokenExpired]
		  ,[PictureURL]
		  ,[BirthDate]
		  ,[PasswordDigest]
		  ,[Gender]
		  ,[BioHtml]
		  ,[AuthorPictureURL]
		  ,[AutoplayEnabled]
		  ,[salesforce_id]
		  ,[salesforce_checksum]
		  ,[DisplayActivitiesOnFB]
		  ,[ReceiveMonthlyNewsletterOnEmail]
		  ,[DisplayDiscussionFeedDailyOnFB]
		  ,[ReceiveDiscussionFeedDailyOnEmail]
		  ,[DisplayCourseNewsWeeklyOnFB]
		  ,[ReceiveCourseNewsWeeklyOnEmail]
		  ,[Created]
		  ,[LastModified]
		  ,[IsConfirmed]
		  ,[LastLoginDate]
		  ,[ProviderUserId]
		  ,[Provider]
		  ,[RegistrationTypeId]
		  ,[RegistrationTypeCode]
		  ,[AffiliateCommission]
		  ,[RegisterStoreId]
		  ,[RegisterStoreName]
		  ,[PayoutTypeId]
		  ,[PayoutTypeCode]
		  ,[PayoutAddressID]
		  ,[PaypalEmail]
		  ,[RegisterHostName]
		  ,[LastLogin]
		  ,[RegisterDate]
		  ,[JoinedToRefundProgram]
		  ,[ProvisionUid]
	  FROM [dbo].[vw_USER_UsersLib]
		  WHERE Email = @Email

)

GO
/****** Object:  View [dbo].[vw_FACT_EventAggregates]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_FACT_EventAggregates]
AS
SELECT        f.EventCount, f.EventTypeID, t.TypeCode, f.EventDate, f.WebStoreId, f.ItemId, f.ItemType, f.AuthorId, f.ItemName, ws.StoreName, u.Email, u.Nickname, u.FirstName, 
                         u.LastName
FROM            dbo.WebStores AS ws RIGHT OUTER JOIN
                         dbo.Users AS u RIGHT OUTER JOIN
                         dbo.FACT_EventAgg AS f INNER JOIN
                         dbo.UserEventTypesLOV AS t ON f.EventTypeID = t.TypeId ON u.Id = f.AuthorId ON ws.StoreID = f.WebStoreId

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_ADMIN_PeriodTable]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-2-25
-- Description:	get periods list
-- =============================================
CREATE FUNCTION [dbo].[tvf_ADMIN_PeriodTable]
(
    @from DATETIME = '01/01/1900' ,
    @to DATETIME = '01/01/2199' ,
    @groupBy VARCHAR(15) = 'month'

)
RETURNS TABLE 
AS
RETURN 
(
			WITH
			cteDates AS
			(

			  SELECT TOP (
					CASE @groupBy	
						WHEN 'day'     THEN (DATEDIFF(day,@from,@to) + 1)
						WHEN 'week'    THEN  (DATEDIFF(week,@from,@to) + 1)
						WHEN 'month'    THEN (DATEDIFF(month,@from,@to) + 1)	
						WHEN 'quarter'  THEN (DATEDIFF(quarter,@from,@to) + 1)
						WHEN 'year' 	THEN (DATEDIFF(year,@from,@to) + 1)
						ELSE  (DATEDIFF(mm,@from,@to) + 1)
					END
					)
					PeriodDate =
					CASE @groupBy	
						WHEN 'day'THEN  DATEADD(day,DATEDIFF(day,0,@from) + (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) -1),0)
						WHEN 'week' THEN DATEADD(week,DATEDIFF(week,0,@from) + (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) -1),0)
						WHEN 'month' THEN DATEADD(month,DATEDIFF(month,0,@from) + (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) -1),0)
						WHEN 'quarter' THEN DATEADD(quarter,DATEDIFF(quarter,0,@from) + (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) -1),0)
						WHEN 'year' THEN DATEADD(year,DATEDIFF(year,0,@from) + (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) -1),0)
						ELSE DATEADD(month,DATEDIFF(month,0,@from) + (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) -1),0)
					END
			   FROM sys.all_columns ac1
			     CROSS JOIN sys.all_columns ac2
			)
 
			 SELECT CASE @groupBy	
					 WHEN 'day' THEN CAST(CAST(p.PeriodDate AS DATE) AS VARCHAR) 
					 WHEN 'week' THEN CAST(DATEPART(year, p.PeriodDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, p.PeriodDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, p.PeriodDate) AS VARCHAR)
					 WHEN 'month' THEN CAST(DATEPART(year, p.PeriodDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, p.PeriodDate) AS VARCHAR)
					 WHEN 'quarter' THEN CAST(DATEPART(year, p.PeriodDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, p.PeriodDate) AS VARCHAR)
					 WHEN 'year' THEN CAST(DATEPART(year, p.PeriodDate) AS VARCHAR) 
					 ELSE CAST(DATEPART(year, p.PeriodDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, p.PeriodDate) AS VARCHAR) 
					 END  AS period
			 FROM cteDates AS p
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_GetEventsDailyAggregates]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-11-04
-- Description:	Get User Events Stats
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_GetEventsDailyAggregates]
(	
	@from DATETIME, 
	@to DATETIME,
	@AuthorId INT = NULL,
	@StoreId INT = NULL
)
RETURNS TABLE 
AS
RETURN 
(

	
			SELECT   CAST(d.EventDate AS DATE) AS EventDate ,
					d.TypeId ,
					ISNULL(ev.cnt, 0) AS cnt
			FROM    ( SELECT    p.period AS EventDate ,
								lov.TypeId ,
								lov.TypeCode ,
								lov.TypeName
					  FROM      dbo.tvf_ADMIN_PeriodTable(@from, @to, 'day') AS p,dbo.UserEventTypesLOV AS lov
					) AS d
			LEFT OUTER JOIN ( SELECT    SUM(ev.EventCount) AS cnt ,
                                    ev.EventTypeID ,
                                    CAST(ev.EventDate AS DATE) AS EventDate
                          FROM      vw_FACT_EventAggregates AS ev
                          WHERE     ( CAST(ev.EventDate AS DATE) BETWEEN @from AND @to )
                                    AND ( @AuthorId IS NULL OR ev.AuthorId = @AuthorId)
                                    AND ( @StoreId IS NULL OR ev.WebStoreId = @StoreId)
                          GROUP BY  ev.EventTypeID ,
                                    CAST(ev.EventDate AS DATE)
                        ) AS ev ON d.TypeId = ev.EventTypeID
                                   AND d.EventDate = ev.EventDate			
)

GO
/****** Object:  View [dbo].[vw_USER_EventsLog]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_USER_EventsLog]
AS
SELECT        TOP (100) PERCENT e.EventID, s.SessionId, s.NetSessionId, s.UserID, u.Nickname, u.FirstName, u.LastName, u.PictureURL, s.IPAddress, s.HttpHeaders, 
                         s.EventDate AS SessionDate, e.EventTypeID, t.TypeCode, t.TypeName, e.AdditionalData, e.EventDate, u.FacebookID, e.AubsoluteUri, e.CourseId, c.CourseName, 
                         c.AuthorUserId AS CourseAuthorId, cu.FirstName AS CourseAuthorFirstName, cu.LastName AS CourseAuthorLastName, cu.Nickname AS CourseAuthorNickname, 
                         e.BundleId, b.BundleName, b.AuthorId AS BundleAuthorId, bu.FirstName AS BundleAuthorFirstName, bu.LastName AS BundleAuthorLastName, 
                         bu.Nickname AS BundleAuthorNickname, e.WebStoreId, w.StoreName, w.TrackingID, w.WixSiteUrl, w.OwnerUserID AS StoreOwnerUserID, 
                         su.Nickname AS StoreOwnerNickname, su.FirstName AS StoreOwnerFirstName, su.LastName AS StoreOwnerLastName, e.VideoBcIdentifier, uv.Name AS VideoName, 
                         uv.Duration AS VideoDuration, uv.ThumbUrl AS VideoThumbUrl, uv.UserId AS VideoAuthorId, vu.FirstName AS VideoAuthorFirstName, 
                         vu.LastName AS VideoAuthorLastName, vu.Nickname AS VideoAuthorNickname, e.HostName
FROM            dbo.CRS_Bundles AS b INNER JOIN
                         dbo.Users AS bu ON b.AuthorId = bu.Id RIGHT OUTER JOIN
                         dbo.UserSessionsEventLogs AS e INNER JOIN
                         dbo.UserEventTypesLOV AS t ON e.EventTypeID = t.TypeId INNER JOIN
                         dbo.UserSessions AS s ON e.SessionId = s.SessionId ON b.BundleId = e.BundleId LEFT OUTER JOIN
                         dbo.WebStores AS w INNER JOIN
                         dbo.Users AS su ON w.OwnerUserID = su.Id ON e.WebStoreId = w.StoreID LEFT OUTER JOIN
                         dbo.Courses AS c INNER JOIN
                         dbo.Users AS cu ON c.AuthorUserId = cu.Id ON e.CourseId = c.Id LEFT OUTER JOIN
                         dbo.Users AS vu RIGHT OUTER JOIN
                         dbo.USER_Videos AS uv ON vu.Id = uv.UserId ON e.VideoBcIdentifier = uv.BcIdentifier LEFT OUTER JOIN
                         dbo.Users AS u ON s.UserID = u.Id

GO
/****** Object:  View [dbo].[vw_USER_LastEventDates]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_USER_LastEventDates]
AS
SELECT        UserID, MAX(EventDate) AS EventDate
FROM            (SELECT        UserID, MAX(EventDate) AS EventDate
                          FROM            dbo.vw_USER_EventsLog AS eac
                          GROUP BY UserID
                          UNION
                          SELECT        CAST(CourseAuthorId AS INT) AS UserID, MAX(EventDate) AS EventDate
                          FROM            dbo.vw_USER_EventsLog AS eac
                          WHERE        (CourseAuthorId IS NOT NULL)
                          GROUP BY CourseAuthorId
                          UNION
                          SELECT        CAST(BundleAuthorId AS INT) AS UserID, MAX(EventDate) AS EventDate
                          FROM            dbo.vw_USER_EventsLog AS eac
                          WHERE        (BundleAuthorId IS NOT NULL)
                          GROUP BY BundleAuthorId
                          UNION
                          SELECT        CAST(VideoAuthorId AS INT) AS UserID, MAX(EventDate) AS EventDate
                          FROM            dbo.vw_USER_EventsLog AS eac
                          WHERE        (VideoAuthorId IS NOT NULL)
                          GROUP BY VideoAuthorId) AS t
GROUP BY UserID

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetEventsLog]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-7-28
-- Description:	Get User vents rep
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetEventsLog]
(	
	--@page INT,
	--@size INT,
	@from DATETIME, 
	@to DATETIME,
	@UserId INT = NULL,
	@CourseId INT = NULL,
	@BundleId INT = NULL,
	@StoreId  INT = NULL,
	@SessionId BIGINT = NULL,
	@EventTypeID SMALLINT = NULL
)
RETURNS TABLE 
AS
RETURN 
(


		SELECT [EventID]
			  ,[SessionId]
			  ,[NetSessionId]
			  ,[UserID]
			  ,[Nickname]
			  ,[FirstName]
			  ,[LastName]
			  ,[PictureURL]
			  ,[IPAddress]
			  ,[HostName]
			  ,[HttpHeaders]
			  ,[SessionDate]
			  ,[EventTypeID]
			  ,[TypeCode]
			  ,[TypeName]
			  ,[AdditionalData]
			  ,[EventDate]
			  ,[FacebookID]
			  ,[AubsoluteUri]
			  ,[CourseId]
			  ,[CourseName]
			  ,[CourseAuthorId]
			  ,[CourseAuthorFirstName]
			  ,[CourseAuthorLastName]
			  ,[CourseAuthorNickname]
			  ,[BundleId]
			  ,[BundleName]
			  ,[BundleAuthorId]
			  ,[BundleAuthorFirstName]
			  ,[BundleAuthorLastName]
			  ,[BundleAuthorNickname]
			  ,[WebStoreId]
			  ,[StoreName]
			  ,[TrackingID]
			  ,[WixSiteUrl]
			  ,[StoreOwnerUserID]
			  ,[StoreOwnerNickname]
			  ,[StoreOwnerFirstName]
			  ,[StoreOwnerLastName]
			  ,[VideoBcIdentifier]
			  ,[VideoName]
			  ,[VideoDuration]
			  ,[VideoThumbUrl]
			  ,[VideoAuthorId]
			  ,[VideoAuthorFirstName]
			  ,[VideoAuthorLastName]
			  ,[VideoAuthorNickname]
		  FROM [dbo].[vw_USER_EventsLog]
		  WHERE (EventDate BETWEEN @from  AND @to)
				AND (@UserId IS NULL OR UserID = @UserId)
				AND (@CourseId IS NULL OR CourseId = @CourseId)
				AND (@BundleId IS NULL OR BundleId = @BundleId)
				AND (@StoreId IS NULL OR WebStoreId = @StoreId)
				AND (@SessionId IS NULL OR SessionId = @SessionId)
				AND (@EventTypeID IS NULL OR EventTypeID = @EventTypeID)
		 --ORDER BY EventDate DESC
		-- OFFSET @size*(@page-1) ROWS
		-- FETCH NEXT @size ROWS ONLY		 
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_DASH_GetLearnerPeriodStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-21
-- Description:	Get learner period stats
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_DASH_GetLearnerPeriodStats] ( @From DATE, @To DATE )
RETURNS TABLE
AS
RETURN
    ( 
		SELECT  ISNULL(t.TotalLearners, 0) AS TotalActiveLearners ,
				ISNULL(t.TotalVideosWatched, 0) AS TotalVideosWatched ,
				ISNULL(t.TotalCoursesWatched, 0) AS TotalCoursesWatched ,
				ISNULL(al.AvgLearnerLogin, 0) AS AvgLearnerLogin ,
				ISNULL(vp.TotalVideoPreveiwWatched, 0) AS TotalVideoPreveiwWatched ,
				ISNULL(cp.TotalCoursePreviewEntered, 0) AS TotalCoursePreviewEntered ,
				ISNULL(pp.TotalPurchasePageEntered, 0) AS TotalPurchasePageEntered ,
				ISNULL(pc.TotalPurchaseComplete, 0) AS TotalPurchaseComplete
		FROM    ( SELECT    COUNT(DISTINCT UserID) AS TotalLearners ,
							COUNT(DISTINCT EventID) AS TotalVideosWatched ,
							COUNT(DISTINCT CourseId) AS TotalCoursesWatched
				  FROM      dbo.vw_USER_EventsLog
				  WHERE     ( TypeCode = N'VIDEO_COURSE_WATCH' )
							AND ( UserID <> CourseAuthorId )
							AND CAST(EventDate AS DATE) >= CAST(@From AS DATE)
							AND CAST(EventDate AS DATE) <= CAST(@To AS DATE)
				) AS t ,
				( SELECT    CAST(COUNT(DISTINCT l.LoginId) AS DECIMAL)/ CAST(COUNT(DISTINCT l.UserId) AS DECIMAL) AS AvgLearnerLogin ,
							COUNT(l.LoginId) AS TotalLearnersLogin
				  FROM      dbo.USER_Logins AS l
				  WHERE     CAST(l.LoginDate AS DATE) >= CAST(@From AS DATE)
							AND CAST(l.LoginDate AS DATE) <= CAST(@To AS DATE)
							AND l.UserId IN (
							SELECT DISTINCT
									UserID
							FROM    dbo.vw_USER_EventsLog
							WHERE   ( TypeCode = N'VIDEO_COURSE_WATCH' )
									AND ( UserID <> CourseAuthorId )
									AND CAST(EventDate AS DATE) >= CAST(@From AS DATE)
									AND CAST(EventDate AS DATE) <= CAST(@To AS DATE) )
				) AS al ,
				( SELECT    COUNT(EventID) AS TotalVideoPreveiwWatched
				  FROM      dbo.vw_USER_EventsLog
				  WHERE     ( TypeCode = N'VIDEO_PREVIEW_WATCH' )
							AND ( UserID <> CourseAuthorId )
							AND CAST(EventDate AS DATE) >= CAST(@From AS DATE)
							AND CAST(EventDate AS DATE) <= CAST(@To AS DATE)
				) AS vp ,
				( SELECT    COUNT(EventID) AS TotalCoursePreviewEntered
				  FROM      dbo.vw_USER_EventsLog
				  WHERE     ( TypeCode = N'COURSE_PREVIEW_ENTER' )
							AND ( UserID <> CourseAuthorId )
							AND CAST(EventDate AS DATE) >= CAST(@From AS DATE)
							AND CAST(EventDate AS DATE) <= CAST(@To AS DATE)
				) AS cp ,
				( SELECT    COUNT(EventID) AS TotalPurchasePageEntered
				  FROM      dbo.vw_USER_EventsLog
				  WHERE     ( TypeCode = N'BUY_PAGE_ENTERED' )
							AND ( UserID <> CourseAuthorId )
							AND CAST(EventDate AS DATE) >= CAST(@From AS DATE)
							AND CAST(EventDate AS DATE) <= CAST(@To AS DATE)
				) AS pp ,
				( SELECT    COUNT(EventID) AS TotalPurchaseComplete
				  FROM      dbo.vw_USER_EventsLog
				  WHERE     ( TypeCode = N'PURCHASE_COMPLETE' )
							AND ( UserID <> CourseAuthorId )
							AND CAST(EventDate AS DATE) >= CAST(@From AS DATE)
							AND CAST(EventDate AS DATE) <= CAST(@To AS DATE)
				) AS pc
    )

GO
/****** Object:  View [dbo].[vw_USER_LastActivityDates]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_USER_LastActivityDates]
AS
SELECT        MAX(ISNULL(ISNULL(e.EventDate, ISNULL(p.LastLogin, ISNULL(l.LoginDate, u.LastLogin))), u.Created)) AS LastActivityDate, u.FirstName, u.LastName, u.Id AS UserID,
                          u.Email
FROM            dbo.USER_Logins AS l RIGHT OUTER JOIN
                         dbo.vw_USER_LastEventDates AS e RIGHT OUTER JOIN
                         dbo.Users AS u ON e.UserID = u.Id ON l.UserId = u.Id LEFT OUTER JOIN
                         dbo.UserProfile AS p ON u.Id = p.RefUserId
GROUP BY u.FirstName, u.LastName, u.Id, u.Email

GO
/****** Object:  View [dbo].[vw_USER_LastSaleDates]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_USER_LastSaleDates]
AS
SELECT        SellerUserId, MAX(OrderDate) AS OrderDate
FROM            dbo.SALE_Orders
WHERE        (BuyerUserId <> SellerUserId)
GROUP BY SellerUserId

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetVideosState]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetVideosState]
(	
	  @OldMont INT ,
    @ExcludeSales BIT = 0
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	 SELECT  CAST(v.BcIdentifier AS VARCHAR(30)) AS BcIdentifier ,
                v.UserId ,
                u.FirstName ,
                u.LastName ,
                u.Email ,
                v.Attached2Chapter AS Attached ,
                s.OrderDate,
				u.LastActivityDate
        FROM    dbo.USER_Videos AS v
                INNER JOIN dbo.vw_USER_LastActivityDates AS u ON v.UserId = u.UserID
                LEFT OUTER JOIN dbo.vw_USER_LastSaleDates AS s ON v.UserId = s.SellerUserId
        WHERE   ( u.LastActivityDate < DATEADD(MONTH, -@OldMont, GETDATE()) )
                AND ( @ExcludeSales = 0 OR s.OrderDate IS NULL)
				AND (v.UserId NOT IN (2225, -- Monicas Jones
									  1655, -- Jeff Minder
									  1594, -- Nathan Schoemer
									  1585, -- Esther Coronel
									  306 -- Lyle
									  ))
)

GO
/****** Object:  View [dbo].[vw_CRS_SubscriberCnt]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_CRS_SubscriberCnt]
AS
SELECT        COUNT(dbo.USER_Courses.UserCourseId) AS cnt, dbo.USER_Courses.CourseId
FROM            dbo.USER_Courses INNER JOIN
                         dbo.SALE_UserAccessStatusesLOV ON dbo.USER_Courses.StatusId = dbo.SALE_UserAccessStatusesLOV.StatusId
GROUP BY dbo.USER_Courses.CourseId

GO
/****** Object:  View [dbo].[vw_CRS_BundleSubscriberCnt]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_CRS_BundleSubscriberCnt]
AS
SELECT        BundleId, COUNT(UserBundleId) AS cnt
FROM            dbo.USER_Bundles
GROUP BY BundleId

GO
/****** Object:  View [dbo].[vw_CRS_BundleCoursesCnt]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_CRS_BundleCoursesCnt]
AS
SELECT        BundleId, COUNT(CourseId) AS cnt
FROM            dbo.CRS_BundleCourses
GROUP BY BundleId

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_WS_SearchItems]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-3-16
-- Description:	Get Publish items for store manage
-- =============================================
CREATE FUNCTION [dbo].[tvf_WS_SearchItems]
(	
	 @CurrencyId SMALLINT = 2 -- USD
	,@ItemStatusId TINYINT = NULL
	,@AuthorId INT = NULL
	,@ItemName NVARCHAR(512) = NULL
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT  ItemName ,
			ItemTypeId ,
			ISNULL(AuthorName,Nickname) AS AuthorName,
			AuthorID ,
			ItemId ,
			ProvisionUid,
			ItemDescription,
			UrlName ,
			ImageURL ,
			dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@CurrencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
			dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@CurrencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created ,
			StatusId AS ItemStatusId ,      
			CoursesCnt ,
			AffiliateCommission
	FROM    ( SELECT    usr.FirstName + ' ' + usr.LastName AS AuthorName ,
						usr.Nickname,
						crs.AuthorUserId AS AuthorId ,
						crs.Id AS ItemId ,
						crs.ProvisionUid,
						1 AS ItemTypeId, 
						crs.CourseName AS ItemName,
						crs.CourseUrlName AS UrlName ,
						crs.SmallImage AS ImageURL ,						
						ISNULL(s.cnt, 0) AS NumSubscribers ,
						ISNULL(crs.Rating, 0) AS Rating ,
						crs.IsFreeCourse ,
						crs.Created ,
						crs.StatusId ,
						1 AS CoursesCnt ,
						crs.AffiliateCommission,
						CAST(crs.Description AS NVARCHAR(MAX)) AS ItemDescription
			  FROM      dbo.Courses AS crs
						INNER JOIN dbo.Users AS usr ON crs.AuthorUserId = usr.Id
						LEFT OUTER JOIN dbo.vw_CRS_SubscriberCnt AS s ON crs.Id = s.CourseId
			  UNION
			  SELECT    au.FirstName + ' ' + au.LastName AS AuthorName ,
						au.Nickname,
						b.AuthorId AS AuthorId ,
						b.BundleId AS ItemId ,
						b.ProvisionUid,
						2 AS ItemTypeId, 
						b.BundleName AS ItemName,
						b.BundleUrlName AS UrlName ,
						b.BannerImage AS ImageURL ,						
						ISNULL(s.cnt, 0) AS NumSubscribers ,
						0 AS Rating ,
						CAST(0 AS BIT) AS IsFreeCourse ,
						b.AddOn ,
						b.StatusId ,
						ISNULL(bc.cnt, 0) AS CoursesCnt ,
						b.AffiliateCommission,
						CAST(b.BundleDescription AS NVARCHAR(MAX)) AS ItemDescription
			  FROM      dbo.vw_CRS_BundleCoursesCnt AS bc
						RIGHT OUTER JOIN dbo.vw_CRS_BundleSubscriberCnt AS s
						RIGHT OUTER JOIN dbo.CRS_Bundles AS b ON s.BundleId = b.BundleId
						INNER JOIN dbo.Users AS au ON au.Id = b.AuthorId ON bc.BundleId = b.BundleId
			) AS i
	WHERE (@ItemStatusId IS NULL OR i.StatusId = @ItemStatusId)
		   AND (@AuthorId IS NULL OR i.AuthorId = @AuthorId	)
		   AND (@ItemName IS NULL OR i.ItemName LIKE '%' + @ItemName + '%')
)

GO
/****** Object:  View [dbo].[vw_CRS_ReviewCnt]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_CRS_ReviewCnt]
AS
SELECT        COUNT(Id) AS cnt, CourseId
FROM            dbo.UserCourseReviews
GROUP BY CourseId

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_SearchItems]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-3-17
-- Description:	search user items(courses & bundles)
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_SearchItems]
(
    @CurrencyId SMALLINT = 2, -- USD
	@AuthorID INT = NULL ,
	@ItemId INT = NULL,
    @StatusId TINYINT = NULL
)
RETURNS TABLE
AS
RETURN
    ( 
	  SELECT ItemId ,
			 Uid ,
			 ProvisionUid,
			 ItemTypeId ,
			 AuthorId ,
			 AuthorNickname ,
			 AuthorFirstName ,
			 AuthorLastName ,
			 ItemName ,
			 UrlName ,
			 ImageURL ,
			 dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@CurrencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
			 dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@CurrencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
			 NumSubscribers ,
			 Rating ,
			 IsFreeCourse ,
			 Created ,
			 StatusId ,
			 CoursesCnt ,
			 AffiliateCommission ,
			 ItemDescription
	  FROM
	  (
			  SELECT    c.Id AS ItemId ,
						c.uid AS Uid ,
						c.ProvisionUid,
						1 AS ItemTypeId ,
						c.AuthorUserId AS AuthorId ,
						u.Nickname AS AuthorNickname ,
						u.FirstName AS AuthorFirstName ,
						u.LastName AS AuthorLastName ,
						c.CourseName AS ItemName ,
						c.CourseUrlName AS UrlName ,
						c.SmallImage AS ImageURL ,               
						ISNULL(s.cnt, 0) AS NumSubscribers ,
						ISNULL(c.Rating, 0) AS Rating ,
						c.IsFreeCourse ,
						c.Created ,
						c.StatusId ,
						1 AS CoursesCnt ,
						c.AffiliateCommission ,
						CAST(c.Description AS NVARCHAR(MAX)) AS ItemDescription
			  FROM      dbo.Courses AS c
						INNER JOIN dbo.Users AS u ON c.AuthorUserId = u.Id
						LEFT OUTER JOIN dbo.vw_CRS_SubscriberCnt AS s ON c.Id = s.CourseId
						LEFT OUTER JOIN dbo.vw_CRS_ReviewCnt AS r ON r.CourseId = c.Id
			  WHERE     ( @AuthorID IS NULL OR c.AuthorUserId = @AuthorID)
						AND ( @ItemId IS NULL OR c.Id = @ItemId)
						AND ( @StatusId IS NULL OR c.StatusId = @StatusId)
			  UNION
			  SELECT    b.BundleId AS ItemId ,
						b.uid AS Uid ,
						b.ProvisionUid,
						2 AS ItemTypeId ,
						b.AuthorId AS AuthorId ,
						u.Nickname AS AuthorNickname ,
						u.FirstName AS AuthorFirstName ,
						u.LastName AS AuthorLastName ,
						b.BundleName AS ItemName ,
						b.BundleUrlName AS UrlName ,
						b.BannerImage AS ImageURL ,               
						ISNULL(s.cnt, 0) AS NumSubscribers ,
						0 AS Rating ,
						CAST(0 AS BIT) AS IsFreeCourse ,
						b.AddOn ,
						b.StatusId ,
						ISNULL(bc.cnt, 0) AS CoursesCnt ,
						b.AffiliateCommission ,
						CAST(b.BundleDescription AS NVARCHAR(MAX)) AS ItemDescription
			  FROM      dbo.vw_CRS_BundleCoursesCnt AS bc
						RIGHT OUTER JOIN dbo.vw_CRS_BundleSubscriberCnt AS s
						RIGHT OUTER JOIN dbo.CRS_Bundles AS b ON s.BundleId = b.BundleId
						INNER JOIN dbo.Users AS u ON u.Id = b.AuthorId ON bc.BundleId = b.BundleId
			  WHERE     ( @AuthorID IS NULL OR b.AuthorId = @AuthorID)
						AND ( @ItemId IS NULL OR b.BundleId = @ItemId)
						AND ( @StatusId IS NULL OR b.StatusId = @StatusId)
			) AS i
	)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_LRNR_GetCourses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-7-23
-- Description:	Get learner courses
-- =============================================
CREATE FUNCTION [dbo].[tvf_LRNR_GetCourses] (@CurrencyId SMALLINT = 2,@LearnerId INT,@UserID INT )
RETURNS TABLE
AS
RETURN	
(
		SELECT  c.Id ,
				c.uid AS Uid ,
				c.AuthorUserId ,
				u.Nickname AS AuthorNickname ,
				u.FirstName AS AuthorFirstName ,
				u.LastName AS AuthorLastName ,
				c.CourseName ,
				dbo.fn_BILL_GetItemPrice(c.Id,1,@CurrencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
				dbo.fn_BILL_GetItemPrice(c.Id,1,@CurrencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
				c.Created ,
				c.SmallImage ,
				c.OverviewVideoIdentifier ,
				ISNULL(r.cnt, 0) AS ReviewCount ,
				ISNULL(c.Rating, 0) AS Rating ,
				ISNULL(s.cnt, 0) AS NumSubscribers ,
				uc.UserId,
				c.IsFreeCourse,
				c.CourseUrlName
		FROM    dbo.Courses AS c
				INNER JOIN dbo.USER_Courses AS uc ON c.Id = uc.CourseId
				INNER JOIN dbo.Users AS u ON c.AuthorUserId = u.Id
				LEFT OUTER JOIN ( SELECT    UserCourseId AS Id ,
											CourseId
									FROM      dbo.USER_Courses
									WHERE     ( UserId = @UserID ) AND (StatusId=1) --active
									GROUP BY  UserCourseId ,
											CourseId
								) AS cuc ON c.Id = cuc.CourseId
				LEFT OUTER JOIN dbo.vw_CRS_SubscriberCnt AS s ON c.Id = s.CourseId
				LEFT OUTER JOIN dbo.vw_CRS_ReviewCnt AS r ON r.CourseId = c.Id
		WHERE   ( uc.UserId = @LearnerId ) AND (c.StatusId=2) --published
		GROUP BY  c.Id ,
				c.uid,
				c.AuthorUserId ,
				u.Nickname,
				u.FirstName,
				u.LastName,
				c.CourseName ,				
				c.Created ,
				c.SmallImage ,
				c.OverviewVideoIdentifier ,
				ISNULL(r.cnt, 0),
				ISNULL(c.Rating, 0),
				ISNULL(s.cnt, 0),
				uc.UserId,
				c.IsFreeCourse,
				c.CourseUrlName
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetAuthorCourses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-6-9
-- Description:	Get author courses
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetAuthorCourses]
(	
	@CurrencyId SMALLINT = 2, -- USD	
	@AuthorID INT,
	@UserID INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT  c.Id ,
			c.uid AS Uid ,
			c.AuthorUserId ,
			u.Nickname AS AuthorNickname ,
			u.FirstName AS AuthorFirstName ,
			u.LastName AS AuthorLastName ,
			c.CourseName ,
			dbo.fn_BILL_GetItemPrice(c.Id,1,@CurrencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
			dbo.fn_BILL_GetItemPrice(c.Id,1,@CurrencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
			c.Created ,
			c.SmallImage ,
			c.OverviewVideoIdentifier ,
			ISNULL(r.cnt, 0) AS ReviewCount ,
			ISNULL(s.cnt, 0) AS LearnerCount
	FROM    dbo.Courses AS c
			INNER JOIN dbo.Users AS u ON c.AuthorUserId = u.Id
			LEFT OUTER JOIN ( SELECT    UserCourseId AS Id ,
										CourseId
							  FROM      dbo.USER_Courses
							  WHERE     ( UserId = @UserID ) AND (StatusId=1) --active
							  GROUP BY  UserCourseId ,
										CourseId
							) AS cuc ON c.Id = cuc.CourseId
			LEFT OUTER JOIN dbo.vw_CRS_SubscriberCnt AS s ON c.Id = s.CourseId
			LEFT OUTER JOIN dbo.vw_CRS_ReviewCnt AS r ON r.CourseId = c.Id
	WHERE   ( c.AuthorUserId = @AuthorID ) AND (c.StatusId=2) --published
	GROUP BY  c.Id ,
				c.uid,
				c.AuthorUserId ,
				u.Nickname,
				u.FirstName,
				u.LastName,
				c.CourseName ,											
				c.Created ,
				c.SmallImage ,
				c.OverviewVideoIdentifier ,
				ISNULL(r.cnt, 0),
				ISNULL(s.cnt, 0)
)


GO
/****** Object:  View [dbo].[vw_WS_Items]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_WS_Items]
AS
SELECT WebstoreItemId, ItemName, ItemTypeId, ItemDescription, Ordinal, AuthorName, AuthorID, ItemId, ProvisionUid AS ItemProvisionUid, UrlName, ImageURL, NumSubscribers, 
                  Rating, IsFreeCourse, Created, TrackingID, StatusId AS ItemStatusId, StoreID, OwnerUserID, WebStoreCategoryID, CategoryOrdinal, CoursesCnt, AffiliateCommission
FROM     (SELECT WC.WebstoreItemId, C.CourseName AS ItemName, WC.ItemTypeId, WC.Ordinal, U.FirstName + ' ' + U.LastName AS AuthorName, C.AuthorUserId AS AuthorID, 
                                    C.Id AS ItemId, C.ProvisionUid, C.CourseUrlName AS UrlName, C.SmallImage AS ImageURL, ISNULL(s.cnt, 0) AS NumSubscribers, ISNULL(C.Rating, 0) AS Rating, 
                                    C.IsFreeCourse, C.Created, WS.TrackingID, C.StatusId, WS.StoreID, WS.OwnerUserID, WC2.WebStoreCategoryID, WC2.Ordinal AS CategoryOrdinal, 
                                    1 AS CoursesCnt, C.AffiliateCommission, CAST(C.Description AS NVARCHAR(MAX)) AS ItemDescription
                  FROM      dbo.WebStoreItems AS WC INNER JOIN
                                    dbo.Courses AS C ON WC.CourseId = C.Id INNER JOIN
                                    dbo.Users AS U ON C.AuthorUserId = U.Id INNER JOIN
                                    dbo.WebStoreCategories AS WC2 ON WC.WebStoreCategoryID = WC2.WebStoreCategoryID INNER JOIN
                                    dbo.WebStores AS WS ON WS.StoreID = WC2.WebStoreID LEFT OUTER JOIN
                                    dbo.vw_CRS_SubscriberCnt AS s ON C.Id = s.CourseId
                  UNION
                  SELECT si.WebstoreItemId, b.BundleName AS ItemName, si.ItemTypeId, si.Ordinal, au.FirstName + ' ' + au.LastName AS AuthorName, b.AuthorId AS AuthorID, 
                                    b.BundleId AS ItemId, b.ProvisionUid, b.BundleUrlName AS UrlName, b.BannerImage AS ImageURL, ISNULL(s.cnt, 0) AS NumSubscribers, 0 AS Rating, 
                                    CAST(0 AS BIT) AS IsFreeCourse, b.AddOn AS Created, ws.TrackingID, b.StatusId, ws.StoreID, ws.OwnerUserID, sc.WebStoreCategoryID, 
                                    sc.Ordinal AS CategoryOrdinal, ISNULL(bc.cnt, 0) AS CoursesCnt, b.AffiliateCommission, CAST(b.BundleDescription AS NVARCHAR(MAX)) AS ItemDescription
                  FROM     dbo.vw_CRS_BundleSubscriberCnt AS s RIGHT OUTER JOIN
                                    dbo.CRS_Bundles AS b ON s.BundleId = b.BundleId INNER JOIN
                                    dbo.WebStoreItems AS si ON b.BundleId = si.BundleId INNER JOIN
                                    dbo.Users AS au ON au.Id = b.AuthorId INNER JOIN
                                    dbo.WebStoreCategories AS sc ON si.WebStoreCategoryID = sc.WebStoreCategoryID INNER JOIN
                                    dbo.WebStores AS ws ON ws.StoreID = sc.WebStoreID LEFT OUTER JOIN
                                    dbo.vw_CRS_BundleCoursesCnt AS bc ON b.BundleId = bc.BundleId) AS i

GO
/****** Object:  View [dbo].[vw_USER_Items]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_USER_Items]
AS
SELECT        UserItemId, ItemTypeId, OrderLineId, UserId, ItemId, AccessStatusId, uid, ItemName, ItemUrlName, ItemDescription, AuthorId, AuthorNickName, AuthorFirstName, 
                         AuthorLastName, IsFreeCourse, ImageUrl, Rating, NumSubscribers, ItemStatusId, FbObjectId, Created, CoursesCnt, ValidUntil
FROM            (SELECT        uc.UserCourseId AS UserItemId, lov.ItemTypeId, uc.OrderLineId, uc.UserId, uc.CourseId AS ItemId, uc.StatusId AS AccessStatusId, c.uid, 
                                                    c.CourseName AS ItemName, c.CourseUrlName AS ItemUrlName, CAST(c.Description AS NVARCHAR(MAX)) AS ItemDescription, 
                                                    c.AuthorUserId AS AuthorId, u.Nickname AS AuthorNickName, u.FirstName AS AuthorFirstName, u.LastName AS AuthorLastName, c.IsFreeCourse, 
                                                    c.SmallImage AS ImageUrl, ISNULL(c.Rating, 0) AS Rating, ISNULL(s.cnt, 0) AS NumSubscribers, c.StatusId AS ItemStatusId, c.FbObjectId, c.Created, 
                                                    1 AS CoursesCnt, uc.ValidUntil
                          FROM            dbo.USER_Courses AS uc INNER JOIN
                                                    dbo.Courses AS c ON uc.CourseId = c.Id INNER JOIN
                                                    dbo.Users AS u ON c.AuthorUserId = u.Id LEFT OUTER JOIN
                                                    dbo.vw_CRS_SubscriberCnt AS s ON c.Id = s.CourseId CROSS JOIN
                                                    dbo.SALE_ItemTypesLOV AS lov
                          WHERE        (lov.ItemTypeCode = 'COURSE')
                          UNION
                          SELECT        ub.UserBundleId AS UserItemId, lov.ItemTypeId, ub.OrderLineId, ub.UserId, ub.BundleId AS ItemId, ub.StatusId AS AccessStatusId, b.uid, 
                                                   b.BundleName AS ItemName, b.BundleUrlName AS ItemUrlName, CAST(b.BundleDescription AS NVARCHAR(MAX)) AS ItemDescription, b.AuthorId, 
                                                   u.Nickname AS AuthorNickName, u.FirstName AS AuthorFirstName, u.LastName AS AuthorLastName, CAST(0 AS BIT) AS IsFreeCourse, 
                                                   b.BannerImage AS ImageUrl, 0 AS Expr3, ISNULL(s.cnt, 0) AS NumSubscribers, b.StatusId AS ItemStatusId, b.FbObjectId, b.AddOn, ISNULL(bc.cnt, 0) 
                                                   AS CoursesCnt, NULL AS ValidUntil
                          FROM            dbo.USER_Bundles AS ub INNER JOIN
                                                   dbo.CRS_Bundles AS b ON ub.BundleId = b.BundleId INNER JOIN
                                                   dbo.Users AS u ON b.AuthorId = u.Id LEFT OUTER JOIN
                                                   dbo.vw_CRS_BundleCoursesCnt AS bc ON b.BundleId = bc.BundleId LEFT OUTER JOIN
                                                   dbo.vw_CRS_BundleSubscriberCnt AS s ON b.BundleId = s.BundleId CROSS JOIN
                                                   dbo.SALE_ItemTypesLOV AS lov
                          WHERE        (lov.ItemTypeCode = 'BUNDLE')) AS i

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetCourses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-6-9
-- Description:	Get author courses
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetCourses]
(	
	 @CurrencyId SMALLINT = 2 -- USD
	,@AuthorID INT = NULL	
)
RETURNS TABLE 
AS
RETURN 
(
	
	 SELECT c.Id ,
			c.uid AS Uid ,
			c.AuthorUserId ,
			u.Nickname AS AuthorNickname ,
			u.FirstName AS AuthorFirstName ,
			u.LastName AS AuthorLastName,
			c.CourseName ,
			dbo.fn_BILL_GetItemPrice(c.Id,1,@CurrencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
			dbo.fn_BILL_GetItemPrice(c.Id,1,@CurrencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
			c.Created ,
			c.SmallImage ,
			c.OverviewVideoIdentifier,
			ISNULL(r.cnt, 0) AS ReviewCount ,
			ISNULL(s.cnt, 0) AS LearnerCount ,
			c.StatusId,
			c.IsFreeCourse
	 FROM   dbo.Courses AS c
			INNER JOIN dbo.Users AS u ON c.AuthorUserId = u.Id
			LEFT OUTER JOIN dbo.vw_CRS_SubscriberCnt AS s ON c.Id = s.CourseId
			LEFT OUTER JOIN dbo.vw_CRS_ReviewCnt AS r ON r.CourseId = c.Id
	 WHERE  (@AuthorID IS NULL OR c.AuthorUserId = @AuthorID)		  
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_GetDailyItemsStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-4-9
-- Description:	Get daily items statistics
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_GetDailyItemsStats]
(
      @CurrencyId SMALLINT = 2, -- USD
      @EventDate DATE ,
      @Published BIT
)
RETURNS TABLE
AS
RETURN
    ( 
	 SELECT		ItemId ,
                Uid ,
                ItemTypeId ,
                AuthorId ,
                AuthorNickname ,
                AuthorFirstName ,
                AuthorLastName ,
                ItemName ,
                UrlName ,
                ImageURL ,
                dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@CurrencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
				dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@CurrencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
                NumSubscribers ,
                Rating ,
                IsFreeCourse ,
                Created ,
                StatusId ,
                CoursesCnt ,
                AffiliateCommission ,
                ItemDescription
	 FROM
	 (
	 SELECT    c.Id AS ItemId ,
                c.uid AS Uid ,
                1 AS ItemTypeId ,
                c.AuthorUserId AS AuthorId ,
                u.Nickname AS AuthorNickname ,
                u.FirstName AS AuthorFirstName ,
                u.LastName AS AuthorLastName ,
                c.CourseName AS ItemName ,
                c.CourseUrlName AS UrlName ,
                c.SmallImage AS ImageURL ,                
                ISNULL(s.cnt, 0) AS NumSubscribers ,
                ISNULL(c.Rating, 0) AS Rating ,
                c.IsFreeCourse ,
                c.Created ,
                c.StatusId ,
                1 AS CoursesCnt ,
                c.AffiliateCommission ,
                CAST(c.Description AS NVARCHAR(MAX)) AS ItemDescription
      FROM      dbo.Courses AS c
                INNER JOIN dbo.Users AS u ON c.AuthorUserId = u.Id
                LEFT OUTER JOIN dbo.vw_CRS_SubscriberCnt AS s ON c.Id = s.CourseId
                LEFT OUTER JOIN dbo.vw_CRS_ReviewCnt AS r ON r.CourseId = c.Id
      WHERE      (@Published = 0 AND ( CAST(c.Created AS DATE) = CAST(@EventDate AS DATE) ))
                 OR ( @Published = 1 AND CAST(c.PublishDate AS DATE) = CAST(@EventDate AS DATE))
                
      UNION
      SELECT    b.BundleId AS ItemId ,
                b.uid AS Uid ,
                2 AS ItemTypeId ,
                b.AuthorId AS AuthorId ,
                u.Nickname AS AuthorNickname ,
                u.FirstName AS AuthorFirstName ,
                u.LastName AS AuthorLastName ,
                b.BundleName AS ItemName ,
                b.BundleUrlName AS UrlName ,
                b.BannerImage AS ImageURL ,               
                ISNULL(s.cnt, 0) AS NumSubscribers ,
                0 AS Rating ,
                CAST(0 AS BIT) AS IsFreeCourse ,
                b.AddOn ,
                b.StatusId ,
                ISNULL(bc.cnt, 0) AS CoursesCnt ,
                b.AffiliateCommission ,
                CAST(b.BundleDescription AS NVARCHAR(MAX)) AS ItemDescription
      FROM      dbo.vw_CRS_BundleCoursesCnt AS bc
                RIGHT OUTER JOIN dbo.vw_CRS_BundleSubscriberCnt AS s
                RIGHT OUTER JOIN dbo.CRS_Bundles AS b ON s.BundleId = b.BundleId
                INNER JOIN dbo.Users AS u ON u.Id = b.AuthorId ON bc.BundleId = b.BundleId
      WHERE      (@Published = 0 AND ( CAST(b.AddOn AS DATE) = CAST(@EventDate AS DATE) ))
                 OR ( @Published = 1 AND CAST(b.PublishDate AS DATE) = CAST(@EventDate AS DATE))
    ) AS i
)

GO
/****** Object:  View [dbo].[vw_QZ_QuizValidationStatus]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_QZ_QuizValidationStatus]
AS
SELECT        qz.QuizId, CAST((CASE WHEN ISNULL(qq.QuestCnt, 0) > 0 THEN 1 ELSE 0 END) AS BIT) AS IsValid
FROM            dbo.QZ_CourseQuizzes AS qz LEFT OUTER JOIN
                             (SELECT        COUNT(q.QuestionId) AS QuestCnt, q.QuizId
                               FROM            dbo.QZ_QuizQuestionsLib AS q LEFT OUTER JOIN
                                                             (SELECT        COUNT(a.OptionId) AS cnt, COUNT(ca.OptionId) AS CorrectAnswer, a.QuestionId
                                                               FROM            dbo.QZ_QuestionAnswerOptions AS a LEFT OUTER JOIN
                                                                                             (SELECT        OptionId, QuestionId
                                                                                               FROM            dbo.QZ_QuestionAnswerOptions AS c
                                                                                               WHERE        (IsCorrect = 1)) AS ca ON ca.QuestionId = a.QuestionId AND ca.OptionId = a.OptionId
                                                               GROUP BY a.QuestionId) AS ans ON ans.QuestionId = q.QuestionId
                               WHERE        (ISNULL(ans.cnt, 0) > 1) AND (ISNULL(ans.CorrectAnswer, 0) = 1)
                               GROUP BY q.QuizId) AS qq ON qq.QuizId = qz.QuizId

GO
/****** Object:  View [dbo].[vw_QZ_CourseQuizzes]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_QZ_CourseQuizzes]
AS
SELECT        q.QuizId, q.Sid, q.CourseId, q.Title, q.Description, q.Instructions, q.PassPercent, q.RandomOrder, q.StatusId, q.AddOn, ISNULL(c.cnt, 0) AS TotalCompleted, 
                         ISNULL(t.cnt, 0) AS TotalTaken, ISNULL(qs.cnt, 0) AS TotalQustions, ISNULL(r.cnt, 0) AS OpenRequests, ISNULL(p.cnt, 0) AS TotalPass, ISNULL(f.cnt, 0) AS TotalFailed,
                          s.IsValid, q.ScoreRuleId, q.AvailableAfter, q.IsMandatory, q.IsBackAllowed, q.Attempts, q.TimeLimit, q.IsAttached, q.AttachCertificate, crs.AuthorUserId, u.Email, 
                         u.Nickname, u.FirstName, u.LastName, crs.CourseName
FROM            dbo.QZ_CourseQuizzes AS q INNER JOIN
                         dbo.Courses AS crs ON q.CourseId = crs.Id INNER JOIN
                         dbo.Users AS u ON crs.AuthorUserId = u.Id LEFT OUTER JOIN
                         dbo.vw_QZ_QuizValidationStatus AS s ON q.QuizId = s.QuizId LEFT OUTER JOIN
                             (SELECT        COUNT(qa.AttemptId) AS cnt, sq.QuizId
                               FROM            dbo.QZ_StudentQuizzes AS sq INNER JOIN
                                                         dbo.QZ_StudentQuizAttempts AS qa ON sq.StudentQuizId = qa.StudentQuizId INNER JOIN
                                                         dbo.QZ_StudentQuizStatusesLOV AS s ON qa.StatusId = s.StatusId
                               WHERE        (s.StatusCode = 'COMPLETED')
                               GROUP BY sq.QuizId) AS c ON q.QuizId = c.QuizId LEFT OUTER JOIN
                             (SELECT        COUNT(qa.AttemptId) AS cnt, sq.QuizId
                               FROM            dbo.QZ_StudentQuizzes AS sq INNER JOIN
                                                         dbo.QZ_StudentQuizAttempts AS qa ON sq.StudentQuizId = qa.StudentQuizId
                               GROUP BY sq.QuizId) AS t ON q.QuizId = t.QuizId LEFT OUTER JOIN
                             (SELECT        COUNT(QuestionId) AS cnt, QuizId
                               FROM            dbo.QZ_QuizQuestionsLib
                               GROUP BY QuizId) AS qs ON q.QuizId = qs.QuizId LEFT OUTER JOIN
                             (SELECT        COUNT(StudentQuizId) AS cnt, QuizId
                               FROM            dbo.QZ_StudentQuizzes AS sq
                               WHERE        (RequestSendOn IS NOT NULL) AND (ResponseSendOn IS NULL)
                               GROUP BY QuizId) AS r ON q.QuizId = r.QuizId LEFT OUTER JOIN
                             (SELECT        COUNT(StudentQuizId) AS cnt, QuizId
                               FROM            dbo.QZ_StudentQuizzes AS sq
                               WHERE        (IsSuccess = 1)
                               GROUP BY QuizId) AS p ON q.QuizId = p.QuizId LEFT OUTER JOIN
                             (SELECT        COUNT(StudentQuizId) AS cnt, QuizId
                               FROM            dbo.QZ_StudentQuizzes AS sq
                               WHERE        (IsSuccess = 0)
                               GROUP BY QuizId) AS f ON q.QuizId = f.QuizId

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetBundles]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-6-10
-- Description:	Get author course bundles
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetBundles] ( @AuthorID INT )
RETURNS TABLE
AS
RETURN
( 
		SELECT  c.BundleId ,
                c.uid AS Uid ,
                c.AuthorId AS AuthorUserId ,
                u.Nickname AS AuthorNickname ,
                u.FirstName AS AuthorFirstName ,
                u.LastName AS AuthorLastName ,
                c.BannerImage ,
                c.OverviewVideoIdentifier ,
                ISNULL(s.cnt, 0) AS LearnerCount ,
                c.BundleName ,
                c.BundleDescription ,
                c.Price ,
                c.MonthlySubscriptionPrice ,
                c.MetaTags ,
                c.FbObjectId ,
                c.FbObjectPublished ,
                c.StatusId,
				c.AddOn
      FROM      dbo.CRS_Bundles AS c
                INNER JOIN dbo.Users AS u ON c.AuthorId = u.Id
                LEFT OUTER JOIN dbo.vw_CRS_BundleSubscriberCnt AS s ON c.BundleId = s.BundleId
      WHERE     ( c.AuthorId = @AuthorID )
)

GO
/****** Object:  View [dbo].[vw_WS_StoresLib]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_WS_StoresLib]
AS
SELECT        ws.StoreID, ws.TrackingID, ws.StoreName, ws.OwnerUserID, dbo.fn_USER_IsAdmin(ws.OwnerUserID) AS IsOwnerAdmin, u.Email AS OwnerEmail, 
                         u.FirstName AS OwnerFirstName, u.LastName AS OwnerLastName, u.Nickname AS OwnerNickname, ISNULL(afi.items, 0) AS AffiliateItems, ISNULL(owi.items, 0) 
                         AS OwnedItems, ws.DefaultCurrencyId, ws.WixInstanceId, ws.RegistrationSourceId, rs.RegistrationTypeCode, ws.WixSiteUrl, ws.uid, ws.SiteUrl, ws.AddOn
FROM            dbo.WebStores AS ws INNER JOIN
                         dbo.Users AS u ON ws.OwnerUserID = u.Id LEFT OUTER JOIN
                             (SELECT        COUNT(ItemId) AS items, StoreID
                               FROM            dbo.vw_WS_Items AS wi
                               WHERE        (AuthorID = OwnerUserID)
                               GROUP BY StoreID) AS owi ON ws.StoreID = owi.StoreID LEFT OUTER JOIN
                         dbo.ADMIN_RegistrationSourcesLOV AS rs ON ws.RegistrationSourceId = rs.RegistrationTypeId LEFT OUTER JOIN
                             (SELECT        COUNT(ItemId) AS items, StoreID
                               FROM            dbo.vw_WS_Items AS wi
                               WHERE        (AuthorID <> OwnerUserID)
                               GROUP BY StoreID) AS afi ON afi.StoreID = ws.StoreID

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_QZ_GetCourseQuizzes]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2015-1-11
-- Description:	Get Course Quizzes
-- =============================================
CREATE FUNCTION [dbo].[tvf_QZ_GetCourseQuizzes] ( @CourseId INT )
RETURNS TABLE
AS
RETURN
( 
	SELECT    QuizId ,
                Sid ,
                Title ,
                Description ,
                Instructions ,
                PassPercent ,
                RandomOrder ,
                StatusId ,
                AddOn ,
                TotalCompleted ,
                TotalTaken ,
                TotalQustions ,
                IsValid ,
                ScoreRuleId ,
                CourseId ,
                AvailableAfter ,
                IsMandatory ,
                IsBackAllowed ,
                Attempts ,
                TimeLimit,
				AttachCertificate
      FROM      dbo.vw_QZ_CourseQuizzes
      WHERE     CourseId = @CourseId
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_QZ_GetUserCourseQuizzes]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2015-1-11
-- Description:	Get User Course Quizzes
-- =============================================
CREATE FUNCTION [dbo].[tvf_QZ_GetUserCourseQuizzes] 
(
	@UserId INT, 
	@CourseId INT 
)
RETURNS TABLE
AS
RETURN
( 
	 SELECT     cq.QuizId ,
                cq.Sid ,
                cq.Title ,
                cq.StatusId ,
                cq.PassPercent ,
                cq.CourseId ,
                cq.AvailableAfter ,
                cq.IsMandatory ,
                cq.Attempts ,
                cq.TimeLimit ,
                cq.AddOn ,
				cq.IsAttached,
          	CAST((CASE WHEN uq.cnt > 0
				THEN 1
				ELSE 0
				END) AS BIT) AS Passed,
				ISNULL(uq.Score,0) AS Score
      FROM      dbo.vw_QZ_CourseQuizzes AS cq
				LEFT OUTER JOIN (
					SELECT COUNT(StudentQuizId) AS cnt,
							MAX(s.Score	) AS score,
							QuizId
					FROM dbo.QZ_StudentQuizzes AS s
					WHERE s.USERId = @UserId
						  AND s.IsSuccess = 1
					GROUP BY s.QuizId
				) AS uq ON uq.QuizId = cq.QuizId
      WHERE     cq.CourseId = @CourseId
)

GO
/****** Object:  View [dbo].[vw_SALE_OrderTotalPayments]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_SALE_OrderTotalPayments]
AS
SELECT        o.OrderId, SUM(p.Amount) AS TotalAmount, s.StatusCode, p.Currency AS ISO
FROM            dbo.SALE_OrderLinePayments AS p INNER JOIN
                         dbo.SALE_PaymentStatusesLOV AS s ON p.StatusId = s.StatusId INNER JOIN
                         dbo.SALE_OrderLines AS o ON p.OrderLineId = o.LineId
GROUP BY o.OrderId, s.StatusCode, p.Currency
HAVING        (s.StatusCode = 'COMPLETED')

GO
/****** Object:  View [dbo].[vw_SALE_Orders]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_SALE_Orders]
AS
SELECT        oh.OrderId, oh.Sid, ISNULL(tp.TotalAmount, 0) AS TotalAmount, tp.ISO, oh.BuyerUserId, ub.Email AS BuyerEmail, ub.Nickname AS BuyerNickName, 
                         ub.FirstName AS BuyerFirstName, ub.LastName AS BuyerLastName, oh.SellerUserId, us.Email AS SellerEmail, us.Nickname AS SellerNickName, 
                         us.FirstName AS SellerFirstName, us.LastName AS SellerLastName, oh.WebStoreId, ws.TrackingID, ws.StoreName, oh.StatusId, st.StatusCode, oh.OrderDate, 
                         oh.AddressId, oh.PaymentMethodId, pm.PaymentMethodCode, oh.InstrumentId, pi.CreditCardType, pi.DisplayName, ws.OwnerUserID AS StoreOwnerUserId, 
                         us.AffiliateCommission
FROM            dbo.SALE_Orders AS oh INNER JOIN
                         dbo.Users AS ub ON oh.BuyerUserId = ub.Id INNER JOIN
                         dbo.Users AS us ON oh.SellerUserId = us.Id INNER JOIN
                         dbo.SALE_OrderStatusesLOV AS st ON oh.StatusId = st.StatusId INNER JOIN
                         dbo.BILL_PaymentMethodsLOV AS pm ON oh.PaymentMethodId = pm.MethodId LEFT OUTER JOIN
                         dbo.vw_SALE_OrderTotalPayments AS tp ON oh.OrderId = tp.OrderId LEFT OUTER JOIN
                         dbo.USER_PaymentInstruments AS pi ON oh.InstrumentId = pi.InstrumentId AND ub.Id = pi.UserId LEFT OUTER JOIN
                         dbo.WebStores AS ws ON oh.WebStoreId = ws.StoreID

GO
/****** Object:  View [dbo].[vw_SALE_OrderLinePaymentsTotalRefunds]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_SALE_OrderLinePaymentsTotalRefunds]
AS
SELECT        PaymentId, SUM(Amount) AS TotalRefunded
FROM            dbo.SALE_OrderLinePaymentRefunds AS r
GROUP BY PaymentId

GO
/****** Object:  View [dbo].[vw_SALE_OrderLinePayments]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_SALE_OrderLinePayments]
AS
SELECT        p.PaymentId, p.OrderLineId, p.Amount, p.Currency, p.PaymentDate, p.ScheduledDate, p.PaymentNumber, p.StatusId, s.StatusCode, ISNULL(r.TotalRefunded, 0) 
                         AS TotalRefunded, l.LineTypeId, t.TypeCode, trx.TransactionId, trx.ExternalTransactionID, l.PaypalProfileID, p.TypeId AS PaymentTypeId, 
                         pt.TypeCode AS PaymentTypeCode, l.OrderId, l.ItemName, so.Sid AS OrderNumber, so.BuyerUserId, so.BuyerEmail, so.BuyerNickName, so.BuyerFirstName, 
                         so.BuyerLastName, so.SellerUserId, so.SellerEmail, so.SellerNickName, so.SellerFirstName, so.SellerLastName, so.WebStoreId, so.TrackingID, so.StoreName, 
                         so.StatusId AS OrderStatusId, so.StatusCode AS OrderStatusCode, so.PaymentMethodId, so.InstrumentId, so.CreditCardType, so.DisplayName, l.CourseId, 
                         l.BundleId, so.PaymentMethodCode, l.CouponInstanceId, l.Price, l.TotalPrice, l.Discount, cp.SubscriptionMonths, cp.CouponTypeAmount, trx.Fee, so.OrderDate, 
                         l.PriceLineId, ISNULL(pl.CurrencyId, 2) AS CurrencyId, c.ISO, c.Symbol, c.CurrencyName, ISNULL(l.AffiliateCommission, so.AffiliateCommission) 
                         AS AffiliateCommission, l.IsUnderRGP, so.StoreOwnerUserId, sou.Email AS StoreOwnerEmail, sou.Nickname AS StoreOwnerNickname, 
                         sou.FirstName AS StoreOwnerFirstName, sou.LastName AS StoreOwnerLastName, cp.CouponTypeId
FROM            dbo.SALE_OrderLinePayments AS p INNER JOIN
                         dbo.SALE_PaymentStatusesLOV AS s ON p.StatusId = s.StatusId INNER JOIN
                         dbo.SALE_OrderLines AS l ON p.OrderLineId = l.LineId INNER JOIN
                         dbo.SALE_OrderLineTypesLOV AS t ON l.LineTypeId = t.TypeId INNER JOIN
                         dbo.SALE_PaymentTypesLOV AS pt ON p.TypeId = pt.TypeId INNER JOIN
                         dbo.vw_SALE_Orders AS so ON l.OrderId = so.OrderId LEFT OUTER JOIN
                         dbo.Users AS sou ON so.StoreOwnerUserId = sou.Id LEFT OUTER JOIN
                         dbo.Coupons AS cp INNER JOIN
                         dbo.CouponInstances AS ci ON cp.Id = ci.CouponId ON l.CouponInstanceId = ci.Id LEFT OUTER JOIN
                         dbo.BILL_ItemsPriceList AS pl INNER JOIN
                         dbo.BASE_CurrencyLib AS c ON pl.CurrencyId = c.CurrencyId ON l.PriceLineId = pl.PriceLineId LEFT OUTER JOIN
                         dbo.vw_SALE_OrderLinePaymentsTotalRefunds AS r ON p.PaymentId = r.PaymentId LEFT OUTER JOIN
                         dbo.SALE_Transactions AS trx ON p.PaymentId = trx.PaymentId AND l.LineId = trx.OrderLineId

GO
/****** Object:  View [dbo].[vw_SALE_OrderLinePaymentRefunds]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_SALE_OrderLinePaymentRefunds]
AS
SELECT        p.PaymentId, p.OrderLineId, p.Amount, p.Currency, p.PaymentDate, p.ScheduledDate, p.PaymentNumber, p.StatusId, s.StatusCode, l.LineTypeId, t.TypeCode, 
                         trx.TransactionId, trx.ExternalTransactionID, l.PaypalProfileID, p.TypeId AS PaymentTypeId, pt.TypeCode AS PaymentTypeCode, l.OrderId, l.ItemName, 
                         so.Sid AS OrderNumber, so.BuyerUserId, so.BuyerEmail, so.BuyerNickName, so.BuyerFirstName, so.BuyerLastName, so.SellerUserId, so.SellerEmail, 
                         so.SellerNickName, so.SellerFirstName, so.SellerLastName, so.WebStoreId, so.TrackingID, so.StoreName, so.StatusId AS OrderStatusId, 
                         so.StatusCode AS OrderStatusCode, so.PaymentMethodId, so.InstrumentId, so.CreditCardType, so.DisplayName, l.CourseId, l.BundleId, so.PaymentMethodCode, 
                         l.CouponInstanceId, l.Price, l.TotalPrice, l.Discount, cp.SubscriptionMonths, cp.CouponTypeAmount, r.RefundId, r.Amount AS RefundAmount, r.RefundDate, 
                         r.TypeId AS RefundTypeId, rt.TypeCode AS RefundTypeCode, ISNULL(pl.CurrencyId, 2) AS CurrencyId, c.CurrencyName, c.ISO, c.Symbol, l.IsUnderRGP, 
                         ISNULL(l.AffiliateCommission, so.AffiliateCommission) AS AffiliateCommission, trx.Fee, so.StoreOwnerUserId, so.OrderDate, sown.Email AS StoreOwnerEmail, 
                         sown.Nickname AS StoreOwnerNickname, sown.FirstName AS StoreOwnerFirstName, sown.LastName AS StoreOwnerLastName
FROM            dbo.SALE_OrderLinePaymentRefunds AS r INNER JOIN
                         dbo.SALE_OrderLinePayments AS p INNER JOIN
                         dbo.SALE_PaymentStatusesLOV AS s ON p.StatusId = s.StatusId INNER JOIN
                         dbo.SALE_OrderLines AS l ON p.OrderLineId = l.LineId INNER JOIN
                         dbo.SALE_OrderLineTypesLOV AS t ON l.LineTypeId = t.TypeId INNER JOIN
                         dbo.SALE_PaymentTypesLOV AS pt ON p.TypeId = pt.TypeId INNER JOIN
                         dbo.vw_SALE_Orders AS so ON l.OrderId = so.OrderId ON r.PaymentId = p.PaymentId INNER JOIN
                         dbo.SALE_PaymentTypesLOV AS rt ON r.TypeId = rt.TypeId INNER JOIN
                         dbo.SALE_Transactions AS trx ON r.RefundId = trx.RefundId AND l.LineId = trx.OrderLineId LEFT OUTER JOIN
                         dbo.Users AS sown ON so.StoreOwnerUserId = sown.Id LEFT OUTER JOIN
                         dbo.Coupons AS cp INNER JOIN
                         dbo.CouponInstances AS ci ON cp.Id = ci.CouponId ON l.CouponInstanceId = ci.Id LEFT OUTER JOIN
                         dbo.BASE_CurrencyLib AS c INNER JOIN
                         dbo.BILL_ItemsPriceList AS pl ON c.CurrencyId = pl.CurrencyId ON l.PriceLineId = pl.PriceLineId

GO
/****** Object:  View [dbo].[vw_SALE_OrderLineTotalPayments]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_SALE_OrderLineTotalPayments]
AS
SELECT        TOP (100) PERCENT o.LineId, SUM(p.Amount) AS TotalAmount, s.StatusCode, p.Currency AS ISO
FROM            dbo.SALE_OrderLinePayments AS p INNER JOIN
                         dbo.SALE_PaymentStatusesLOV AS s ON p.StatusId = s.StatusId INNER JOIN
                         dbo.SALE_OrderLines AS o ON p.OrderLineId = o.LineId
GROUP BY o.LineId, s.StatusCode, p.Currency
HAVING        (s.StatusCode = 'COMPLETED')

GO
/****** Object:  View [dbo].[vw_SALE_OrderLinesTotalRefunds]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_SALE_OrderLinesTotalRefunds]
AS
SELECT        SUM(r.Amount) AS TotalRefunded, l.LineId
FROM            dbo.SALE_OrderLines AS l INNER JOIN
                         dbo.SALE_OrderLinePayments ON l.LineId = dbo.SALE_OrderLinePayments.OrderLineId INNER JOIN
                         dbo.SALE_OrderLinePaymentRefunds AS r ON dbo.SALE_OrderLinePayments.PaymentId = r.PaymentId
GROUP BY l.LineId

GO
/****** Object:  View [dbo].[vw_SALE_OrderLines]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_SALE_OrderLines]
AS
SELECT        oh.OrderId, sol.LineId, oh.Sid AS OrderNumber, sol.SellerUserId, su.Email AS SellerEmail, su.Nickname AS SellerNickName, su.FirstName AS SellerFirstName, 
                         su.LastName AS SellerLastName, oh.BuyerUserId, usrbuy.Email AS BuyerEmail, usrbuy.Nickname AS BuyerNickName, usrbuy.FirstName AS BuyerFirstName, 
                         usrbuy.LastName AS BuyerLastName, oh.WebStoreId, ws.TrackingID, ws.StoreName, os.StatusCode AS OrderStatusCode, oh.StatusId AS OrderStatusId, 
                         oh.PaymentMethodId, pm.PaymentMethodCode, oh.OrderDate, sol.LineTypeId, lt.TypeCode AS LineTypeCode, sol.PaymentTermId, pt.PaymentTermCode, 
                         sol.ItemName, sol.Price, sol.Discount, sol.TotalPrice, ISNULL(p.TotalAmount, 0) AS TotalAmountPayed, sol.PaypalProfileID, sol.Description, 
                         ws.OwnerUserID AS StoreOwnerUserId, usown.Email AS StoreOwnerEmail, usown.Nickname AS StoreOwnerNickname, usown.FirstName AS StoreOwnerFirstName, 
                         usown.LastName AS StoreOwnerLastName, sol.CourseId, sol.BundleId, ISNULL(r.TotalRefunded, 0) AS TotalRefunded, sol.CouponInstanceId, ci.CouponCode, 
                         c.CouponTypeAmount, ct.CouponTypeId, oh.AddressId, oh.InstrumentId, pi.CreditCardType, pi.DisplayName, sol.PriceLineId, pl.CurrencyId, cur.ISO, cur.Symbol, 
                         cur.CurrencyName, su.FacebookID AS SellerFacebookID, usrbuy.FacebookID AS BuyerFacebookID, sol.IsUnderRGP, sol.AffiliateCommission, oh.CancelledOn
FROM            dbo.Users AS usown INNER JOIN
                         dbo.WebStores AS ws ON usown.Id = ws.OwnerUserID RIGHT OUTER JOIN
                         dbo.SALE_Orders AS oh INNER JOIN
                         dbo.SALE_OrderLines AS sol ON oh.OrderId = sol.OrderId INNER JOIN
                         dbo.SALE_OrderLineTypesLOV AS lt ON sol.LineTypeId = lt.TypeId INNER JOIN
                         dbo.SALE_OrderStatusesLOV AS os ON oh.StatusId = os.StatusId INNER JOIN
                         dbo.Users AS su ON sol.SellerUserId = su.Id INNER JOIN
                         dbo.BILL_PaymentTermsLOV AS pt ON sol.PaymentTermId = pt.PaymentTermId INNER JOIN
                         dbo.Users AS usrbuy ON oh.BuyerUserId = usrbuy.Id INNER JOIN
                         dbo.BILL_PaymentMethodsLOV AS pm ON oh.PaymentMethodId = pm.MethodId LEFT OUTER JOIN
                         dbo.Coupons AS c INNER JOIN
                         dbo.CouponInstances AS ci ON c.Id = ci.CouponId INNER JOIN
                         dbo.CRS_CouponTypesLOV AS ct ON c.CouponTypeId = ct.CouponTypeId ON sol.CouponInstanceId = ci.Id LEFT OUTER JOIN
                         dbo.USER_PaymentInstruments AS pi ON oh.InstrumentId = pi.InstrumentId ON ws.StoreID = oh.WebStoreId LEFT OUTER JOIN
                         dbo.BILL_ItemsPriceList AS pl INNER JOIN
                         dbo.BASE_CurrencyLib AS cur ON pl.CurrencyId = cur.CurrencyId ON sol.PriceLineId = pl.PriceLineId LEFT OUTER JOIN
                         dbo.vw_SALE_OrderLineTotalPayments AS p ON sol.LineId = p.LineId LEFT OUTER JOIN
                         dbo.vw_SALE_OrderLinesTotalRefunds AS r ON sol.LineId = r.LineId

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_SALE_SearchOrders]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-2-07
-- Description:	Search sales orders
-- =============================================
CREATE FUNCTION [dbo].[tvf_SALE_SearchOrders]
(	
	 @from DATETIME 
	,@to DATETIME
	,@SellerUserId INT		= NULL
	,@BuyerUserId INT		= NULL
	,@CourseId INT			= NULL
	,@BundleId INT			= NULL
	,@StoreId INT			= NULL
	,@SubscriptionsOnly BIT = 0
	,@StatusId TINYINT		= NULL
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT  oh.OrderId ,
			oh.Sid ,
			oh.TotalAmount ,
			oh.ISO,
			oh.BuyerUserId ,
			oh.BuyerEmail ,
			oh.BuyerNickName ,
			oh.BuyerFirstName ,
			oh.BuyerLastName ,
			oh.SellerUserId ,
			oh.SellerEmail ,
			oh.SellerNickName ,
			oh.SellerFirstName ,
			oh.SellerLastName ,
			oh.WebStoreId ,
			oh.TrackingID ,
			oh.StoreName ,
			oh.StatusId ,
			oh.StatusCode ,
			oh.OrderDate ,
			oh.AddressId ,
			oh.PaymentMethodId ,
			oh.PaymentMethodCode ,
			oh.InstrumentId ,
			oh.CreditCardType ,
			oh.DisplayName,
			oh.StoreOwnerUserId,
			oh.AffiliateCommission
	FROM    dbo.vw_SALE_Orders AS oh
			INNER JOIN dbo.vw_SALE_OrderLines AS ol ON oh.OrderId = ol.OrderId
	WHERE  (oh.OrderDate BETWEEN @from  AND @to)
			AND (@SellerUserId IS NULL OR oh.SellerUserId = @SellerUserId)
			AND (@BuyerUserId IS NULL OR oh.BuyerUserId = @BuyerUserId)
			AND (@CourseId IS NULL OR (ol.CourseId IS NOT NULL AND ol.CourseId = @CourseId))
			AND (@BundleId IS NULL OR (ol.BundleId IS NOT NULL AND ol.BundleId = @BundleId))
			AND (@StoreId IS NULL OR (oh.WebStoreId IS NOT NULL AND oh.WebStoreId = @StoreId))
			AND (@SubscriptionsOnly = 0 OR (ol.PaymentTermCode <> 'IMMEDIATE'))
			AND (@StatusId IS NULL OR oh.StatusId= @StatusId)
	GROUP BY oh.OrderId ,
			oh.Sid ,
			oh.TotalAmount ,
			oh.ISO,
			oh.BuyerUserId ,
			oh.BuyerEmail ,
			oh.BuyerNickName ,
			oh.BuyerFirstName ,
			oh.BuyerLastName ,
			oh.SellerUserId ,
			oh.SellerEmail ,
			oh.SellerNickName ,
			oh.SellerFirstName ,
			oh.SellerLastName ,
			oh.WebStoreId ,
			oh.TrackingID ,
			oh.StoreName ,
			oh.StatusId ,
			oh.StatusCode ,
			oh.OrderDate ,
			oh.AddressId ,
			oh.PaymentMethodId ,
			oh.PaymentMethodCode ,
			oh.InstrumentId ,
			oh.CreditCardType ,
			oh.DisplayName,
			oh.StoreOwnerUserId,
			oh.AffiliateCommission
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DB_GetUserSalesDetails]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-11-10
-- Description:	Get Author sales details for dashboard
-- =============================================
CREATE FUNCTION [dbo].[tvf_DB_GetUserSalesDetails]
    (
      @From DATE ,
      @To DATE ,
      @UserId INT ,
      @CurrencyId SMALLINT ,
      @StoreId INT = NULL ,
      @PaymentSource VARCHAR(10) = NULL ,
      @LineTypeId TINYINT = NULL
    )
RETURNS TABLE
AS
RETURN
    ( 
		SELECT    PaymentSource ,
                PaymentId ,
                OrderLineId ,
                Amount ,
                Currency ,
                PaymentDate ,
                PaymentNumber ,
                TotalRefunded ,
                LineTypeId ,
                TransactionId ,
                ExternalTransactionID ,
                PaypalProfileID ,
                PaymentTypeId ,
                ItemName ,
                OrderNumber ,
                BuyerUserId ,
                BuyerEmail ,
                BuyerNickName ,
                BuyerFirstName ,
                BuyerLastName ,
                SellerUserId ,
                SellerEmail ,
                SellerNickName ,
                SellerFirstName ,
                SellerLastName ,
                WebStoreId ,
                TrackingID ,
                StoreName ,
                StoreOwnerUserId ,
                StoreOwnerEmail ,
                StoreOwnerNickname ,
                StoreOwnerFirstName ,
                StoreOwnerLastName ,
                OrderStatusId ,
                OrderStatusCode ,
                CourseId ,
                BundleId ,
                CouponInstanceId ,
                CouponTypeId ,
                Price ,
                TotalPrice ,
                Discount ,
                TotalAmount AS TotalAmountPayed ,
                SubscriptionMonths ,
                CouponTypeAmount ,
                Fee ,
                OrderDate ,
                CurrencyId ,
                ISO ,
                Symbol ,
                CurrencyName ,
                AffiliateCommission ,
                IsUnderRGP
      FROM      (
		-- Author Sales
                  SELECT    'AS' AS PaymentSource ,
                            p.PaymentId ,
                            p.OrderLineId ,
                            p.Amount ,
                            p.Currency ,
                            p.PaymentDate ,
                            p.PaymentNumber ,
                            p.TotalRefunded ,
                            p.LineTypeId ,
                            p.TypeCode AS LineTypeCode ,
                            p.TransactionId ,
                            p.ExternalTransactionID ,
                            p.PaypalProfileID ,
                            p.PaymentTypeId ,
                            p.ItemName ,
                            p.OrderNumber ,
                            p.BuyerUserId ,
                            p.BuyerEmail ,
                            p.BuyerNickName ,
                            p.BuyerFirstName ,
                            p.BuyerLastName ,
                            p.SellerUserId ,
                            p.SellerEmail ,
                            p.SellerNickName ,
                            p.SellerFirstName ,
                            p.SellerLastName ,
                            p.WebStoreId ,
                            p.TrackingID ,
                            p.StoreName ,
                            p.StoreOwnerUserId ,
                            p.StoreOwnerEmail ,
                            p.StoreOwnerNickname ,
                            p.StoreOwnerFirstName ,
                            p.StoreOwnerLastName ,
                            p.OrderStatusId ,
                            p.OrderStatusCode ,
                            p.CourseId ,
                            p.BundleId ,
                            p.CouponInstanceId ,
                            p.CouponTypeId ,
                            p.Price ,
                            p.TotalPrice ,
                            p.Discount ,
                            p.SubscriptionMonths ,
                            p.CouponTypeAmount ,
                            p.Fee ,
                            p.OrderDate ,
                            p.CurrencyId ,
                            p.ISO ,
                            p.Symbol ,
                            p.CurrencyName ,
                            p.AffiliateCommission ,
                            p.IsUnderRGP ,
                            t.TotalAmount
                  FROM      dbo.vw_SALE_OrderLinePayments AS p
                            LEFT OUTER JOIN dbo.vw_SALE_OrderLineTotalPayments
                            AS t ON p.OrderLineId = t.LineId
                  WHERE     ( p.StatusCode = 'COMPLETED' )
                            AND ( StoreOwnerUserId IS NULL
                                  OR StoreOwnerUserId = SellerUserId
                                )
                            AND ( CAST(PaymentDate AS DATE) BETWEEN CAST(@From AS DATE)
                                                            AND
                                                              CAST(@To AS DATE) )
                            AND ( SellerUserId = @UserId )
                            AND ( CurrencyId = @CurrencyId )
                            AND ( @StoreId IS NULL
                                  OR WebStoreId = @StoreId
                                )
                  UNION
		-- Sales By Affiliate
                  SELECT    'BAFS' AS PaymentSource ,
                            p.PaymentId ,
                            p.OrderLineId ,
                            p.Amount ,
                            p.Currency ,
                            p.PaymentDate ,
                            p.PaymentNumber ,
                            p.TotalRefunded ,
                            p.LineTypeId ,
                            p.TypeCode AS LineTypeCode ,
                            p.TransactionId ,
                            p.ExternalTransactionID ,
                            p.PaypalProfileID ,
                            p.PaymentTypeId ,
                            p.ItemName ,
                            p.OrderNumber ,
                            p.BuyerUserId ,
                            p.BuyerEmail ,
                            p.BuyerNickName ,
                            p.BuyerFirstName ,
                            p.BuyerLastName ,
                            p.SellerUserId ,
                            p.SellerEmail ,
                            p.SellerNickName ,
                            p.SellerFirstName ,
                            p.SellerLastName ,
                            p.WebStoreId ,
                            p.TrackingID ,
                            p.StoreName ,
                            p.StoreOwnerUserId ,
                            p.StoreOwnerEmail ,
                            p.StoreOwnerNickname ,
                            p.StoreOwnerFirstName ,
                            p.StoreOwnerLastName ,
                            p.OrderStatusId ,
                            p.OrderStatusCode ,
                            p.CourseId ,
                            p.BundleId ,
                            p.CouponInstanceId ,
                            p.CouponTypeId ,
                            p.Price ,
                            p.TotalPrice ,
                            p.Discount ,
                            p.SubscriptionMonths ,
                            p.CouponTypeAmount ,
                            p.Fee ,
                            p.OrderDate ,
                            p.CurrencyId ,
                            p.ISO ,
                            p.Symbol ,
                            p.CurrencyName ,
                            p.AffiliateCommission ,
                            p.IsUnderRGP ,
                            t.TotalAmount
                  FROM      dbo.vw_SALE_OrderLinePayments AS p
                            LEFT OUTER JOIN dbo.vw_SALE_OrderLineTotalPayments
                            AS t ON p.OrderLineId = t.LineId
                  WHERE     ( p.StatusCode = 'COMPLETED' )
                            AND ( WebStoreId IS NOT NULL )
                            AND ( StoreOwnerUserId <> SellerUserId )
                            AND ( SellerUserId = @UserId )
                            AND ( CAST(PaymentDate AS DATE) BETWEEN CAST(@From AS DATE)
                                                            AND
                                                              CAST(@To AS DATE) )
                            AND ( CurrencyId = @CurrencyId )
                            AND ( @StoreId IS NULL
                                  OR WebStoreId = @StoreId
                                )
                  UNION
			--Affiliate sales
                  SELECT    'AFS' AS PaymentSource ,
                            p.PaymentId ,
                            p.OrderLineId ,
                            p.Amount ,
                            p.Currency ,
                            p.PaymentDate ,
                            p.PaymentNumber ,
                            p.TotalRefunded ,
                            p.LineTypeId ,
                            p.TypeCode AS LineTypeCode ,
                            p.TransactionId ,
                            p.ExternalTransactionID ,
                            p.PaypalProfileID ,
                            p.PaymentTypeId ,
                            p.ItemName ,
                            p.OrderNumber ,
                            p.BuyerUserId ,
                            p.BuyerEmail ,
                            p.BuyerNickName ,
                            p.BuyerFirstName ,
                            p.BuyerLastName ,
                            p.SellerUserId ,
                            p.SellerEmail ,
                            p.SellerNickName ,
                            p.SellerFirstName ,
                            p.SellerLastName ,
                            p.WebStoreId ,
                            p.TrackingID ,
                            p.StoreName ,
                            p.StoreOwnerUserId ,
                            p.StoreOwnerEmail ,
                            p.StoreOwnerNickname ,
                            p.StoreOwnerFirstName ,
                            p.StoreOwnerLastName ,
                            p.OrderStatusId ,
                            p.OrderStatusCode ,
                            p.CourseId ,
                            p.BundleId ,
                            p.CouponInstanceId ,
                            p.CouponTypeId ,
                            p.Price ,
                            p.TotalPrice ,
                            p.Discount ,
                            p.SubscriptionMonths ,
                            p.CouponTypeAmount ,
                            p.Fee ,
                            p.OrderDate ,
                            p.CurrencyId ,
                            p.ISO ,
                            p.Symbol ,
                            p.CurrencyName ,
                            p.AffiliateCommission ,
                            p.IsUnderRGP ,
                            t.TotalAmount
                  FROM      dbo.vw_SALE_OrderLinePayments AS p
                            LEFT OUTER JOIN dbo.vw_SALE_OrderLineTotalPayments
                            AS t ON p.OrderLineId = t.LineId
                  WHERE     ( p.StatusCode = 'COMPLETED' )
                            AND ( WebStoreId IS NOT NULL )
                            AND ( StoreOwnerUserId <> SellerUserId )
                            AND ( StoreOwnerUserId = @UserId )
                            AND ( CAST(PaymentDate AS DATE) BETWEEN CAST(@From AS DATE)
                                                            AND
                                                              CAST(@To AS DATE) )
                            AND ( CurrencyId = @CurrencyId )
                            AND ( @StoreId IS NULL
                                  OR WebStoreId = @StoreId
                                )
                ) AS t
      WHERE     ( @PaymentSource IS NULL
                  OR PaymentSource = @PaymentSource
                )
                AND ( @LineTypeId IS NULL
                      OR LineTypeId = @LineTypeId
                    )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetMonthlyStatementSales]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-5-5
-- Description:	Get user monthly statment sales
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetMonthlyStatementSales]
(		
	@Year INT, 
	@Month INT ,
	@UserId INT,
	@CurrencyId SMALLINT = 2 -- USD     
)
RETURNS TABLE 
AS
RETURN 
(
	   SELECT  ISNULL(sp.total, 0) AS total ,
                CAST(ISNULL(sp.fee, 0) AS MONEY) AS fee,
				PaymentSource,
				sp.SellerUserId
        FROM    ( SELECT    SUM(Amount) AS total ,
                            SUM(Fee) AS fee ,
                            PaymentSource,
							s.SellerUserId
                  FROM      (
								SELECT      SellerUserId ,
											Amount ,
											PaymentDate ,
											Fee ,
											TypeCode AS PaymentSource ,
											CurrencyId 
								FROM    dbo.vw_SALE_OrderLinePayments
								WHERE   ( StatusCode = 'COMPLETED' )
										AND ( DATEPART(year, PaymentDate) = @Year )
										AND ( DATEPART(month, PaymentDate) = @Month )
										AND (SellerUserId = @UserId )
										AND (CurrencyId = @CurrencyId) 
										AND (WebStoreId IS NULL OR StoreOwnerUserId = @UserId)
                            ) AS s
                  GROUP BY  SellerUserId ,
                            PaymentSource
                ) AS sp
               
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_DASH_GetPeriodSalesTotals]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-18
-- Description:	Get totals for admin dashboard
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_DASH_GetPeriodSalesTotals]
(	
	@CurrencyId SMALLINT,
	@From DATE, 
	@To DATE
)
RETURNS TABLE 
AS
RETURN 
(

	SELECT   	SUM(Amount) AS total_sales ,
					COUNT(PaymentId) AS total_payment_qty ,
					SUM(CASE WHEN TypeCode = 'SALE'
								THEN Amount
								ELSE 0
						END) AS total_onetime_sales ,
					COUNT(DISTINCT ((CASE WHEN TypeCode = 'SALE'
								THEN OrderId
						END) )) AS total_onetime_qty,
					SUM(CASE WHEN TypeCode = 'SUBSCRIPTION'
								THEN Amount
								ELSE 0
						END) AS total_subscription_sales ,
					COUNT(DISTINCT ((CASE WHEN TypeCode = 'SUBSCRIPTION'
								THEN OrderId
						END) )) AS total_subscription_qty,
					SUM(CASE WHEN TypeCode = 'RENTAL'
								THEN Amount
								ELSE 0
						END) AS total_rental_sales ,
					COUNT(DISTINCT ((CASE WHEN TypeCode = 'RENTAL'
								THEN OrderId
						END) )) AS total_rental_qty,
					CurrencyId
					FROM      dbo.vw_SALE_OrderLinePayments
					WHERE   ( StatusCode = 'COMPLETED' )
							AND ( CAST(PaymentDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) )
							AND (CurrencyId = @CurrencyId)
					GROUP BY  CurrencyId
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DB_GetAuthorSalesStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-11-03
-- Description:	Get Author sales statisitic for dashboard
-- =============================================
CREATE FUNCTION [dbo].[tvf_DB_GetAuthorSalesStats]
(	
	@From DATE ,
    @To DATE ,
    @UserId INT ,   
    @CurrencyId SMALLINT,
	@StoreId INT = NULL 
)
RETURNS TABLE 
AS
RETURN 
(
		SELECT  UserId ,
				cur.CurrencyId ,
				cur.CurrencyCode, 
				cur.ISO, 
				cur.Symbol,

				--One time
				AuthorTotalOnetimeSales ,
				AuthorTotalOnetimeQty ,
		
				--Subscriptions
				AuthorTotalSubscriptionSales ,
				AuthorTotalSubscriptionQty ,
		
				--Rental
				AuthorTotalRentalSales ,
				AuthorTotalRentalQty ,
        
				--Affiliate
				ByAffiliateTotalSales,
				AffiliateTotalSales,
				ByAffiliateTotalQty,
				AffiliateTotalQty ,

				--Refund
				ISNULL(TotalRefund,0) AS TotalRefund,
				ISNULL(TotalRefundQty,0) AS TotalRefundQty,

				--Cancel
				ISNULL(TotalCancelled,0) AS TotalCancelled ,
				ISNULL(TotalCancelledQty,0) AS TotalCancelledQty,

				-- Coupon
				ISNULL(TotalCouponValue,0) AS TotalCouponValue,
				ISNULL(TotalCouponQty,0) AS TotalCouponQty


		FROM(
			SELECT  u.UserId ,
					u.CurrencyId ,
			
					-- Author sales statistic
					--ISNULL(auth_sales.total_sales, 0) AS AuthorTotalSales ,
					ISNULL(auth_sales.total_onetime_sales, 0) AS AuthorTotalOnetimeSales ,
					ISNULL(auth_sales.total_onetime_qty, 0) AS AuthorTotalOnetimeQty ,
					ISNULL(auth_sales.total_subscription_sales, 0) AS AuthorTotalSubscriptionSales ,
					ISNULL(auth_sales.total_subscription_qty, 0) AS AuthorTotalSubscriptionQty ,
					ISNULL(auth_sales.total_rental_sales, 0) AS AuthorTotalRentalSales ,
					ISNULL(auth_sales.total_rental_qty, 0) AS AuthorTotalRentalQty ,
					--ISNULL(auth_sales.total_fees, 0) AS AuthorTotalFees,

					-- Sales by Affiliate statistics
					ISNULL(by_aff.total_net_sales,0) AS ByAffiliateTotalSales,
					ISNULL(by_aff.total_qty,0) AS ByAffiliateTotalQty,
					--ISNULL(by_aff.total_net_fees,0) AS ByAffiliateTotalFees,

					-- Affiliate sales statistics
					ISNULL(aff_sales.total_commission,0) AS AffiliateTotalSales,
					ISNULL(aff_sales.total_qty,0) AS AffiliateTotalQty,
					--ISNULL(aff_sales.total_net_fees,0) AS AffiliateTotalFees,

					-- Refunds
					(ISNULL(auth_refund.total_refunded,0) + ISNULL(by_aff_refund.total_net_refunded,0) + ISNULL(aff_refund.total_net_refunded,0)) AS TotalRefund,
					(ISNULL(auth_refund.total_qty,0) + ISNULL(by_aff_refund.total_qty,0) + ISNULL(aff_refund.total_qty,0)) AS TotalRefundQty,

					-- Subscription Cancellations
					(ISNULL(auth_cancel.total_cancelled,0) + ISNULL(by_aff_cancel.total_cancelled,0) + ISNULL(aff_cancel.total_cancelled,0)) AS TotalCancelled,
					(ISNULL(auth_cancel.total_cancelled_qty,0) + ISNULL(by_aff_cancel.total_cancelled_qty,0) + ISNULL(aff_cancel.total_cancelled_qty,0)) AS TotalCancelledQty,

					-- Coupons
					(ISNULL(auth_coupon.DiscountValue,0) + ISNULL(by_aff_coupon.DiscountValue,0) + ISNULL(aff_coupon.DiscountValue,0)) AS TotalCouponValue,
					(ISNULL(auth_coupon.total_qty,0) + ISNULL(by_aff_coupon.total_qty,0) + ISNULL(aff_coupon.total_qty,0)) AS TotalCouponQty
			FROM    (
						-- Base user
						  SELECT    u.Id AS UserId ,
									ISNULL(c.CurrencyId, 2) AS CurrencyId
						  FROM      ( SELECT    SellerUserId AS UserId ,
												CurrencyId
									  FROM      dbo.vw_SALE_OrderLinePayments AS s
									  WHERE     ( StatusCode = 'COMPLETED' )
												AND ( CAST(PaymentDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) )
												AND ( SellerUserId = @UserId )
												AND (@StoreId IS NULL OR WebStoreId = @StoreId)
												AND (CurrencyId = @CurrencyId)
									  GROUP BY  SellerUserId ,
												CurrencyId
									  UNION
									  SELECT    StoreOwnerUserId AS UserId ,
												CurrencyId
									  FROM      dbo.vw_SALE_OrderLinePayments AS s
									  WHERE     ( StatusCode = 'COMPLETED' )
												AND ( WebStoreId IS NOT NULL ) AND ( StoreOwnerUserId <> SellerUserId )
												AND (@StoreId IS NULL OR WebStoreId = @StoreId)
												AND ( CAST(PaymentDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) )
												AND ( StoreOwnerUserId = @UserId )
												AND (CurrencyId = @CurrencyId)
									  GROUP BY  StoreOwnerUserId ,
												CurrencyId
									) AS up
									INNER JOIN dbo.BASE_CurrencyLib AS c ON up.CurrencyId = c.CurrencyId
									RIGHT OUTER JOIN dbo.Users AS u ON ISNULL(up.UserId, u.Id) = u.Id
						  WHERE     ( u.Id = @UserId )
						) AS u

		-- SALES ---------------------------------------------------------------------------------------------------
						LEFT OUTER JOIN (
						--Author sales
								  SELECT    SellerUserId AS UserId ,
											SUM(Amount) AS total_sales ,
											COUNT(PaymentId) AS total_qty ,
											SUM(CASE WHEN TypeCode = 'SALE'
													 THEN Amount
													 ELSE 0
												END) AS total_onetime_sales ,
											COUNT(DISTINCT ((CASE WHEN TypeCode = 'SALE'
													 THEN OrderId
												END) )) AS total_onetime_qty,
											--SUM(CASE WHEN TypeCode = 'SALE' THEN 1
											--		 ELSE 0
											--	END) AS total_onetime_qty ,											
											SUM(CASE WHEN TypeCode = 'SUBSCRIPTION'
													 THEN Amount
													 ELSE 0
												END) AS total_subscription_sales ,
											COUNT(DISTINCT ((CASE WHEN TypeCode = 'SUBSCRIPTION'
													 THEN OrderId
												END) )) AS total_subscription_qty,
											--SUM(CASE WHEN TypeCode = 'SUBSCRIPTION'
											--		 THEN 1
											--		 ELSE 0
											--	END) AS total_subscription_qty ,											
											SUM(CASE WHEN TypeCode = 'RENTAL'
													 THEN Amount
													 ELSE 0
												END) AS total_rental_sales ,
											COUNT(DISTINCT ((CASE WHEN TypeCode = 'RENTAL'
													 THEN OrderId
												END) )) AS total_rental_qty,
											--SUM(CASE WHEN TypeCode = 'RENTAL' THEN 1
											--		 ELSE 0
											--	END) AS total_rental_qty ,
											SUM(Fee) AS total_fees ,
											CurrencyId
								  FROM      dbo.vw_SALE_OrderLinePayments
								  WHERE     ( StatusCode = 'COMPLETED' )
											AND ( StoreOwnerUserId IS NULL
												  OR StoreOwnerUserId = SellerUserId
												)
											AND ( CAST(PaymentDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) )
											AND ( SellerUserId = @UserId )
											AND (CurrencyId = @CurrencyId)
											AND (@StoreId IS NULL OR WebStoreId = @StoreId)
								  GROUP BY  SellerUserId ,
											CurrencyId
								) AS auth_sales ON auth_sales.UserId = u.UserId
												   AND auth_sales.CurrencyId = u.CurrencyId		

						 LEFT OUTER JOIN (
							-- Sales By Affiliate
									SELECT  SellerUserId AS UserId ,
											SUM(Amount) AS total_sales ,
											--COUNT(PaymentId) AS total_qty ,
											COUNT(DISTINCT (OrderId)) AS total_qty,
											SUM(s.Amount * ( 1 - s.AffiliateCommission / 100 )) AS total_net_sales ,
											SUM(Fee) AS total_fees ,        
											SUM(Fee * ( 1 - AffiliateCommission / 100 )) AS total_net_fees ,
											CurrencyId
									FROM    dbo.vw_SALE_OrderLinePayments AS s
									WHERE   ( StatusCode = 'COMPLETED' )
											AND ( WebStoreId IS NOT NULL )
											AND ( StoreOwnerUserId <> SellerUserId )
											AND (SellerUserId = @UserId)
											AND ( CAST(PaymentDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) )
											AND (CurrencyId = @CurrencyId)	
											AND (@StoreId IS NULL OR WebStoreId = @StoreId)								
									GROUP BY SellerUserId ,
											CurrencyId 	
						 ) AS by_aff ON by_aff.UserId = u.UserId
										AND by_aff.CurrencyId = u.CurrencyId	

						 LEFT OUTER JOIN (
								--Affiliate sales
								SELECT  StoreOwnerUserId AS UserId ,
										SUM(Amount) AS total_sales ,
										--COUNT(PaymentId) AS total_qty ,
										COUNT(DISTINCT (OrderId)) AS total_qty,
										SUM(Amount * ( AffiliateCommission / 100 )) AS total_commission ,
										SUM(Fee) AS total_fees ,
										SUM(Fee * ( AffiliateCommission / 100 )) AS total_net_fees ,
										CurrencyId
								FROM    dbo.vw_SALE_OrderLinePayments
								WHERE   ( StatusCode = 'COMPLETED' )
										AND (WebStoreId IS NOT NULL )
										AND (StoreOwnerUserId <> SellerUserId )
										AND (StoreOwnerUserId = @UserId)
										AND ( CAST(PaymentDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) )		
										AND (CurrencyId = @CurrencyId)	
										AND (@StoreId IS NULL OR WebStoreId = @StoreId)					
								GROUP BY StoreOwnerUserId ,
										 CurrencyId
						 ) AS aff_sales ON aff_sales.UserId = u.UserId
										AND aff_sales.CurrencyId = u.CurrencyId	

		-- REFUNDS -----------------------------------------------------------------------------------------
						LEFT OUTER JOIN (
							-- Author Refunds
							SELECT  SellerUserId AS UserId ,
									SUM(ABS(Amount)) AS total_refunded ,
									COUNT(RefundId) AS total_qty ,
									SUM(ABS(Fee)) AS fee_refunded ,
									CurrencyId
							FROM    dbo.vw_SALE_OrderLinePaymentRefunds AS r
							WHERE   (( StoreOwnerUserId IS NULL ) OR ( StoreOwnerUserId = SellerUserId ))
									AND ( CAST(RefundDate  AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
									AND (SellerUserId = @UserId)
									AND (CurrencyId = @CurrencyId)
									AND (@StoreId IS NULL OR WebStoreId = @StoreId)
							GROUP BY SellerUserId ,
									CurrencyId
						) AS auth_refund ON auth_refund.UserId = u.UserId
												   AND auth_refund.CurrencyId = u.CurrencyId		


						LEFT OUTER JOIN (
								-- By Affiliate refunds
								SELECT  SellerUserId AS UserId ,
										SUM(ABS(Amount)) AS total_refunded ,
										COUNT(RefundId) AS total_qty ,
										SUM(ABS(Amount * ( 1 - AffiliateCommission / 100 ))) AS total_net_refunded ,
										SUM(ABS(Fee)) AS fee_refunded ,
										SUM(ABS(Fee * ( 1 - AffiliateCommission / 100 ))) AS fee_net_refunded,
										CurrencyId
								FROM    dbo.vw_SALE_OrderLinePaymentRefunds AS r
								WHERE   (( WebStoreId IS NOT NULL ) AND ( StoreOwnerUserId <> SellerUserId ))
										AND ( CAST(RefundDate  AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
										AND (SellerUserId = @UserId)
										AND (CurrencyId = @CurrencyId)
										AND (@StoreId IS NULL OR WebStoreId = @StoreId)
								GROUP BY SellerUserId ,      
										CurrencyId
						) AS by_aff_refund ON by_aff_refund.UserId = u.UserId
												   AND by_aff_refund.CurrencyId = u.CurrencyId

						LEFT OUTER JOIN (
							-- Affiliate Refunds
							SELECT  StoreOwnerUserId AS UserId ,
									SUM(ABS(Amount)) AS total_refunded ,
									COUNT(RefundId) AS total_qty ,
									SUM(ABS(Amount * ( AffiliateCommission / 100 ))) AS total_net_refunded ,
									SUM(ABS(Fee)) AS fee_refunded ,
									SUM(ABS(Fee * ( AffiliateCommission / 100 ))) AS fee_net_refunded ,      
									CurrencyId
							FROM    dbo.vw_SALE_OrderLinePaymentRefunds AS r
							WHERE   (( WebStoreId IS NOT NULL ) AND ( StoreOwnerUserId <> SellerUserId ))
									AND ( CAST(RefundDate  AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
									AND (StoreOwnerUserId = @UserId)
									AND (CurrencyId = @CurrencyId)
									AND (@StoreId IS NULL OR WebStoreId = @StoreId)
							GROUP BY CurrencyId ,
									StoreOwnerUserId
						) AS aff_refund ON aff_refund.UserId = u.UserId
										AND aff_refund.CurrencyId = u.CurrencyId

		-- SUBSCRIPTION CANCELLATIONS ------------------------------------------------------------------------------------------------------

						LEFT OUTER JOIN (
						-- Author subscription cancellations
											SELECT  ISNULL(SUM(ac.TotalPrice), 0) AS total_cancelled ,
													COUNT(ac.OrderNum) AS total_cancelled_qty,
													ac.UserId,
													ac.CurrencyId
											FROM    ( SELECT    so.SellerUserId AS UserId,
																so.Sid AS OrderNum,
																ISNULL(so.CancelledOn,
																	   DATEFROMPARTS(DATEPART(year, p.LastPaymentDate),
																					 DATEPART(month, p.LastPaymentDate), 2)) AS CancelledOn ,
																sl.TotalPrice ,
																ISNULL(pl.CurrencyId,2) AS CurrencyId 
													  FROM      dbo.SALE_Orders AS so
																INNER JOIN dbo.SALE_OrderStatusesLOV AS st ON so.StatusId = st.StatusId
																INNER JOIN dbo.SALE_OrderLines AS sl ON so.OrderId = sl.OrderId
																INNER JOIN ( SELECT MAX(lp.PaymentDate) AS LastPaymentDate ,
																					lp.OrderLineId
																			 FROM   dbo.SALE_OrderLinePayments AS lp
																					INNER JOIN dbo.SALE_PaymentStatusesLOV
																					AS ps ON lp.StatusId = ps.StatusId
																			 WHERE  ( ps.StatusCode = 'COMPLETED' )
																			 GROUP BY lp.OrderLineId
																		   ) AS p ON sl.LineId = p.OrderLineId
																LEFT OUTER  JOIN dbo.BILL_ItemsPriceList AS pl ON sl.PriceLineId = pl.PriceLineId
																INNER JOIN dbo.SALE_OrderLineTypesLOV AS ltp ON sl.LineTypeId = ltp.TypeId
																LEFT OUTER JOIN dbo.WebStores AS ws ON so.WebStoreId = ws.StoreID
													  WHERE     ( st.StatusCode = 'CANCELED' OR st.StatusCode='SUSPENDED')
																AND ( ltp.TypeCode = 'SUBSCRIPTION' )
																AND ( ws.OwnerUserID IS NULL OR ws.OwnerUserID = so.SellerUserId)
																AND ( so.SellerUserId = @UserId )
																AND (ISNULL(pl.CurrencyId,2) = @CurrencyId)
																AND (@StoreId IS NULL OR WebStoreId = @StoreId)
													) AS ac
											WHERE  ( CAST(CancelledOn AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
											GROUP BY ac.UserId,
													ac.CurrencyId
										) AS auth_cancel ON auth_cancel.UserId = u.UserId
														AND auth_cancel.CurrencyId = u.CurrencyId

							LEFT OUTER JOIN (
								-- By Affiliate subscription cancellations
											SELECT  ISNULL(SUM(ac.TotalNetPrice), 0) AS total_cancelled ,
													COUNT(ac.OrderNum) AS total_cancelled_qty,
													ac.UserId,
													ac.CurrencyId
											FROM    ( SELECT    so.SellerUserId AS UserId,
																so.Sid AS OrderNum,
																ISNULL(so.CancelledOn,
																		DATEFROMPARTS(DATEPART(year, p.LastPaymentDate),
																						DATEPART(month, p.LastPaymentDate), 2)) AS CancelledOn ,
																(sl.TotalPrice  * ( 1 - sl.AffiliateCommission / 100 ) ) AS TotalNetPrice,
																ISNULL(pl.CurrencyId,2) AS CurrencyId 
														FROM      dbo.SALE_Orders AS so
																INNER JOIN dbo.SALE_OrderStatusesLOV AS st ON so.StatusId = st.StatusId
																INNER JOIN dbo.SALE_OrderLines AS sl ON so.OrderId = sl.OrderId
																INNER JOIN ( SELECT MAX(lp.PaymentDate) AS LastPaymentDate ,
																					lp.OrderLineId
																				FROM   dbo.SALE_OrderLinePayments AS lp
																					INNER JOIN dbo.SALE_PaymentStatusesLOV
																					AS ps ON lp.StatusId = ps.StatusId
																				WHERE  ( ps.StatusCode = 'COMPLETED' )
																				GROUP BY lp.OrderLineId
																			) AS p ON sl.LineId = p.OrderLineId
																LEFT OUTER  JOIN dbo.BILL_ItemsPriceList AS pl ON sl.PriceLineId = pl.PriceLineId
																INNER JOIN dbo.SALE_OrderLineTypesLOV AS ltp ON sl.LineTypeId = ltp.TypeId
																LEFT OUTER JOIN dbo.WebStores AS ws ON so.WebStoreId = ws.StoreID
														WHERE     ( st.StatusCode = 'CANCELED' OR st.StatusCode='SUSPENDED')
																AND ( ltp.TypeCode = 'SUBSCRIPTION' )
																AND ( WebStoreId IS NOT NULL )
																AND ( ws.OwnerUserID <> so.SellerUserId )
																AND ( so.SellerUserId = @UserId )
																AND (ISNULL(pl.CurrencyId,2) = @CurrencyId)
																AND (@StoreId IS NULL OR WebStoreId = @StoreId)
													) AS ac
											WHERE   ( CAST(CancelledOn AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
												GROUP BY ac.UserId,
													ac.CurrencyId 
										) AS by_aff_cancel ON by_aff_cancel.UserId = u.UserId
														AND by_aff_cancel.CurrencyId = u.CurrencyId

							LEFT OUTER JOIN (
									-- Affiliate subscription cancellations
									SELECT  ISNULL(SUM(ac.TotalNetPrice), 0) AS total_cancelled ,
											COUNT(ac.OrderNum) AS total_cancelled_qty,
											ac.UserId,
											ac.CurrencyId
									FROM    ( SELECT    ws.OwnerUserID AS UserId,
														so.Sid AS OrderNum,
														ISNULL(so.CancelledOn,
															   DATEFROMPARTS(DATEPART(year, p.LastPaymentDate),
																			 DATEPART(month, p.LastPaymentDate), 2)) AS CancelledOn ,
														(sl.TotalPrice *  ( AffiliateCommission / 100 ) ) AS TotalNetPrice,
														ISNULL(pl.CurrencyId,2) AS CurrencyId 
											  FROM      dbo.SALE_Orders AS so
														INNER JOIN dbo.SALE_OrderStatusesLOV AS st ON so.StatusId = st.StatusId
														INNER JOIN dbo.SALE_OrderLines AS sl ON so.OrderId = sl.OrderId
														INNER JOIN ( SELECT MAX(lp.PaymentDate) AS LastPaymentDate ,
																			lp.OrderLineId
																	 FROM   dbo.SALE_OrderLinePayments AS lp
																			INNER JOIN dbo.SALE_PaymentStatusesLOV
																			AS ps ON lp.StatusId = ps.StatusId
																	 WHERE  ( ps.StatusCode = 'COMPLETED' )
																	 GROUP BY lp.OrderLineId
																   ) AS p ON sl.LineId = p.OrderLineId
														LEFT OUTER JOIN dbo.BILL_ItemsPriceList AS pl ON sl.PriceLineId = pl.PriceLineId
														INNER JOIN dbo.SALE_OrderLineTypesLOV AS ltp ON sl.LineTypeId = ltp.TypeId
														LEFT OUTER JOIN dbo.WebStores AS ws ON so.WebStoreId = ws.StoreID
											  WHERE     ( st.StatusCode = 'CANCELED' OR st.StatusCode='SUSPENDED')
														AND ( ltp.TypeCode = 'SUBSCRIPTION' )
														AND  (WebStoreId IS NOT NULL )
														AND (ws.OwnerUserID <> so.SellerUserId )
														AND (ws.OwnerUserID = @UserId)
														AND (ISNULL(pl.CurrencyId,2) = @CurrencyId)
														AND (@StoreId IS NULL OR WebStoreId = @StoreId)
											) AS ac
									WHERE   ( CAST(CancelledOn AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
									   GROUP BY ac.UserId,
											ac.CurrencyId 
										) AS aff_cancel ON aff_cancel.UserId = u.UserId
														AND aff_cancel.CurrencyId = u.CurrencyId

		-- COUPONS 
						LEFT OUTER JOIN (
								-- Author Coupons
										SELECT  SellerUserId AS UserId ,
												SUM(ISNULL(Discount, 0)) AS DiscountValue ,
												--COUNT(LineId) AS total_qty ,
												COUNT(DISTINCT (LineId)) AS total_qty,
												ISNULL(CurrencyId,2) AS CurrencyId
										FROM    dbo.vw_SALE_OrderLines
										WHERE   ( StoreOwnerUserId IS NULL OR StoreOwnerUserId = SellerUserId)
												AND ( CAST(OrderDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
												AND ( SellerUserId = @UserId )
												AND ( CouponInstanceId IS NOT NULL )
												AND (ISNULL(CurrencyId,2) = @CurrencyId)
												AND (@StoreId IS NULL OR WebStoreId = @StoreId)
										GROUP BY SellerUserId ,
												ISNULL(CurrencyId,2)
							) AS auth_coupon ON auth_coupon.UserId = u.UserId
											AND auth_coupon.CurrencyId = u.CurrencyId

							LEFT OUTER JOIN (
								-- By Affiliate Coupons
										SELECT  SellerUserId AS UserId ,
												SUM(ISNULL(Discount, 0)) AS DiscountValue ,--*( 1 - AffiliateCommission / 100 )
												--COUNT(LineId) AS total_qty ,
												COUNT(DISTINCT (LineId)) AS total_qty,
												ISNULL(CurrencyId,2) AS CurrencyId
										FROM    dbo.vw_SALE_OrderLines
										WHERE   ( CAST(OrderDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
												AND ( WebStoreId IS NOT NULL )
												AND ( StoreOwnerUserId <> SellerUserId )
												AND (SellerUserId = @UserId)
												AND ( CouponInstanceId IS NOT NULL )
												AND (ISNULL(CurrencyId,2) = @CurrencyId)
												AND (@StoreId IS NULL OR WebStoreId = @StoreId)
										GROUP BY SellerUserId ,
												ISNULL(CurrencyId,2)
							) AS by_aff_coupon ON by_aff_coupon.UserId = u.UserId
											AND by_aff_coupon.CurrencyId = u.CurrencyId

							LEFT OUTER JOIN (
								-- Affiliate Coupons
										SELECT  StoreOwnerUserId AS UserId ,
												SUM(ISNULL(Discount, 0)) AS DiscountValue , --*( AffiliateCommission / 100 )
												--COUNT(LineId) AS total_qty ,
												COUNT(DISTINCT (LineId)) AS total_qty,
												ISNULL(CurrencyId,2) AS CurrencyId
										FROM    dbo.vw_SALE_OrderLines
										WHERE   ( CAST(OrderDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
												AND (WebStoreId IS NOT NULL )
												AND (StoreOwnerUserId <> SellerUserId )
												AND (StoreOwnerUserId = @UserId)
												AND ( CouponInstanceId IS NOT NULL )
												AND (ISNULL(CurrencyId,2) = @CurrencyId)
												AND (@StoreId IS NULL OR WebStoreId = @StoreId)
										GROUP BY StoreOwnerUserId ,
												ISNULL(CurrencyId,2)
							) AS aff_coupon ON aff_coupon.UserId = u.UserId
											AND aff_coupon.CurrencyId = u.CurrencyId
		) AS t  INNER JOIN
								 dbo.BASE_CurrencyLib AS cur ON t.CurrencyId = cur.CurrencyId
)

GO
/****** Object:  View [dbo].[vw_PO_MonthlySalesByAffiliates]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*	AND (( @UserId IS NULL ) OR ( so.SellerUserId = @UserId ))*/
CREATE VIEW [dbo].[vw_PO_MonthlySalesByAffiliates]
AS
SELECT        SellerUserId AS UserId, DATEPART(year, PaymentDate) AS Year, DATEPART(month, PaymentDate) AS Month, SUM(Amount) AS total_sales, 
                         SUM(CASE WHEN s.IsUnderRGP = 1 THEN s.Amount ELSE 0 END) AS total_rgp_sales, SUM(CASE WHEN s.IsUnderRGP = 0 THEN s.Amount ELSE 0 END) 
                         AS total_non_rgp_sales, SUM(Fee) AS total_fees, SUM(CASE WHEN s.IsUnderRGP = 1 THEN s.Fee ELSE 0 END) AS total_rgp_fee, 
                         SUM(CASE WHEN s.IsUnderRGP = 0 THEN s.Fee ELSE 0 END) AS total_non_rgp_fee, 
                         SUM(CASE WHEN s.IsUnderRGP = 1 THEN s.Amount * (1 - s.AffiliateCommission / 100) ELSE 0 END) AS total_net_rgp_sales, 
                         SUM(CASE WHEN s.IsUnderRGP = 0 THEN s.Amount * (1 - s.AffiliateCommission / 100) ELSE 0 END) AS total_net_non_rgp_sales, 
                         SUM(Fee * (1 - AffiliateCommission / 100)) AS total_net_fees, SUM(CASE WHEN s.IsUnderRGP = 1 THEN s.Fee * (1 - s.AffiliateCommission / 100) ELSE 0 END) 
                         AS total_net_rgp_fee, SUM(CASE WHEN s.IsUnderRGP = 0 THEN s.Fee * (1 - s.AffiliateCommission / 100) ELSE 0 END) AS total_net_non_rgp_fee, CurrencyId
FROM            dbo.vw_SALE_OrderLinePayments AS s
WHERE        (StatusCode = 'COMPLETED') AND (WebStoreId IS NOT NULL) AND (StoreOwnerUserId <> SellerUserId)
GROUP BY SellerUserId, CurrencyId, DATEPART(year, PaymentDate), DATEPART(month, PaymentDate)

GO
/****** Object:  View [dbo].[vw_PO_MonthlyAuthorSales]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_PO_MonthlyAuthorSales]
AS
SELECT        SellerUserId AS UserId, DATEPART(year, PaymentDate) AS Year, DATEPART(month, PaymentDate) AS Month, SUM(Amount) AS total_sales, 
                         SUM(CASE WHEN s.IsUnderRGP = 1 THEN s.Amount ELSE 0 END) AS total_rgp_sales, SUM(CASE WHEN s.IsUnderRGP = 0 THEN s.Amount ELSE 0 END) 
                         AS total_non_rgp_sales, SUM(Fee) AS total_fees, SUM(CASE WHEN s.IsUnderRGP = 1 THEN s.Fee ELSE 0 END) AS total_rgp_fee, 
                         SUM(CASE WHEN s.IsUnderRGP = 0 THEN s.Fee ELSE 0 END) AS total_non_rgp_fee, CurrencyId
FROM            dbo.vw_SALE_OrderLinePayments AS s
WHERE        (StatusCode = 'COMPLETED') AND (StoreOwnerUserId IS NULL OR
                         StoreOwnerUserId = SellerUserId)
GROUP BY SellerUserId, CurrencyId, DATEPART(year, PaymentDate), DATEPART(month, PaymentDate)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DB_GetAuthorPeriodCurrenciesLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-11-03
-- Description:	Get Author currencies LOV for dashboard
-- =============================================
CREATE FUNCTION [dbo].[tvf_DB_GetAuthorPeriodCurrenciesLOV]
(	
	@From DATE = NULL,
    @To DATE = NULL,
    @UserId INT 
)
RETURNS TABLE 
AS
RETURN 
(
			SELECT c.CurrencyId,
					c.CurrencyName,
					c.Symbol,
					c.ISO,
					SUM(ISNULL(up.EventCnt,0)) AS  EventCnt
			FROM      ( 	 SELECT    SellerUserId AS UserId ,
										COUNT(s.PaymentId) AS EventCnt,
										CurrencyId
							FROM      dbo.vw_SALE_OrderLinePayments AS s
							WHERE   ( StatusCode = 'COMPLETED' )
									AND ((@From IS NULL AND @To IS NULL) OR (( CAST(PaymentDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) )))
									AND ( SellerUserId = @UserId )
							GROUP BY  SellerUserId ,
									CurrencyId
							UNION
							SELECT    StoreOwnerUserId AS UserId ,
								      COUNT(s.PaymentId) AS EventCnt,
									  CurrencyId
							FROM      dbo.vw_SALE_OrderLinePayments AS s
							WHERE     ( StatusCode = 'COMPLETED' )
									AND ( WebStoreId IS NOT NULL ) AND ( StoreOwnerUserId <> SellerUserId )
									AND ((@From IS NULL AND @To IS NULL) OR (( CAST(PaymentDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) )))
									AND ( StoreOwnerUserId = @UserId )
							GROUP BY  StoreOwnerUserId ,
									CurrencyId
					) AS up
					INNER JOIN dbo.BASE_CurrencyLib AS c ON up.CurrencyId = c.CurrencyId
					RIGHT OUTER JOIN dbo.Users AS u ON ISNULL(up.UserId, u.Id) = u.Id
			WHERE     ( u.Id = @UserId )
			GROUP BY  c.CurrencyId,
					c.CurrencyName,
					c.Symbol,
					c.ISO
)

GO
/****** Object:  View [dbo].[vw_PO_MonthlyAffiliateSales]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_PO_MonthlyAffiliateSales]
AS
SELECT        StoreOwnerUserId AS UserId, DATEPART(year, PaymentDate) AS Year, DATEPART(month, PaymentDate) AS Month, SUM(Amount) AS total_sales, 
                         SUM(CASE WHEN s.IsUnderRGP = 1 THEN s.Amount ELSE 0 END) AS total_rgp_sales, SUM(CASE WHEN s.IsUnderRGP = 0 THEN s.Amount ELSE 0 END) 
                         AS total_non_rgp_sales, SUM(Amount * (AffiliateCommission / 100)) AS total_commission, 
                         SUM(CASE WHEN s.IsUnderRGP = 1 THEN s.Amount * (s.AffiliateCommission / 100) ELSE 0 END) AS total_rgp_commission, 
                         SUM(CASE WHEN s.IsUnderRGP = 0 THEN s.Amount * (s.AffiliateCommission / 100) ELSE 0 END) AS total_non_rgp_commission, SUM(Fee) AS total_fees, 
                         SUM(CASE WHEN s.IsUnderRGP = 1 THEN s.Fee ELSE 0 END) AS total_rgp_fee, SUM(CASE WHEN s.IsUnderRGP = 0 THEN s.Fee ELSE 0 END) 
                         AS total_non_rgp_fee, SUM(Fee * (AffiliateCommission / 100)) AS total_net_fees, SUM(CASE WHEN s.IsUnderRGP = 1 THEN s.Fee * (s.AffiliateCommission / 100) 
                         ELSE 0 END) AS total_net_rgp_fee, SUM(CASE WHEN s.IsUnderRGP = 0 THEN s.Fee * (s.AffiliateCommission / 100) ELSE 0 END) AS total_net_non_rgp_fee, 
                         CurrencyId
FROM            dbo.vw_SALE_OrderLinePayments AS s
WHERE        (StatusCode = 'COMPLETED') AND (WebStoreId IS NOT NULL) AND (StoreOwnerUserId <> SellerUserId)
GROUP BY StoreOwnerUserId, DATEPART(year, PaymentDate), DATEPART(month, PaymentDate), CurrencyId

GO
/****** Object:  View [dbo].[vw_PO_MonthlyRefundsByAffiliates]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_PO_MonthlyRefundsByAffiliates]
AS
SELECT SellerUserId AS UserId, SUM(ABS(Amount)) AS total_refunded, SUM(ABS(Amount * (1 - AffiliateCommission / 100))) AS total_net_refunded, SUM(ABS(Fee)) AS fee_refunded, 
                  SUM(ABS(Fee * (1 - AffiliateCommission / 100))) AS fee_net_refunded, DATEPART(year, RefundDate) AS Year, DATEPART(month, RefundDate) AS Month, CurrencyId
FROM     dbo.vw_SALE_OrderLinePaymentRefunds AS r
WHERE  (WebStoreId IS NOT NULL) AND (StoreOwnerUserId <> SellerUserId)
GROUP BY SellerUserId, DATEPART(year, RefundDate), DATEPART(month, RefundDate), CurrencyId

GO
/****** Object:  View [dbo].[vw_PO_MonthlyAuthorRefunds]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_PO_MonthlyAuthorRefunds]
AS
SELECT SellerUserId AS UserId, SUM(ABS(Amount)) AS total_refunded, SUM(ABS(Fee)) AS fee_refunded, DATEPART(year, RefundDate) AS Year, DATEPART(month, RefundDate) 
                  AS Month, CurrencyId
FROM     dbo.vw_SALE_OrderLinePaymentRefunds AS r
WHERE  (StoreOwnerUserId IS NULL) OR
                  (StoreOwnerUserId = SellerUserId)
GROUP BY SellerUserId, DATEPART(year, RefundDate), DATEPART(month, RefundDate), CurrencyId

GO
/****** Object:  View [dbo].[vw_PO_MonthlyAffiliateRefunds]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_PO_MonthlyAffiliateRefunds]
AS
SELECT StoreOwnerUserId AS UserId, SUM(ABS(Amount)) AS total_refunded, SUM(ABS(Amount * (AffiliateCommission / 100))) AS total_net_refunded, SUM(ABS(Fee)) 
                  AS fee_refunded, SUM(ABS(Fee * (AffiliateCommission / 100))) AS fee_net_refunded, DATEPART(year, RefundDate) AS Year, DATEPART(month, RefundDate) AS Month, 
                  CurrencyId
FROM     dbo.vw_SALE_OrderLinePaymentRefunds AS r
WHERE  (WebStoreId IS NOT NULL) AND (StoreOwnerUserId <> SellerUserId)
GROUP BY DATEPART(year, RefundDate), DATEPART(month, RefundDate), CurrencyId, StoreOwnerUserId

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_PO_GetMonthlyPayoutReport]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[tvf_PO_GetMonthlyPayoutReport]
    (
      @Year INT ,
      @Month INT ,
      @PrevYear INT ,
      @PrevMonth INT ,
      @LfeCommission INT ,
      @UserId INT = NULL ,
      @CurrencyId SMALLINT = NULL
    )
RETURNS TABLE
AS
RETURN
    (
	  SELECT    po.UserId ,
                po.TotalSales ,
                po.AuthorSales ,
                po.AffiliateTotalSales ,
                po.AffiliateCommission ,
                po.AffiliateFees ,
                po.TotalFees ,
                po.RefundProgramHold ,
                po.RefundProgramReleased ,
                po.TotalRefunded ,
                po.TotalRefundedFees ,
                ISNULL(po.Balance,0) AS Balance ,
                ISNULL(( po.Balance * @LfeCommission / 100 ), 0) AS LfeCommissions ,
                ISNULL(( po.Balance - po.Balance * @LfeCommission / 100 ), 0) AS Payout ,
                po.Author_total_sales ,
                po.Author_total_rgp_sales ,
                po.Author_total_non_rgp_sales ,
                po.Author_total_fees ,
                po.Author_total_rgp_fee ,
                po.Author_total_non_rgp_fee ,
                po.By_Affiliate_total_sales ,
                po.By_Affiliate_total_rgp_sales ,
                po.By_Affiliate_total_non_rgp_sales ,
                po.By_Affiliate_total_fees ,
                po.By_Affiliate_total_rgp_fee ,
                po.By_Affiliate_total_non_rgp_fee ,
                po.By_Affiliate_total_net_rgp_sales ,
                po.By_Affiliate_total_net_non_rgp_sales ,
                po.By_Affiliate_total_net_fees ,
                po.By_Affiliate_total_net_rgp_fee ,
                po.By_Affiliate_total_net_non_rgp_fee ,
                po.Affiliate_total_sales ,
                po.Affiliate_total_rgp_sales ,
                po.Affiliate_total_non_rgp_sales ,
                po.Affiliate_total_commission ,
                po.Affiliate_total_rgp_commission ,
                po.Affiliate_total_non_rgp_commission ,
                po.Affiliate_total_fees ,
                po.Affiliate_total_rgp_fee ,
                po.Affiliate_total_non_rgp_fee ,
                po.Affiliate_total_net_fees ,
                po.Affiliate_total_net_rgp_fee ,
                po.Affiliate_total_net_non_rgp_fee ,
                po.Author_Released_total_rgp_sales ,
                po.Author_Released_total_rgp_fee ,
                po.Affiliate_Released_total_net_rgp_sales ,
                po.Affiliate_Released_total_net_rgp_fee ,
                po.By_Affiliate_Released_total_rgp_commission ,
                po.By_Affiliate_Released_total_net_rgp_fee ,
                po.Author_total_refunded ,
                po.Author_fee_refunded ,
                po.Affiliate_total_refunded ,
                po.Affiliate_fee_refunded ,
                po.Affiliate_total_net_refunded ,
                po.Affiliate_fee_net_refunded ,
                po.By_Affiliate_total_refunded ,
                po.By_Affiliate_fee_refunded ,
                po.By_Affiliate_total_net_refunded ,
                po.By_Affiliate_fee_net_refunded ,
                po.CurrencyId
      FROM      ( SELECT    p.UserId ,
							ISNULL(p.TotalSales,0) AS TotalSales,
							ISNULL(p.AuthorSales,0) AS AuthorSales,
							ISNULL(p.AffiliateTotalSales,0) AS AffiliateTotalSales,
							ISNULL(p.AffiliateCommission,0) AS AffiliateCommission,
							ISNULL(( p.Affiliate_total_non_rgp_sales + p.By_Affiliate_total_non_rgp_sales - p.AffiliateCommission ),0) AS AffiliateFees ,
							ISNULL(p.TotalFees,0) AS TotalFees,
							ISNULL(p.RefundProgramHold,0) AS RefundProgramHold,
							ISNULL(p.RefundProgramReleased,0) AS RefundProgramReleased,							
							ISNULL(p.TotalRefunded,0) AS TotalRefunded,
							ISNULL(p.TotalRefundedFees,0) AS TotalRefundedFees,                            
                            ( p.AuthorSales  + ISNULL(p.AffiliateTotalSales,0) + p.AffiliateCommission + p.RefundProgramReleased - p.RefundProgramHold - p.TotalFees - p.TotalRefunded + p.TotalRefundedFees ) AS Balance ,
                            p.Author_total_sales ,
                            p.Author_total_rgp_sales ,
                            p.Author_total_non_rgp_sales ,
                            p.Author_total_fees ,
                            p.Author_total_rgp_fee ,
                            p.Author_total_non_rgp_fee ,
                            p.By_Affiliate_total_sales ,
                            p.By_Affiliate_total_rgp_sales ,
                            p.By_Affiliate_total_non_rgp_sales ,
                            p.By_Affiliate_total_fees ,
                            p.By_Affiliate_total_rgp_fee ,
                            p.By_Affiliate_total_non_rgp_fee ,
                            p.By_Affiliate_total_net_rgp_sales ,
                            p.By_Affiliate_total_net_non_rgp_sales ,
                            p.By_Affiliate_total_net_fees ,
                            p.By_Affiliate_total_net_rgp_fee ,
                            p.By_Affiliate_total_net_non_rgp_fee ,
                            p.Affiliate_total_sales ,
                            p.Affiliate_total_rgp_sales ,
                            p.Affiliate_total_non_rgp_sales ,
                            p.Affiliate_total_commission ,
                            p.Affiliate_total_rgp_commission ,
                            p.Affiliate_total_non_rgp_commission ,
                            p.Affiliate_total_fees ,
                            p.Affiliate_total_rgp_fee ,
                            p.Affiliate_total_non_rgp_fee ,
                            p.Affiliate_total_net_fees ,
                            p.Affiliate_total_net_rgp_fee ,
                            p.Affiliate_total_net_non_rgp_fee ,
                            p.Author_Released_total_rgp_sales ,
                            p.Author_Released_total_rgp_fee ,
                            p.Affiliate_Released_total_net_rgp_sales ,
                            p.Affiliate_Released_total_net_rgp_fee ,
                            p.By_Affiliate_Released_total_rgp_commission ,
                            p.By_Affiliate_Released_total_net_rgp_fee ,
                            p.Author_total_refunded ,
                            p.Author_fee_refunded ,
                            p.Affiliate_total_refunded ,
                            p.Affiliate_fee_refunded ,
                            p.Affiliate_total_net_refunded ,
                            p.Affiliate_fee_net_refunded ,
                            p.By_Affiliate_total_refunded ,
                            p.By_Affiliate_fee_refunded ,
                            p.By_Affiliate_total_net_refunded ,
                            p.By_Affiliate_fee_net_refunded ,
                            p.CurrencyId
                  FROM      ( SELECT    r.UserId ,
                                        ( r.Author_total_sales + r.Affiliate_total_sales + r.By_Affiliate_total_sales ) AS TotalSales ,
                                        r.Author_total_sales AS AuthorSales ,
                                        ( r.Affiliate_total_sales + r.By_Affiliate_total_sales ) AS AffiliateTotalSales ,
                                        ( r.Author_total_non_rgp_fee + r.Affiliate_total_net_non_rgp_fee + r.By_Affiliate_total_net_non_rgp_fee + r.Author_Released_total_rgp_fee + r.Affiliate_Released_total_net_rgp_fee + r.By_Affiliate_Released_total_net_rgp_fee ) AS TotalFees ,
                                        ( r.Author_total_rgp_sales + r.Affiliate_total_rgp_sales + r.By_Affiliate_total_rgp_sales ) AS RefundProgramHold ,
                                        ( r.Author_Released_total_rgp_sales + r.Affiliate_Released_total_net_rgp_sales + r.By_Affiliate_Released_total_rgp_commission ) AS RefundProgramReleased ,
                                        ( r.Affiliate_total_non_rgp_commission + r.By_Affiliate_total_net_non_rgp_sales ) AS AffiliateCommission ,
                                        ( r.Author_total_refunded + r.Affiliate_total_net_refunded + r.By_Affiliate_total_net_refunded ) AS TotalRefunded ,
                                        ( r.Author_fee_refunded + r.Affiliate_fee_net_refunded + r.By_Affiliate_fee_net_refunded ) AS TotalRefundedFees ,
                                        r.Author_total_sales ,
                                        r.Author_total_rgp_sales ,
                                        r.Author_total_non_rgp_sales ,
                                        r.Author_total_fees ,
                                        r.Author_total_rgp_fee ,
                                        r.Author_total_non_rgp_fee ,
                                        r.By_Affiliate_total_sales ,
                                        r.By_Affiliate_total_rgp_sales ,
                                        r.By_Affiliate_total_non_rgp_sales ,
                                        r.By_Affiliate_total_fees ,
                                        r.By_Affiliate_total_rgp_fee ,
                                        r.By_Affiliate_total_non_rgp_fee ,
                                        r.By_Affiliate_total_net_rgp_sales ,
                                        r.By_Affiliate_total_net_non_rgp_sales ,
                                        r.By_Affiliate_total_net_fees ,
                                        r.By_Affiliate_total_net_rgp_fee ,
                                        r.By_Affiliate_total_net_non_rgp_fee ,
                                        r.Affiliate_total_sales ,
                                        r.Affiliate_total_rgp_sales ,
                                        r.Affiliate_total_non_rgp_sales ,
                                        r.Affiliate_total_commission ,
                                        r.Affiliate_total_rgp_commission ,
                                        r.Affiliate_total_non_rgp_commission ,
                                        r.Affiliate_total_fees ,
                                        r.Affiliate_total_rgp_fee ,
                                        r.Affiliate_total_non_rgp_fee ,
                                        r.Affiliate_total_net_fees ,
                                        r.Affiliate_total_net_rgp_fee ,
                                        r.Affiliate_total_net_non_rgp_fee ,
                                        r.Author_Released_total_rgp_sales ,
                                        r.Author_Released_total_rgp_fee ,
                                        r.Affiliate_Released_total_net_rgp_sales ,
                                        r.Affiliate_Released_total_net_rgp_fee ,
                                        r.By_Affiliate_Released_total_rgp_commission ,
                                        r.By_Affiliate_Released_total_net_rgp_fee ,
                                        r.Author_total_refunded ,
                                        r.Author_fee_refunded ,
                                        r.Affiliate_total_refunded ,
                                        r.Affiliate_fee_refunded ,
                                        r.Affiliate_total_net_refunded ,
                                        r.Affiliate_fee_net_refunded ,
                                        r.By_Affiliate_total_refunded ,
                                        r.By_Affiliate_fee_refunded ,
                                        r.By_Affiliate_total_net_refunded ,
                                        r.By_Affiliate_fee_net_refunded ,
                                        r.CurrencyId
                              FROM      ( SELECT    u.UserId ,
				
							
								-- Author sales --
								---------------------------------------------------------
                                                    ISNULL(mas.total_sales, 0) AS Author_total_sales ,
                                                    ISNULL(mas.total_rgp_sales, 0) AS Author_total_rgp_sales ,
                                                    ISNULL(mas.total_non_rgp_sales, 0) AS Author_total_non_rgp_sales ,
                                                    ISNULL(mas.total_fees, 0) AS Author_total_fees ,
                                                    ISNULL(mas.total_rgp_fee,0) AS Author_total_rgp_fee ,
                                                    ISNULL(mas.total_non_rgp_fee,0) AS Author_total_non_rgp_fee ,
		
								-- Sales by Affiliate --
								----------------------------------------------------------------------
                                                    ISNULL(msba.total_sales, 0) AS By_Affiliate_total_sales ,
                                                    ISNULL(msba.total_rgp_sales,0) AS By_Affiliate_total_rgp_sales ,
                                                    ISNULL(msba.total_non_rgp_sales,0) AS By_Affiliate_total_non_rgp_sales ,
                                                    ISNULL(msba.total_fees, 0) AS By_Affiliate_total_fees ,
                                                    ISNULL(msba.total_rgp_fee,0) AS By_Affiliate_total_rgp_fee ,
                                                    ISNULL(msba.total_non_rgp_fee,0) AS By_Affiliate_total_non_rgp_fee ,
                                                    ISNULL(msba.total_net_rgp_sales,0) AS By_Affiliate_total_net_rgp_sales ,
                                                    ISNULL(msba.total_net_non_rgp_sales,0) AS By_Affiliate_total_net_non_rgp_sales ,
                                                    ISNULL(msba.total_net_fees,0) AS By_Affiliate_total_net_fees ,
                                                    ISNULL(msba.total_net_rgp_fee,0) AS By_Affiliate_total_net_rgp_fee ,
                                                    ISNULL(msba.total_net_non_rgp_fee,0) AS By_Affiliate_total_net_non_rgp_fee ,
		
								-- Affiliate sales --
								--------------------------------------------------------------
                                                    ISNULL(mos.total_sales, 0) AS Affiliate_total_sales ,
                                                    ISNULL(mos.total_rgp_sales,0) AS Affiliate_total_rgp_sales ,
                                                    ISNULL(mos.total_non_rgp_sales,0) AS Affiliate_total_non_rgp_sales ,
                                                    ISNULL(mos.total_commission,0) AS Affiliate_total_commission ,
                                                    ISNULL(mos.total_rgp_commission,0) AS Affiliate_total_rgp_commission ,
                                                    ISNULL(mos.total_non_rgp_commission,0) AS Affiliate_total_non_rgp_commission ,
                                                    ISNULL(mos.total_fees, 0) AS Affiliate_total_fees ,
                                                    ISNULL(mos.total_rgp_fee,0) AS Affiliate_total_rgp_fee ,
                                                    ISNULL(mos.total_non_rgp_fee,0) AS Affiliate_total_non_rgp_fee ,
                                                    ISNULL(mos.total_net_fees,0) AS Affiliate_total_net_fees ,
                                                    ISNULL(mos.total_net_rgp_fee,0) AS Affiliate_total_net_rgp_fee ,
                                                    ISNULL(mos.total_net_non_rgp_fee,0) AS Affiliate_total_net_non_rgp_fee ,

								-- Author sales Released Previous Month MBG Programm --
								---------------------------------------------------------------
                                                    ISNULL(pmas.total_rgp_sales,0) AS Author_Released_total_rgp_sales ,
                                                    ISNULL(pmas.total_rgp_fee,0) AS Author_Released_total_rgp_fee ,

								-- Sales by Affiliate Released Previous Month MBG Programm --
								--------------------------------------------------------------
                                                    ISNULL(pmsba.total_net_rgp_sales,0) AS Affiliate_Released_total_net_rgp_sales ,
                                                    ISNULL(pmsba.total_net_rgp_fee,0) AS Affiliate_Released_total_net_rgp_fee ,


								-- Affiliate sales Released Previous Month MBG Programm --
								-----------------------------------------------------------------
                                                    ISNULL(pmos.total_rgp_commission,0) AS By_Affiliate_Released_total_rgp_commission ,
                                                    ISNULL(pmos.total_net_rgp_fee,0) AS By_Affiliate_Released_total_net_rgp_fee ,

								-- REFUNDS --
								-----------------------------------------------------------------------------

								-- Author Refunds --
								-----------------------------------------------------------------------------
                                                    ISNULL(ras.total_refunded,0) AS Author_total_refunded ,
                                                    ISNULL(ras.fee_refunded, 0) AS Author_fee_refunded ,

								-- Refunds by Affiliate --
								-----------------------------------------------------------------------------
                                                    ISNULL(ros.total_refunded,0) AS Affiliate_total_refunded ,
                                                    ISNULL(ros.fee_refunded, 0) AS Affiliate_fee_refunded ,
                                                    ISNULL(ros.total_net_refunded,0) AS Affiliate_total_net_refunded ,
                                                    ISNULL(ros.fee_net_refunded,0) AS Affiliate_fee_net_refunded ,

								-- Affiliate Refunds --
								-----------------------------------------------------------------------------
                                                    ISNULL(rsba.total_refunded,0) AS By_Affiliate_total_refunded ,
                                                    ISNULL(rsba.fee_refunded,0) AS By_Affiliate_fee_refunded ,
                                                    ISNULL(rsba.total_net_refunded,0) AS By_Affiliate_total_net_refunded ,
                                                    ISNULL(rsba.fee_net_refunded,0) AS By_Affiliate_fee_net_refunded ,
                                                    u.CurrencyId
                                          FROM      ( SELECT  usr.UserId ,
                                                              usr.CurrencyId
                                                      FROM    ( 
															  -- Auhtor sales --	
															  SELECT    UserId ,
																		CurrencyId
															  FROM      dbo.vw_PO_MonthlyAuthorSales
															  WHERE     ( Year = @Year ) AND ( Month = @Month )
																		AND ( @UserId IS NULL OR UserId = @UserId)
																		AND ( @CurrencyId IS NULL OR CurrencyId = @CurrencyId)
															  GROUP BY  UserId ,
																		CurrencyId
															  
															  -- Affiliate sales --
															  UNION
															  SELECT    UserId ,
																		CurrencyId
															  FROM      dbo.vw_PO_MonthlyAffiliateSales
															  WHERE     ( Year = @Year ) AND ( Month = @Month )
																		AND ( @UserId IS NULL OR UserId = @UserId)
																		AND ( @CurrencyId IS NULL OR CurrencyId = @CurrencyId)
															  GROUP BY  UserId ,
																		CurrencyId
															  
															  -- Sales by Affiliate --
															  UNION
															  SELECT    UserId ,
																		CurrencyId
															  FROM      dbo.vw_PO_MonthlySalesByAffiliates
															  WHERE     ( Year = @Year ) AND ( Month = @Month )
																		AND ( @UserId IS NULL OR UserId = @UserId)
																		AND ( @CurrencyId IS NULL OR CurrencyId = @CurrencyId)
															  GROUP BY  UserId ,
																		CurrencyId

															 -- Affiliate Sales released--
															 UNION  
															  SELECT    StoreOwnerUserId AS UserId ,
																			CurrencyId
																  FROM      dbo.vw_SALE_OrderLinePayments AS s
																  WHERE     ( StatusCode = 'COMPLETED' )
																			AND ( WebStoreId IS NOT NULL )
																			AND ( StoreOwnerUserId <> SellerUserId )
																			AND ( @UserId IS NULL OR StoreOwnerUserId = @UserId)
																			AND ( DATEPART(year, PaymentDate) = @PrevYear )
																			AND ( DATEPART(month, PaymentDate) = @PrevMonth )
																			AND ( s.TotalRefunded = 0 )
																			AND ( s.IsUnderRGP = 1 )
																  GROUP BY  StoreOwnerUserId ,
																			CurrencyId

															-- Sales by Affiliate released-- 
															 UNION 
															 SELECT    SellerUserId AS UserId ,
																			CurrencyId
																  FROM      dbo.vw_SALE_OrderLinePayments AS s
																  WHERE     ( StatusCode = 'COMPLETED' )
																			AND ( WebStoreId IS NOT NULL )
																			AND ( StoreOwnerUserId <> SellerUserId )
																			AND ( @UserId IS NULL OR SellerUserId = @UserId)
																			AND ( DATEPART(year, PaymentDate) = @PrevYear )
																			AND ( DATEPART(month, PaymentDate) = @PrevMonth )
																			AND ( s.TotalRefunded = 0 )
																			AND ( s.IsUnderRGP = 1 )
																  GROUP BY  SellerUserId ,
																			CurrencyId
															-- Author Sales released--  
															UNION 
															SELECT  ISNULL(s.StoreOwnerUserId,SellerUserId) AS UserId ,
																	CurrencyId
															FROM    dbo.vw_SALE_OrderLinePayments AS s
															WHERE   ( StatusCode = 'COMPLETED' )
																	AND ( WebStoreId IS NULL OR s.StoreOwnerUserId = s.SellerUserId)
																	AND ( @UserId IS NULL OR s.SellerUserId = @UserId)
																	AND ( DATEPART(year, PaymentDate) = @PrevYear )
																	AND ( DATEPART(month, PaymentDate) = @PrevMonth )
																	AND ( s.TotalRefunded = 0 )
																	AND ( s.IsUnderRGP = 1 )
															GROUP BY ISNULL(s.StoreOwnerUserId,SellerUserId) ,
																	CurrencyId
                                                              ) AS usr
                                                      --WHERE   dbo.fn_USER_IsAdmin(usr.UserId) = 0
                                                    ) AS u -- Monthly Sales
                                                    LEFT OUTER JOIN dbo.vw_PO_MonthlyAffiliateSales
                                                    AS mos ON u.UserId = mos.UserId
                                                              AND u.CurrencyId = mos.CurrencyId
                                                              AND mos.[Year] = @Year
                                                              AND mos.[Month] = @Month
                                                    LEFT OUTER JOIN dbo.vw_PO_MonthlySalesByAffiliates
                                                    AS msba ON u.UserId = msba.UserId
                                                              AND u.CurrencyId = msba.CurrencyId
                                                              AND msba.[Year] = @Year
                                                              AND msba.[Month] = @Month
                                                    LEFT OUTER JOIN dbo.vw_PO_MonthlyAuthorSales
                                                    AS mas ON u.UserId = mas.UserId
                                                              AND u.CurrencyId = mas.CurrencyId
                                                              AND mas.[Year] = @Year
                                                              AND mas.[Month] = @Month

									-- Refunds
                                                    LEFT OUTER JOIN dbo.vw_PO_MonthlyAffiliateRefunds
                                                    AS ros ON u.UserId = ros.UserId
                                                              AND u.CurrencyId = ros.CurrencyId
                                                              AND ros.[Year] = @Year
                                                              AND ros.[Month] = @Month
                                                    LEFT OUTER JOIN dbo.vw_PO_MonthlyRefundsByAffiliates
                                                    AS rsba ON u.UserId = rsba.UserId
                                                              AND u.CurrencyId = rsba.CurrencyId
                                                              AND rsba.[Year] = @Year
                                                              AND rsba.[Month] = @Month
                                                    LEFT OUTER JOIN dbo.vw_PO_MonthlyAuthorRefunds
                                                    AS ras ON u.UserId = ras.UserId
                                                              AND u.CurrencyId = ras.CurrencyId
                                                              AND ras.[Year] = @Year
                                                              AND ras.[Month] = @Month

									--previous month released MBG
									-- Affiliate Sales --
                                                    LEFT OUTER JOIN ( SELECT
																		  StoreOwnerUserId AS UserId ,
																		  SUM(s.Amount * ( s.AffiliateCommission / 100 )) AS total_rgp_commission ,
																		  SUM(s.Fee * ( s.AffiliateCommission / 100 )) AS total_net_rgp_fee ,
																		  CurrencyId
																		  FROM
																		  dbo.vw_SALE_OrderLinePayments
																		  AS s
																		  WHERE
																		  ( StatusCode = 'COMPLETED' )
																		  AND ( WebStoreId IS NOT NULL )
																		  AND ( StoreOwnerUserId <> SellerUserId )
																		  AND ( DATEPART(year,
																		  PaymentDate) = @PrevYear )
																		  AND ( DATEPART(month,
																		  PaymentDate) = @PrevMonth )
																		  AND ( s.TotalRefunded = 0 )
																		  AND ( s.IsUnderRGP = 1 )
																		  GROUP BY StoreOwnerUserId ,
																		  CurrencyId
																		  ) AS pmos ON u.UserId = pmos.UserId AND u.CurrencyId = pmos.CurrencyId
									-- Sales by Affiliate --                           
                                                    LEFT OUTER JOIN ( SELECT
																	  SellerUserId AS UserId ,
																	  SUM(s.Amount * ( 1 - s.AffiliateCommission / 100 )) AS total_net_rgp_sales ,
																	  SUM(s.Fee * ( 1 - s.AffiliateCommission / 100 )) AS total_net_rgp_fee ,
																	  CurrencyId
																	  FROM
																	  dbo.vw_SALE_OrderLinePayments
																	  AS s
																	  WHERE
																	  ( StatusCode = 'COMPLETED' )
																	  AND ( WebStoreId IS NOT NULL )
																	  AND ( StoreOwnerUserId <> SellerUserId )
																	  AND ( DATEPART(year,
																	  PaymentDate) = @PrevYear )
																	  AND ( DATEPART(month,
																	  PaymentDate) = @PrevMonth )
																	  AND ( s.TotalRefunded = 0 )
																	  AND ( s.IsUnderRGP = 1 )
																	  GROUP BY SellerUserId ,
																	  CurrencyId
																	  ) AS pmsba ON u.UserId = pmsba.UserId AND u.CurrencyId = pmsba.CurrencyId
									-- Author Sales --                                                              
                                                    LEFT OUTER JOIN ( SELECT  ISNULL(s.StoreOwnerUserId,SellerUserId) AS UserId ,
																				SUM(s.Amount) AS total_rgp_sales ,
																				SUM(s.Fee) AS total_rgp_fee ,
																				CurrencyId
																		FROM    dbo.vw_SALE_OrderLinePayments AS s
																		WHERE   ( StatusCode = 'COMPLETED' )
																				AND ( WebStoreId IS NULL OR s.SellerUserId = s.SellerUserId)
																				AND ( DATEPART(year, PaymentDate) = @PrevYear )
																				AND ( DATEPART(month, PaymentDate) = @PrevMonth )
																				AND ( s.TotalRefunded = 0 )
																				AND ( s.IsUnderRGP = 1 )
																		GROUP BY ISNULL(s.StoreOwnerUserId,SellerUserId) ,
																				CurrencyId
																	  ) AS pmas ON u.UserId = pmas.UserId AND u.CurrencyId = pmas.CurrencyId
                                          WHERE     u.UserId IS NOT NULL
                                                    AND ( @CurrencyId IS NULL OR u.CurrencyId = @CurrencyId)
                                        ) AS r
                            ) AS p
                ) AS po
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DB_GetUserRefundDetails]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-11-10
-- Description:	Get Author refunds details for dashboard
-- =============================================
CREATE FUNCTION [dbo].[tvf_DB_GetUserRefundDetails]
(	
	@From DATE ,
    @To DATE ,
    @UserId INT ,   
    @CurrencyId SMALLINT,
	@StoreId INT = NULL ,
	@PaymentSource VARCHAR(10) = NULL,
	@LineTypeId TINYINT = NULL
)
RETURNS TABLE 
AS
RETURN 
(
		  SELECT  PaymentSource,
									PaymentId ,
									OrderLineId ,
									Amount ,
									Currency ,
									PaymentDate ,
									PaymentNumber ,									
									LineTypeId ,
									TransactionId ,
									ExternalTransactionID ,
									PaypalProfileID ,
									PaymentTypeId ,
									ItemName ,
									OrderNumber ,
									BuyerUserId ,
									BuyerEmail ,
									BuyerNickName ,
									BuyerFirstName ,
									BuyerLastName ,
									SellerUserId ,
									SellerEmail ,
									SellerNickName ,
									SellerFirstName ,
									SellerLastName ,
									WebStoreId ,
									TrackingID ,
									StoreName ,
									StoreOwnerUserId ,
									StoreOwnerEmail ,
									StoreOwnerNickname ,
									StoreOwnerFirstName ,
									StoreOwnerLastName ,
									OrderStatusId ,
									OrderStatusCode ,
									CourseId ,
									BundleId ,
									CouponInstanceId ,
									Price ,
									TotalPrice ,
									Discount ,
									SubscriptionMonths ,
									CouponTypeAmount ,
									Fee ,
									OrderDate ,
									CurrencyId ,
									ISO ,
									Symbol ,
									CurrencyName ,
									AffiliateCommission ,
									IsUnderRGP,
									RefundAmount, 
									RefundDate, 
									RefundId
		FROM(
							-- Author Refunds
							SELECT  'AS' AS PaymentSource,
									PaymentId ,
									OrderLineId ,
									Amount ,
									Currency ,
									PaymentDate ,
									PaymentNumber ,									
									LineTypeId ,
									TypeCode AS LineTypeCode,
									TransactionId ,
									ExternalTransactionID ,
									PaypalProfileID ,
									PaymentTypeId ,
									ItemName ,
									OrderNumber ,
									BuyerUserId ,
									BuyerEmail ,
									BuyerNickName ,
									BuyerFirstName ,
									BuyerLastName ,
									SellerUserId ,
									SellerEmail ,
									SellerNickName ,
									SellerFirstName ,
									SellerLastName ,
									WebStoreId ,
									TrackingID ,
									StoreName ,
									StoreOwnerUserId ,
									StoreOwnerEmail ,
									StoreOwnerNickname ,
									StoreOwnerFirstName ,
									StoreOwnerLastName ,
									OrderStatusId ,
									OrderStatusCode ,
									CourseId ,
									BundleId ,
									CouponInstanceId ,
									Price ,
									TotalPrice ,
									Discount ,
									SubscriptionMonths ,
									CouponTypeAmount ,
									Fee ,
									OrderDate ,
									CurrencyId ,
									ISO ,
									Symbol ,
									CurrencyName ,
									AffiliateCommission ,
									IsUnderRGP,
									RefundAmount, 
									RefundDate, 
									RefundId
							FROM    dbo.vw_SALE_OrderLinePaymentRefunds AS r
							WHERE   (( StoreOwnerUserId IS NULL ) OR ( StoreOwnerUserId = SellerUserId ))
									AND ( CAST(RefundDate  AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
									AND (SellerUserId = @UserId)
									AND (CurrencyId = @CurrencyId)
									AND (@StoreId IS NULL OR WebStoreId = @StoreId)
						
						UNION
								-- By Affiliate refunds
								SELECT  'BAFS' AS PaymentSource,
										PaymentId ,
										OrderLineId ,
										Amount ,
										Currency ,
										PaymentDate ,
										PaymentNumber ,
										LineTypeId ,
										TypeCode AS LineTypeCode,
										TransactionId ,
										ExternalTransactionID ,
										PaypalProfileID ,
										PaymentTypeId ,
										ItemName ,
										OrderNumber ,
										BuyerUserId ,
										BuyerEmail ,
										BuyerNickName ,
										BuyerFirstName ,
										BuyerLastName ,
										SellerUserId ,
										SellerEmail ,
										SellerNickName ,
										SellerFirstName ,
										SellerLastName ,
										WebStoreId ,
										TrackingID ,
										StoreName ,
										StoreOwnerUserId ,
										StoreOwnerEmail ,
										StoreOwnerNickname ,
										StoreOwnerFirstName ,
										StoreOwnerLastName ,
										OrderStatusId ,
										OrderStatusCode ,
										CourseId ,
										BundleId ,
										CouponInstanceId ,
										Price ,
										TotalPrice ,
										Discount ,
										SubscriptionMonths ,
										CouponTypeAmount ,
										Fee ,
										OrderDate ,
										CurrencyId ,
										ISO ,
										Symbol ,
										CurrencyName ,
										AffiliateCommission ,
										IsUnderRGP,
										RefundAmount, 
										RefundDate, 
										RefundId
								FROM    dbo.vw_SALE_OrderLinePaymentRefunds AS r
								WHERE   (( WebStoreId IS NOT NULL ) AND ( StoreOwnerUserId <> SellerUserId ))
										AND ( CAST(RefundDate  AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
										AND (SellerUserId = @UserId)
										AND (CurrencyId = @CurrencyId)
										AND (@StoreId IS NULL OR WebStoreId = @StoreId)
								
						UNION
							-- Affiliate Refunds
							SELECT  'AFS' AS PaymentSource,
									PaymentId ,
									OrderLineId ,
									Amount ,
									Currency ,
									PaymentDate ,
									PaymentNumber ,									
									LineTypeId ,
									TypeCode AS LineTypeCode,
									TransactionId ,
									ExternalTransactionID ,
									PaypalProfileID ,
									PaymentTypeId ,
									ItemName ,
									OrderNumber ,
									BuyerUserId ,
									BuyerEmail ,
									BuyerNickName ,
									BuyerFirstName ,
									BuyerLastName ,
									SellerUserId ,
									SellerEmail ,
									SellerNickName ,
									SellerFirstName ,
									SellerLastName ,
									WebStoreId ,
									TrackingID ,
									StoreName ,
									StoreOwnerUserId ,
									StoreOwnerEmail ,
									StoreOwnerNickname ,
									StoreOwnerFirstName ,
									StoreOwnerLastName ,
									OrderStatusId ,
									OrderStatusCode ,
									CourseId ,
									BundleId ,
									CouponInstanceId ,
									Price ,
									TotalPrice ,
									Discount ,
									SubscriptionMonths ,
									CouponTypeAmount ,
									Fee ,
									OrderDate ,
									CurrencyId ,
									ISO ,
									Symbol ,
									CurrencyName ,
									AffiliateCommission ,
									IsUnderRGP,
									RefundAmount, 
									RefundDate, 
									RefundId
							FROM    dbo.vw_SALE_OrderLinePaymentRefunds AS r
							WHERE   (( WebStoreId IS NOT NULL ) AND ( StoreOwnerUserId <> SellerUserId ))
									AND ( CAST(RefundDate  AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
									AND (StoreOwnerUserId = @UserId)
									AND (CurrencyId = @CurrencyId)
									AND (@StoreId IS NULL OR WebStoreId = @StoreId)
		) AS t
    WHERE (@PaymentSource IS NULL OR PaymentSource = @PaymentSource)  
		  AND (@LineTypeId IS NULL OR LineTypeId = @LineTypeId)  
					
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_SearchUsers]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-2-27
-- Description:	Search Users
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_SearchUsers]
(	
	 @UserId INT = NULL
	,@TypeId INT = NULL
	,@RegisterFrom DATETIME = NULL
	,@RegisterTo DATETIME = NULL
	,@LoginFrom DATETIME = NULL
	,@LoginTo DATETIME = NULL
	,@IsGRP BIT = 0
	,@RoleId INT = NULL
)
RETURNS TABLE 
AS
RETURN 
(

		SELECT [Id]
			  ,[UserId]
			  ,[Nickname]
			  ,[FirstName]
			  ,[LastName]
			  ,[FacebookID]
			  ,[BirthDate]
			  ,[Gender]
			  ,[IsConfirmed]
			  ,[ProviderUserId]
			  ,[Provider]
			  ,[Email]
			  ,[PictureURL]
			  ,[AuthorPictureURL]
			  ,[LastLogin]
			  ,[StatusType]
			  ,[RegisterDate]
			  ,[RegistrationTypeId]
			  ,[RegistrationTypeCode]
			  ,[courses]
			  ,[bundles]
			  ,[chapters]
			  ,[videos]
			  ,[logins]
			  ,[purchases]
			  ,[stores]
			  ,[RegisterStoreId]
			  ,[RegisterStoreName]
			  ,[PayoutTypeId]
			  ,[PayoutTypeCode]
			  ,[PayoutAddressID]
			  ,[PaypalEmail]
			  ,[Created]
			  ,[RegisterHostName]
			  ,[JoinedToRefundProgram]
			  ,[ProvisionUid]
			FROM [dbo].[vw_USER_UserLogins] AS u
			WHERE (@UserId IS NULL OR UserId = @UserId)			
				AND (@TypeId IS NULL OR RegistrationTypeId = @TypeId)
				AND (@LoginFrom IS NULL OR LastLogin >= @LoginFrom)
				AND (@LoginTo IS NULL OR LastLogin <= @LoginTo)
				AND (@RegisterFrom IS NULL OR RegisterDate >= @RegisterFrom)
				AND (@RegisterTo IS NULL OR RegisterDate <= @RegisterTo)
				AND (@IsGRP = 0 OR JoinedToRefundProgram = 1)
				AND (@RoleId IS NULL OR EXISTS (SELECT 1 FROM dbo.webpages_UsersInRoles WHERE RoleId = @RoleId AND UserId = u.Id))
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_GetDailyUserLogins]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-4-8
-- Description:	Get daily user login statistic
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_GetDailyUserLogins]
(	
	@LoginDate DATE,
	@Returned BIT
)
RETURNS TABLE 
AS
RETURN 
(

		SELECT ul.Id
			  ,ul.UserId
			  ,ul.Nickname
			  ,ul.FirstName
			  ,ul.LastName
			  ,ul.FacebookID
			  ,ul.BirthDate
			  ,ul.Gender
			  ,ul.IsConfirmed
			  ,ul.ProviderUserId
			  ,ul.Provider
			  ,ul.Email
			  ,ul.PictureURL
			  ,ul.AuthorPictureURL
			  ,ul.LastLogin
			  ,ul.StatusType
			  ,ul.RegisterDate
			  ,ul.RegistrationTypeId
			  ,ul.RegistrationTypeCode
			  ,ul.courses
			  ,ul.bundles
			  ,ul.chapters
			  ,ul.videos
			  ,ul.logins
			  ,ul.purchases
			  ,ul.stores
			  ,ul.RegisterStoreId
			  ,ul.RegisterStoreName
			  ,ul.PayoutTypeId
			  ,ul.PayoutTypeCode
			  ,ul.PayoutAddressID
			  ,ul.PaypalEmail
			  ,ul.Created
			  ,ul.RegisterHostName
			  ,ul.JoinedToRefundProgram
			  ,ul.ProvisionUid
		  FROM [dbo].[vw_USER_UserLogins] AS ul
					INNER JOIN ( SELECT DISTINCT
										us.UserID
								 FROM   dbo.UserSessions AS us
								 WHERE  ( CAST(us.EventDate AS DATE) = CAST(@LoginDate AS DATE) )
							   ) AS l ON l.UserID = ul.UserId
			WHERE (@Returned = 0 OR (ul.Created < @LoginDate))
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_GetDailyAuthorLogins]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-4-8
-- Description:	Get daily author login statistic
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_GetDailyAuthorLogins]
(	
	@LoginDate DATE
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT  Id ,
			a.UserId ,
			Nickname ,
			FirstName ,
			LastName ,
			FacebookID ,
			BirthDate ,
			Gender ,
			IsConfirmed ,
			ProviderUserId ,
			Provider ,
			Email ,
			PictureURL ,
			AuthorPictureURL ,
			LastLogin ,
			StatusType ,
			RegisterDate ,
			RegistrationTypeId ,
			RegistrationTypeCode ,
			RegisterStoreId ,
			RegisterStoreName ,
			RegisterHostName ,
			PayoutAddressID ,
			PayoutTypeId ,
			PayoutTypeCode ,
			PaypalEmail ,
			courses ,
			bundles ,
			chapters ,
			videos ,
			logins ,
			purchases ,
			stores ,
			Created,
			JoinedToRefundProgram,
			ProvisionUid
FROM    ( SELECT    u.Id ,
                    u.UserId ,
                    u.Email ,                    
                    u.FirstName ,
					u.LastName ,
					u.Nickname,
					u.FacebookID ,
					u.BirthDate ,
					u.Gender ,
					u.IsConfirmed ,
					u.ProviderUserId ,
					u.Provider ,
					u.PictureURL ,
					u.AuthorPictureURL ,
					u.LastLogin ,
					u.StatusType ,
					u.RegisterDate ,
					u.RegistrationTypeId ,
					u.RegistrationTypeCode ,
					u.RegisterStoreId ,
					u.RegisterStoreName ,
					u.RegisterHostName,
					u.PayoutAddressID ,
					u.PayoutTypeId ,
					u.PayoutTypeCode ,
					u.PaypalEmail ,
					u.courses ,
					u.bundles ,
					u.chapters ,
					u.videos ,
					u.logins ,
					u.purchases ,
					u.stores ,
					u.Created,
					u.ProvisionUid,
					CAST(CASE RegistrationTypeCode
                           WHEN 'WIX' THEN 1
                           ELSE CASE ISNULL(b.bundles, 0) + ISNULL(c.courses,0) + ISNULL(s.stores, 0)
                                  WHEN 0 THEN 0
                                  ELSE 1
                                END
                         END AS BIT) AS IsAuthor 
					,u.JoinedToRefundProgram
          FROM      dbo.vw_USER_UserLogins AS u
                    LEFT OUTER JOIN ( SELECT    COUNT(BundleId) AS bundles ,
                                                AuthorId
                                      FROM      dbo.CRS_Bundles
                                      GROUP BY  AuthorId
                                    ) AS b ON b.AuthorId = u.UserId
                    LEFT OUTER JOIN ( SELECT    COUNT(StoreID) AS stores ,
                                                OwnerUserID
                                      FROM      dbo.WebStores AS ws
                                      GROUP BY  OwnerUserID
                                    ) AS s ON s.OwnerUserID = u.UserId
                    LEFT OUTER JOIN ( SELECT    COUNT(Id) AS courses ,
                                                AuthorUserId
                                      FROM      dbo.Courses
                                      GROUP BY  AuthorUserId
                                    ) AS c ON c.AuthorUserId = u.UserId
        ) AS a
		INNER JOIN ( SELECT DISTINCT
								us.UserID
						 FROM   dbo.UserSessions AS us
						 WHERE  ( CAST(us.EventDate AS DATE) = CAST(@LoginDate AS DATE) )
					   ) AS l ON l.UserID = a.UserId
	WHERE   ( IsAuthor = 1 )		
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_SALE_SearchOrderLines]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-12-25
-- Description:	Get transactions for Portal Admin report
-- =============================================
CREATE FUNCTION [dbo].[tvf_SALE_SearchOrderLines]
(	
	 @from			DATETIME 
	,@to			DATETIME
	,@SellerUserId	INT			= NULL
	,@BuyerUserId	INT			= NULL
	,@OwnerUserId	INT			= NULL
	,@CourseId		INT			= NULL
	,@BundleId		INT			= NULL
	,@StoreId		INT			= NULL
	,@LineTypeId	TINYINT		= NULL	
)
RETURNS TABLE 
AS
RETURN 
(

		SELECT [OrderId]
			  ,[LineId]
			  ,[OrderNumber]
			  ,[SellerUserId]
			  ,[SellerEmail]
			  ,[SellerNickName]
			  ,[SellerFirstName]
			  ,[SellerLastName]
			  ,[BuyerUserId]
			  ,[BuyerEmail]
			  ,[BuyerNickName]
			  ,[BuyerFirstName]
			  ,[BuyerLastName]
			  ,[WebStoreId]
			  ,[TrackingID]
			  ,[StoreName]
			  ,[OrderStatusCode]
			  ,[OrderStatusId]
			  ,[PaymentMethodId]
			  ,[PaymentMethodCode]
			  ,[OrderDate]
			  ,[LineTypeId]
			  ,[LineTypeCode]
			  ,[PaymentTermId]
			  ,[PaymentTermCode]
			  ,[ItemName]
			  ,[Price]
			  ,[Discount]
			  ,[TotalPrice]
			  ,[TotalAmountPayed]
			  ,[PaypalProfileID]
			  ,[Description]
			  ,[StoreOwnerUserId]
			  ,[StoreOwnerEmail]
			  ,[StoreOwnerNickname]
			  ,[StoreOwnerFirstName]
			  ,[StoreOwnerLastName]
			  ,[CourseId]
			  ,[BundleId]
			  ,[TotalRefunded]
			  ,[CouponInstanceId]
			  ,[CouponCode]
			  ,[CouponTypeAmount]
			  ,[CouponTypeId]
			  ,[AddressId]
			  ,[InstrumentId]
			  ,[CreditCardType]
			  ,[DisplayName]
			  ,[PriceLineId]
			  ,[CurrencyId]
			  ,[ISO]
			  ,[Symbol]
			  ,[CurrencyName]
			  ,[SellerFacebookID]
			  ,[BuyerFacebookID]
			  ,[IsUnderRGP]
			  ,[AffiliateCommission]
			  ,[CancelledOn]
 	  FROM [dbo].[vw_SALE_OrderLines]
	  WHERE (OrderDate BETWEEN @from  AND @to)
			AND (@SellerUserId IS NULL OR SellerUserId = @SellerUserId)
			AND (@BuyerUserId IS NULL OR BuyerUserId = @BuyerUserId)
			AND (@CourseId IS NULL OR (CourseId IS NOT NULL AND CourseId = @CourseId))
			AND (@BundleId IS NULL OR (BundleId IS NOT NULL AND BundleId = @BundleId))
			AND (@OwnerUserId IS NULL OR StoreOwnerUserId = @OwnerUserId )
			AND (@StoreId IS NULL OR WebStoreId = @StoreId)
			AND (@LineTypeId IS NULL OR LineTypeId = @LineTypeId)
	 
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DB_GetUserCouponUsageDetails]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-11-10
-- Description:	Get Author sales details for dashboard
-- =============================================
CREATE FUNCTION [dbo].[tvf_DB_GetUserCouponUsageDetails]
    (
      @From DATE ,
      @To DATE ,
      @UserId INT ,
      @CurrencyId SMALLINT ,
      @StoreId INT = NULL ,
      @PaymentSource VARCHAR(10) = NULL ,
      @LineTypeId TINYINT = NULL
    )
RETURNS TABLE
AS
RETURN
    ( 
		SELECT  PaymentSource ,
				LineId ,
				TotalRefunded ,
				LineTypeId ,
				LineTypeCode ,
				PaypalProfileID ,
				ItemName ,
				OrderNumber ,
				BuyerUserId ,
				BuyerEmail ,
				BuyerNickName ,
				BuyerFirstName ,
				BuyerLastName ,
				SellerUserId ,
				SellerEmail ,
				SellerNickName ,
				SellerFirstName ,
				SellerLastName ,
				WebStoreId ,
				TrackingID ,
				StoreName ,
				StoreOwnerUserId ,
				StoreOwnerEmail ,
				StoreOwnerNickname ,
				StoreOwnerFirstName ,
				StoreOwnerLastName ,
				OrderStatusId ,
				OrderStatusCode ,
				CourseId ,
				BundleId ,
				CouponInstanceId ,
				CouponTypeId ,
				Price ,
				TotalPrice ,
				Discount ,
				CouponTypeAmount ,
				OrderDate ,
				ISNULL(CurrencyId ,2) AS CurrencyId,
				ISO ,
				Symbol ,
				CurrencyName ,
				AffiliateCommission ,
				IsUnderRGP ,
				TotalAmountPayed
      FROM      (
		-- Author Sales
                  SELECT    'AS' AS PaymentSource ,
                            LineId ,
							TotalRefunded ,
							LineTypeId ,
							LineTypeCode ,
							PaypalProfileID ,
							ItemName ,
							OrderNumber ,
							BuyerUserId ,
							BuyerEmail ,
							BuyerNickName ,
							BuyerFirstName ,
							BuyerLastName ,
							SellerUserId ,
							SellerEmail ,
							SellerNickName ,
							SellerFirstName ,
							SellerLastName ,
							WebStoreId ,
							TrackingID ,
							StoreName ,
							StoreOwnerUserId ,
							StoreOwnerEmail ,
							StoreOwnerNickname ,
							StoreOwnerFirstName ,
							StoreOwnerLastName ,
							OrderStatusId ,
							OrderStatusCode ,
							CourseId ,
							BundleId ,
							CouponInstanceId ,
							CouponTypeId ,
							Price ,
							TotalPrice ,
							Discount ,
							CouponTypeAmount ,
							OrderDate ,
							CurrencyId ,
							ISO ,
							Symbol ,
							CurrencyName ,
							AffiliateCommission ,
							IsUnderRGP ,
							TotalAmountPayed
                 FROM    dbo.vw_SALE_OrderLines
						 WHERE   ( StoreOwnerUserId IS NULL OR StoreOwnerUserId = SellerUserId)
								AND ( CAST(OrderDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
								AND ( SellerUserId = @UserId )
								AND ( CouponInstanceId IS NOT NULL )
								AND (ISNULL(CurrencyId,2) = @CurrencyId)
								AND (@StoreId IS NULL OR WebStoreId = @StoreId)
                  UNION
		-- Sales By Affiliate
                  SELECT    'BAFS' AS PaymentSource ,
                            LineId ,
							TotalRefunded ,
							LineTypeId ,
							LineTypeCode ,
							PaypalProfileID ,
							ItemName ,
							OrderNumber ,
							BuyerUserId ,
							BuyerEmail ,
							BuyerNickName ,
							BuyerFirstName ,
							BuyerLastName ,
							SellerUserId ,
							SellerEmail ,
							SellerNickName ,
							SellerFirstName ,
							SellerLastName ,
							WebStoreId ,
							TrackingID ,
							StoreName ,
							StoreOwnerUserId ,
							StoreOwnerEmail ,
							StoreOwnerNickname ,
							StoreOwnerFirstName ,
							StoreOwnerLastName ,
							OrderStatusId ,
							OrderStatusCode ,
							CourseId ,
							BundleId ,
							CouponInstanceId ,
							CouponTypeId ,
							Price ,
							TotalPrice ,
							Discount ,
							CouponTypeAmount ,
							OrderDate ,
							CurrencyId ,
							ISO ,
							Symbol ,
							CurrencyName ,
							AffiliateCommission ,
							IsUnderRGP ,
							TotalAmountPayed
                 FROM    dbo.vw_SALE_OrderLines
				WHERE   ( CAST(OrderDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
						AND ( WebStoreId IS NOT NULL )
						AND ( StoreOwnerUserId <> SellerUserId )
						AND (SellerUserId = @UserId)
						AND ( CouponInstanceId IS NOT NULL )
						AND (ISNULL(CurrencyId,2) = @CurrencyId)
						AND (@StoreId IS NULL OR WebStoreId = @StoreId)
                  UNION
			--Affiliate sales
                  SELECT    'AFS' AS PaymentSource ,
                            LineId ,
							TotalRefunded ,
							LineTypeId ,
							LineTypeCode ,
							PaypalProfileID ,
							ItemName ,
							OrderNumber ,
							BuyerUserId ,
							BuyerEmail ,
							BuyerNickName ,
							BuyerFirstName ,
							BuyerLastName ,
							SellerUserId ,
							SellerEmail ,
							SellerNickName ,
							SellerFirstName ,
							SellerLastName ,
							WebStoreId ,
							TrackingID ,
							StoreName ,
							StoreOwnerUserId ,
							StoreOwnerEmail ,
							StoreOwnerNickname ,
							StoreOwnerFirstName ,
							StoreOwnerLastName ,
							OrderStatusId ,
							OrderStatusCode ,
							CourseId ,
							BundleId ,
							CouponInstanceId ,
							CouponTypeId ,
							Price ,
							TotalPrice ,
							Discount ,
							CouponTypeAmount ,
							OrderDate ,
							CurrencyId ,
							ISO ,
							Symbol ,
							CurrencyName ,
							AffiliateCommission ,
							IsUnderRGP ,
							TotalAmountPayed
            FROM    dbo.vw_SALE_OrderLines
			WHERE   ( CAST(OrderDate AS DATE) BETWEEN CAST(@From AS DATE) AND  CAST(@To AS DATE) ) 
					AND (WebStoreId IS NOT NULL )
					AND (StoreOwnerUserId <> SellerUserId )
					AND (StoreOwnerUserId = @UserId)
					AND ( CouponInstanceId IS NOT NULL )
					AND (ISNULL(CurrencyId,2) = @CurrencyId)
					AND (@StoreId IS NULL OR WebStoreId = @StoreId)
                ) AS t
      WHERE     ( @PaymentSource IS NULL
                  OR PaymentSource = @PaymentSource
                )
                AND ( @LineTypeId IS NULL
                      OR LineTypeId = @LineTypeId
                    )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DB_GetUserSubscriptionsCancelDetails]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-11-10
-- Description:	Get Author subscriptions cancel details for dashboard
-- =============================================
CREATE FUNCTION [dbo].[tvf_DB_GetUserSubscriptionsCancelDetails]
(	
	@From DATE ,
    @To DATE ,
    @UserId INT ,   
    @CurrencyId SMALLINT,
	@StoreId INT = NULL ,
	@PaymentSource VARCHAR(10) = NULL,
	@LineTypeId TINYINT = NULL
)
RETURNS TABLE 
AS
RETURN 
(
		    SELECT  PaymentSource ,
            CancelledOn ,
            LineId ,
            LineTypeId ,
            LineTypeCode ,
            PaypalProfileID ,
            ItemName ,
            OrderNumber ,
            BuyerUserId ,
            BuyerEmail ,
            BuyerNickName ,
            BuyerFirstName ,
            BuyerLastName ,
            SellerUserId ,
            SellerEmail ,
            SellerNickName ,
            SellerFirstName ,
            SellerLastName ,
            WebStoreId ,
            TrackingID ,
            StoreName ,
            StoreOwnerUserId ,
            StoreOwnerEmail ,
            StoreOwnerNickname ,
            StoreOwnerFirstName ,
            StoreOwnerLastName ,
            OrderStatusId ,
            OrderStatusCode ,
            CourseId ,
            BundleId ,
            CouponInstanceId ,
            Price ,
            TotalPrice ,
            Discount ,
			TotalAmountPayed,
            CouponTypeAmount ,
            OrderDate ,
            CurrencyId ,
            ISO ,
            Symbol ,
            CurrencyName ,
            AffiliateCommission ,
            IsUnderRGP
    FROM    (
						-- Author subscription cancellations
              SELECT    'AS' AS PaymentSource ,
                        ac.CancelledOn ,
                        ac.LineId ,
                        ac.LineTypeId ,
                        ac.LineTypeCode ,
                        ac.PaypalProfileID ,
                        ac.ItemName ,
                        ac.OrderNumber ,
                        ac.BuyerUserId ,
                        ac.BuyerEmail ,
                        ac.BuyerNickName ,
                        ac.BuyerFirstName ,
                        ac.BuyerLastName ,
                        ac.SellerUserId ,
                        ac.SellerEmail ,
                        ac.SellerNickName ,
                        ac.SellerFirstName ,
                        ac.SellerLastName ,
                        ac.WebStoreId ,
                        ac.TrackingID ,
                        ac.StoreName ,
                        ac.StoreOwnerUserId ,
                        ac.StoreOwnerEmail ,
                        ac.StoreOwnerNickname ,
                        ac.StoreOwnerFirstName ,
                        ac.StoreOwnerLastName ,
                        ac.OrderStatusId ,
                        ac.OrderStatusCode ,
                        ac.CourseId ,
                        ac.BundleId ,
                        ac.CouponInstanceId ,
                        ac.Price ,
                        ac.TotalPrice ,
                        ac.Discount ,
						ac.TotalAmountPayed,
                        ac.CouponTypeAmount ,
                        ac.OrderDate ,
                        ac.CurrencyId ,
                        ac.ISO ,
                        ac.Symbol ,
                        ac.CurrencyName ,
                        ac.AffiliateCommission ,
                        ac.IsUnderRGP
              FROM      ( SELECT    ISNULL(sl.CancelledOn,
                                           DATEFROMPARTS(DATEPART(year,
                                                              p.LastPaymentDate),
                                                         DATEPART(month,
                                                              p.LastPaymentDate),
                                                         2)) AS CancelledOn ,
                                    sl.LineId ,
                                    sl.LineTypeId ,
                                    sl.LineTypeCode ,
                                    sl.PaypalProfileID ,
                                    sl.ItemName ,
                                    sl.OrderNumber ,
                                    sl.BuyerUserId ,
                                    sl.BuyerEmail ,
                                    sl.BuyerNickName ,
                                    sl.BuyerFirstName ,
                                    sl.BuyerLastName ,
                                    sl.SellerUserId ,
                                    sl.SellerEmail ,
                                    sl.SellerNickName ,
                                    sl.SellerFirstName ,
                                    sl.SellerLastName ,
                                    sl.WebStoreId ,
                                    sl.TrackingID ,
                                    sl.StoreName ,
                                    sl.StoreOwnerUserId ,
                                    sl.StoreOwnerEmail ,
                                    sl.StoreOwnerNickname ,
                                    sl.StoreOwnerFirstName ,
                                    sl.StoreOwnerLastName ,
                                    sl.OrderStatusId ,
                                    sl.OrderStatusCode ,
                                    sl.CourseId ,
                                    sl.BundleId ,
                                    sl.CouponInstanceId ,
                                    sl.Price ,
                                    sl.TotalPrice ,
                                    sl.Discount ,
									sl.TotalAmountPayed,
                                    sl.CouponTypeAmount ,
                                    sl.OrderDate ,
                                    sl.CurrencyId ,
                                    sl.ISO ,
                                    sl.Symbol ,
                                    sl.CurrencyName ,
                                    sl.AffiliateCommission ,
                                    sl.IsUnderRGP
                          FROM      dbo.vw_SALE_OrderLines AS sl
                                    INNER JOIN ( SELECT MAX(lp.PaymentDate) AS LastPaymentDate ,
                                                        lp.OrderLineId
                                                 FROM   dbo.SALE_OrderLinePayments
                                                        AS lp
                                                        INNER JOIN dbo.SALE_PaymentStatusesLOV
                                                        AS ps ON lp.StatusId = ps.StatusId
                                                 WHERE  ( ps.StatusCode = 'COMPLETED' )
                                                 GROUP BY lp.OrderLineId
                                               ) AS p ON sl.LineId = p.OrderLineId
                          WHERE     ( sl.OrderStatusCode = 'CANCELED'  OR sl.OrderStatusCode='SUSPENDED')
                                    AND ( sl.LineTypeCode = 'SUBSCRIPTION' )
                                    AND ( sl.StoreOwnerUserId IS NULL
                                          OR sl.StoreOwnerUserId = sl.SellerUserId
                                        )
                                    AND ( sl.SellerUserId = @UserId )
                                    AND ( ISNULL(sl.CurrencyId,2) = @CurrencyId )
                                    AND ( @StoreId IS NULL
                                          OR WebStoreId = @StoreId
                                        )
                        ) AS ac
              WHERE     ( CAST(CancelledOn AS DATE) BETWEEN CAST(@From AS DATE)
                                                    AND     CAST(@To AS DATE) )
              UNION

								-- By Affiliate subscription cancellations
              SELECT    'BAFS' AS PaymentSource ,
                        bafc.CancelledOn ,
                        bafc.LineId ,
                        bafc.LineTypeId ,
                        bafc.LineTypeCode ,
                        bafc.PaypalProfileID ,
                        bafc.ItemName ,
                        bafc.OrderNumber ,
                        bafc.BuyerUserId ,
                        bafc.BuyerEmail ,
                        bafc.BuyerNickName ,
                        bafc.BuyerFirstName ,
                        bafc.BuyerLastName ,
                        bafc.SellerUserId ,
                        bafc.SellerEmail ,
                        bafc.SellerNickName ,
                        bafc.SellerFirstName ,
                        bafc.SellerLastName ,
                        bafc.WebStoreId ,
                        bafc.TrackingID ,
                        bafc.StoreName ,
                        bafc.StoreOwnerUserId ,
                        bafc.StoreOwnerEmail ,
                        bafc.StoreOwnerNickname ,
                        bafc.StoreOwnerFirstName ,
                        bafc.StoreOwnerLastName ,
                        bafc.OrderStatusId ,
                        bafc.OrderStatusCode ,
                        bafc.CourseId ,
                        bafc.BundleId ,
                        bafc.CouponInstanceId ,
                        bafc.Price ,
                        bafc.TotalPrice ,
                        bafc.Discount ,									
						bafc.TotalAmountPayed,
                        bafc.CouponTypeAmount ,
                        bafc.OrderDate ,
                        bafc.CurrencyId ,
                        bafc.ISO ,
                        bafc.Symbol ,
                        bafc.CurrencyName ,
                        bafc.AffiliateCommission ,
                        bafc.IsUnderRGP
              FROM      ( SELECT    ISNULL(sl.CancelledOn,
                                           DATEFROMPARTS(DATEPART(year,
                                                              p.LastPaymentDate),
                                                         DATEPART(month,
                                                              p.LastPaymentDate),
                                                         2)) AS CancelledOn ,
                                    sl.LineId ,
                                    sl.LineTypeId ,
                                    sl.LineTypeCode ,
                                    sl.PaypalProfileID ,
                                    sl.ItemName ,
                                    sl.OrderNumber ,
                                    sl.BuyerUserId ,
                                    sl.BuyerEmail ,
                                    sl.BuyerNickName ,
                                    sl.BuyerFirstName ,
                                    sl.BuyerLastName ,
                                    sl.SellerUserId ,
                                    sl.SellerEmail ,
                                    sl.SellerNickName ,
                                    sl.SellerFirstName ,
                                    sl.SellerLastName ,
                                    sl.WebStoreId ,
                                    sl.TrackingID ,
                                    sl.StoreName ,
                                    sl.StoreOwnerUserId ,
                                    sl.StoreOwnerEmail ,
                                    sl.StoreOwnerNickname ,
                                    sl.StoreOwnerFirstName ,
                                    sl.StoreOwnerLastName ,
                                    sl.OrderStatusId ,
                                    sl.OrderStatusCode ,
                                    sl.CourseId ,
                                    sl.BundleId ,
                                    sl.CouponInstanceId ,
                                    sl.Price ,
                                    sl.TotalPrice ,
                                    sl.Discount ,
									sl.TotalAmountPayed,
                                    sl.CouponTypeAmount ,
                                    sl.OrderDate ,
                                    sl.CurrencyId ,
                                    sl.ISO ,
                                    sl.Symbol ,
                                    sl.CurrencyName ,
                                    sl.AffiliateCommission ,
                                    sl.IsUnderRGP
                          FROM      dbo.vw_SALE_OrderLines AS sl
                                    INNER JOIN ( SELECT MAX(lp.PaymentDate) AS LastPaymentDate ,
                                                        lp.OrderLineId
                                                 FROM   dbo.SALE_OrderLinePayments
                                                        AS lp
                                                        INNER JOIN dbo.SALE_PaymentStatusesLOV
                                                        AS ps ON lp.StatusId = ps.StatusId
                                                 WHERE  ( ps.StatusCode = 'COMPLETED' )
                                                 GROUP BY lp.OrderLineId
                                               ) AS p ON sl.LineId = p.OrderLineId
                          WHERE     ( sl.OrderStatusCode = 'CANCELED' OR sl.OrderStatusCode='SUSPENDED')
                                    AND ( sl.LineTypeCode = 'SUBSCRIPTION' )
                                    AND ( WebStoreId IS NOT NULL )
                                    AND ( sl.StoreOwnerUserId <> sl.SellerUserId )
                                    AND ( sl.SellerUserId = @UserId )
                                    AND ( ISNULL(sl.CurrencyId,2) = @CurrencyId )
                                    AND ( @StoreId IS NULL
                                          OR WebStoreId = @StoreId
                                        )
                        ) AS bafc
              WHERE     ( CAST(CancelledOn AS DATE) BETWEEN CAST(@From AS DATE)
                                                    AND     CAST(@To AS DATE) )
              UNION

									-- Affiliate subscription cancellations
              SELECT    'AFS' AS PaymentSource ,
                        afc.CancelledOn ,
                        afc.LineId ,
                        afc.LineTypeId ,
                        afc.LineTypeCode ,
                        afc.PaypalProfileID ,
                        afc.ItemName ,
                        afc.OrderNumber ,
                        afc.BuyerUserId ,
                        afc.BuyerEmail ,
                        afc.BuyerNickName ,
                        afc.BuyerFirstName ,
                        afc.BuyerLastName ,
                        afc.SellerUserId ,
                        afc.SellerEmail ,
                        afc.SellerNickName ,
                        afc.SellerFirstName ,
                        afc.SellerLastName ,
                        afc.WebStoreId ,
                        afc.TrackingID ,
                        afc.StoreName ,
                        afc.StoreOwnerUserId ,
                        afc.StoreOwnerEmail ,
                        afc.StoreOwnerNickname ,
                        afc.StoreOwnerFirstName ,
                        afc.StoreOwnerLastName ,
                        afc.OrderStatusId ,
                        afc.OrderStatusCode ,
                        afc.CourseId ,
                        afc.BundleId ,
                        afc.CouponInstanceId ,
                        afc.Price ,
                        afc.TotalPrice ,
                        afc.Discount ,
						afc.TotalAmountPayed,
                        afc.CouponTypeAmount ,
                        afc.OrderDate ,
                        afc.CurrencyId ,
                        afc.ISO ,
                        afc.Symbol ,
                        afc.CurrencyName ,
                        afc.AffiliateCommission ,
                        afc.IsUnderRGP
              FROM      ( SELECT    ISNULL(sl.CancelledOn,
                                           DATEFROMPARTS(DATEPART(year,
                                                              p.LastPaymentDate),
                                                         DATEPART(month,
                                                              p.LastPaymentDate),
                                                         2)) AS CancelledOn ,
                                    sl.LineId ,
                                    sl.LineTypeId ,
                                    sl.LineTypeCode ,
                                    sl.PaypalProfileID ,
                                    sl.ItemName ,
                                    sl.OrderNumber ,
                                    sl.BuyerUserId ,
                                    sl.BuyerEmail ,
                                    sl.BuyerNickName ,
                                    sl.BuyerFirstName ,
                                    sl.BuyerLastName ,
                                    sl.SellerUserId ,
                                    sl.SellerEmail ,
                                    sl.SellerNickName ,
                                    sl.SellerFirstName ,
                                    sl.SellerLastName ,
                                    sl.WebStoreId ,
                                    sl.TrackingID ,
                                    sl.StoreName ,
                                    sl.StoreOwnerUserId ,
                                    sl.StoreOwnerEmail ,
                                    sl.StoreOwnerNickname ,
                                    sl.StoreOwnerFirstName ,
                                    sl.StoreOwnerLastName ,
                                    sl.OrderStatusId ,
                                    sl.OrderStatusCode ,
                                    sl.CourseId ,
                                    sl.BundleId ,
                                    sl.CouponInstanceId ,
                                    sl.Price ,
                                    sl.TotalPrice ,
                                    sl.Discount ,
									sl.TotalAmountPayed,
                                    sl.CouponTypeAmount ,
                                    sl.OrderDate ,
                                    sl.CurrencyId ,
                                    sl.ISO ,
                                    sl.Symbol ,
                                    sl.CurrencyName ,
                                    sl.AffiliateCommission ,
                                    sl.IsUnderRGP
                          FROM      dbo.vw_SALE_OrderLines AS sl
                                    INNER JOIN ( SELECT MAX(lp.PaymentDate) AS LastPaymentDate ,
                                                        lp.OrderLineId
                                                 FROM   dbo.SALE_OrderLinePayments
                                                        AS lp
                                                        INNER JOIN dbo.SALE_PaymentStatusesLOV
                                                        AS ps ON lp.StatusId = ps.StatusId
                                                 WHERE  ( ps.StatusCode = 'COMPLETED' )
                                                 GROUP BY lp.OrderLineId
                                               ) AS p ON sl.LineId = p.OrderLineId
                          WHERE     ( sl.OrderStatusCode = 'CANCELED' OR sl.OrderStatusCode='SUSPENDED' )
                                    AND ( sl.LineTypeCode = 'SUBSCRIPTION' )
                                    AND ( WebStoreId IS NOT NULL )
                                    AND ( sl.StoreOwnerUserId <> sl.SellerUserId )
                                    AND ( sl.StoreOwnerUserId = @UserId )
                                    AND ( ISNULL(sl.CurrencyId,2) = @CurrencyId )
                                    AND ( @StoreId IS NULL
                                          OR WebStoreId = @StoreId
                                        )
                        ) AS afc
              WHERE     ( CAST(CancelledOn AS DATE) BETWEEN CAST(@From AS DATE)
                                                    AND     CAST(@To AS DATE) )
            ) AS t
    WHERE   ( @PaymentSource IS NULL
              OR PaymentSource = @PaymentSource
            )
            AND ( @LineTypeId IS NULL
                  OR LineTypeId = @LineTypeId
                )  
					
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_SALE_GetSellerSalesStatistic]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-1-14
-- Description:	bring sales statistic by date for dahsboard/reports and e.t.c.
-- =============================================
CREATE FUNCTION [dbo].[tvf_SALE_GetSellerSalesStatistic]
(	
	@from DATETIME, 
	@to DATETIME,
	@AuthorId INT = NULL
)
RETURNS TABLE 
AS
RETURN 
(
		SELECT  COUNT([LineId]) TotalTrx ,				
				COUNT(DISTINCT([BuyerUserId])) TotalLearner,
				ISNULL(SUM([TotalAmountPayed]), 0)  AS TotalTrxAmount
		FROM    dbo.vw_SALE_OrderLines
		WHERE   ([OrderDate] BETWEEN @from AND @to)
				AND ( @AuthorId IS NULL OR [SellerUserId] = @AuthorId)
				AND (LineTypeCode='SALE' OR LineTypeCode='SUBSCRIPTION')
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_DASH_GetLearnerPeriodCouponStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-21
-- Description:	Get learner period coupon stats
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_DASH_GetLearnerPeriodCouponStats] (@CurrencyId SMALLINT, @From DATE, @To DATE )
RETURNS TABLE
AS
RETURN
( 
		SELECT      CurrencyId, 
					ISNULL(SUM(Discount),0) AS TotalDiscount,
					ISNULL(COUNT(DISTINCT OrderNumber),0) AS TotalCouponsClaimed
		FROM        vw_SALE_OrderLines
		WHERE       (CouponInstanceId IS NOT NULL)
					AND (CAST(OrderDate AS DATE) >= CAST(@From AS DATE) AND CAST(OrderDate AS DATE) <= CAST(@To AS DATE))
					AND (Discount IS NOT NULL AND Discount > 0)
					AND (CurrencyId = @CurrencyId)
		GROUP BY CurrencyId
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_DASH_GetPeriodSalesStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-18
-- Description:	Get sales stats for admin dashboard
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_DASH_GetPeriodSalesStats]
    (
      @CurrencyId SMALLINT ,
      @From DATE ,
      @To DATE
    )
RETURNS TABLE
AS
RETURN
    ( SELECT    ISNULL(COUNT(DISTINCT ( (CASE WHEN LineTypeCode = 'SALE'
                                              THEN OrderId
                                         END) )), 0) AS total_onetime_qty ,
                ISNULL(COUNT(DISTINCT ( (CASE WHEN LineTypeCode = 'SUBSCRIPTION'
                                              THEN OrderId
                                         END) )), 0) AS total_subscription_qty ,
                ISNULL(COUNT(DISTINCT ( (CASE WHEN LineTypeCode = 'RENTAL'
                                              THEN OrderId
                                         END) )), 0) AS total_rental_qty ,
                ISNULL(COUNT(DISTINCT ( (CASE WHEN LineTypeCode = 'FREE'
                                              THEN OrderId
                                         END) )), 0) AS total_free_qty ,
				ISNULL(COUNT(DISTINCT ( (CASE WHEN IsUnderRGP = 1
                                              THEN OrderId
                                         END) )), 0) AS total_mbg_qty ,
                CurrencyId
      FROM      dbo.vw_SALE_OrderLines
      WHERE     ( CAST(OrderDate AS DATE) BETWEEN CAST(@From AS DATE)
                                          AND     CAST(@To AS DATE) )
                AND ( CurrencyId = @CurrencyId )
      GROUP BY  CurrencyId
    )

GO
/****** Object:  View [dbo].[vw_FACT_DASH_Authors]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_FACT_DASH_Authors]
AS
SELECT        c.AuthorUserId AS AuthorId, c.Created AS AddOn,'COURSE' AS Type
FROM            dbo.Courses AS c
UNION
SELECT        b.AuthorId, b.AddOn, 'BUNDLE' AS Type
FROM            dbo.CRS_Bundles AS b

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_DASH_GetAuthorTotalStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-21
-- Description:	Get author totals stats
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_DASH_GetAuthorTotalStats] ( )
RETURNS TABLE
AS
RETURN
    ( 
	
		SELECT    ISNULL(ac.AverageCourseChapters,0) AS AverageCourseChapters,
				 ISNULL(acpa.AverageCoursesPerAuthor,0) AS AverageCoursesPerAuthor,
				 ISNULL(abpa.AverageBundlesPerAuthor,0) AS AverageBundlesPerAuthor,
				 ISNULL(free.TotalFreeCourses,0) AS TotalFreeCourses,
				 ISNULL(free.AverageFreeCoursesPerAuthor,0) AS AverageFreeCoursesPerAuthor
		FROM      ( SELECT    CAST(COUNT(DISTINCT ch.Id) AS DECIMAL) / CAST(COUNT(DISTINCT c.Id) AS DECIMAL) AS AverageCourseChapters
					FROM      dbo.Courses AS c
						INNER JOIN dbo.CourseChapters AS ch ON c.Id = ch.CourseId
				  ) AS ac,
				  (SELECT  CAST(COUNT(c.Id) AS DECIMAL) / CAST(COUNT(DISTINCT c.AuthorUserId) AS DECIMAL) AS AverageCoursesPerAuthor
					FROM dbo.Courses AS c				  
				  ) AS acpa,
				  (	SELECT  CAST(COUNT(c.BundleId) AS DECIMAL) / CAST((SELECT COUNT(DISTINCT a.AuthorId) FROM dbo.vw_FACT_DASH_Authors AS a) AS DECIMAL) AS AverageBundlesPerAuthor
					FROM dbo.CRS_Bundles AS c) AS abpa,
				  (SELECT COUNT(c.Id) AS TotalFreeCourses,
						 CAST( COUNT(c.Id) AS DECIMAL) / ( CAST(COUNT(DISTINCT c.AuthorUserId) AS DECIMAL))	 AS AverageFreeCoursesPerAuthor
		FROM dbo.Courses AS c
		WHERE c.IsFreeCourse = 1) AS free		

    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_DASH_GetAuthorPeriodStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-21
-- Description:	Get author period stats
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_DASH_GetAuthorPeriodStats] ( @From DATE, @To DATE )
RETURNS TABLE
AS
RETURN
    ( SELECT    ISNULL(aa.ActiveAuthors,0) AS ActiveAuthors,
                ISNULL(al.AvgAuthorLogins,0) AS AvgAuthorLogins ,
                ISNULL(al.TotalLogins,0) AS TotalLogins ,
                ISNULL(dv.DashboardViews,0) AS DashboardViews ,
                ISNULL(c.TotalCouponsCreated,0) AS TotalCouponsCreated
      FROM      ( SELECT    COUNT(DISTINCT a.AuthorId) AS ActiveAuthors
                  FROM      vw_FACT_DASH_Authors AS a
                            INNER JOIN dbo.USER_Logins AS l ON l.UserId = a.AuthorId
                  WHERE     (CAST(l.LoginDate AS DATE) >= CAST(@From AS DATE) AND CAST(l.LoginDate AS DATE) <= CAST(@To AS DATE))
							AND CAST(a.AddOn AS DATE) <= CAST(@To AS DATE)
                ) AS aa ,
                ( SELECT    CAST(COUNT(DISTINCT l.LoginId) AS DECIMAL)
                            / CAST(COUNT(DISTINCT l.UserId) AS DECIMAL) AS AvgAuthorLogins ,
                            COUNT(l.LoginId) AS TotalLogins
                  FROM      dbo.USER_Logins AS l
                  WHERE     CAST(l.LoginDate AS DATE) >= CAST(@From AS DATE)
                            AND CAST(l.LoginDate AS DATE) <= CAST(@To AS DATE)
                            AND l.UserId IN (
                            SELECT  a.AuthorId
                            FROM    dbo.vw_FACT_DASH_Authors AS a 
							WHERE CAST(a.AddOn AS DATE) <= CAST(@To AS DATE))
                ) AS al ,
                ( SELECT    COUNT(l.EventID) AS DashboardViews
                  FROM      dbo.UserSessionsEventLogs AS l
                            INNER JOIN dbo.UserEventTypesLOV AS t ON l.EventTypeID = t.TypeId
                  WHERE     ( t.TypeCode = N'DASHBOARD_VIEW' )
                            AND CAST(l.EventDate AS DATE) >= CAST(@From AS DATE)
                            AND CAST(l.EventDate AS DATE) <= CAST(@To AS DATE)
                ) AS dv ,
                ( SELECT    COUNT(Id) AS TotalCouponsCreated
                  FROM      dbo.Coupons
                  WHERE     CAST(AddOn AS DATE) >= CAST(@From AS DATE)
                            AND CAST(AddOn AS DATE) <= CAST(@To AS DATE)
                ) AS c
    )

GO
/****** Object:  View [dbo].[vw_SALE_Transactions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_SALE_Transactions]
AS
SELECT        trx.TransactionId, so.Sid AS OrderNumber, so.OrderId, so.BuyerUserId, bu.Email AS BuyerEmail, bu.Nickname AS BuyerNickName, 
                         bu.FirstName AS BuyerFirstName, bu.LastName AS BuyerLastName, so.WebStoreId, ws.TrackingID, ws.StoreName, so.OrderDate, so.PaymentMethodId, 
                         pm.PaymentMethodCode, so.InstrumentId, pi.DisplayName AS PaymentIntsrumentDisplayName, sol.LineId, sol.LineTypeId, solt.TypeCode AS LineTypeCode, 
                         sol.PaymentTermId, pt.PaymentTermCode, sol.ItemName, sol.CourseId, sol.BundleId, p.Currency, p.PaymentDate, p.ScheduledDate, p.PaymentNumber, 
                         pst.StatusId AS PaymentStatusId, pst.StatusCode AS PaymentStatusCode, trx.TransactionTypeId, trxt.TypeCode AS TransactionTypeCode, trx.TransactionDate, 
                         trx.ExternalTransactionID, trx.Amount, trx.Fee, trx.Remarks, sol.SellerUserId, su.Email AS SellerEmail, su.Nickname AS SellerNickName, 
                         su.FirstName AS SellerFirstName, su.LastName AS SellerLastName, c.CourseName, cb.BundleName, sol.PriceLineId, pl.CurrencyId, cur.CurrencyName, cur.ISO, 
                         cur.Symbol, trx.RequestId, p.PaymentId
FROM            dbo.BASE_CurrencyLib AS cur INNER JOIN
                         dbo.BILL_ItemsPriceList AS pl ON cur.CurrencyId = pl.CurrencyId RIGHT OUTER JOIN
                         dbo.SALE_TransactionTypesLOV AS trxt INNER JOIN
                         dbo.SALE_Transactions AS trx INNER JOIN
                         dbo.SALE_OrderLines AS sol ON trx.OrderLineId = sol.LineId INNER JOIN
                         dbo.SALE_Orders AS so ON sol.OrderId = so.OrderId ON trxt.TransactionTypeId = trx.TransactionTypeId INNER JOIN
                         dbo.SALE_OrderLineTypesLOV AS solt ON sol.LineTypeId = solt.TypeId INNER JOIN
                         dbo.Users AS bu ON so.BuyerUserId = bu.Id INNER JOIN
                         dbo.BILL_PaymentMethodsLOV AS pm ON so.PaymentMethodId = pm.MethodId INNER JOIN
                         dbo.BILL_PaymentTermsLOV AS pt ON sol.PaymentTermId = pt.PaymentTermId INNER JOIN
                         dbo.Users AS su ON sol.SellerUserId = su.Id ON pl.PriceLineId = sol.PriceLineId LEFT OUTER JOIN
                         dbo.WebStores AS ws ON so.WebStoreId = ws.StoreID LEFT OUTER JOIN
                         dbo.CRS_Bundles AS cb ON sol.BundleId = cb.BundleId LEFT OUTER JOIN
                         dbo.Courses AS c ON sol.CourseId = c.Id LEFT OUTER JOIN
                         dbo.USER_PaymentInstruments AS pi ON so.InstrumentId = pi.InstrumentId AND bu.Id = pi.UserId LEFT OUTER JOIN
                         dbo.SALE_PaymentStatusesLOV AS pst INNER JOIN
                         dbo.SALE_OrderLinePayments AS p ON pst.StatusId = p.StatusId ON trx.PaymentId = p.PaymentId AND sol.LineId = p.OrderLineId

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_SALE_SearchTransactions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-12-25
-- Description:	Get transactions for Portal Admin report
-- =============================================
CREATE FUNCTION [dbo].[tvf_SALE_SearchTransactions]
(	
	 @from DATETIME 
	,@to DATETIME
	,@SellerUserId INT  = NULL
	,@BuyerUserId INT   = NULL
	,@CourseId INT      = NULL
	,@BundleId INT      = NULL
	,@TrxTypeId INT     = NULL	
)
RETURNS TABLE 
AS
RETURN 
(
		SELECT [TransactionId]
				,[OrderNumber]
				,[OrderId]
				,[BuyerUserId]
				,[BuyerEmail]
				,[BuyerNickName]
				,[BuyerFirstName]
				,[BuyerLastName]
				,[WebStoreId]
				,[TrackingID]
				,[StoreName]
				,[OrderDate]
				,[PaymentMethodId]
				,[PaymentMethodCode]
				,[InstrumentId]
				,[PaymentIntsrumentDisplayName]
				,[LineId]
				,[LineTypeId]
				,[LineTypeCode]
				,[PaymentTermId]
				,[PaymentTermCode]
				,[ItemName]
				,[CourseId]
				,[CourseName]
				,[BundleId]
				,[BundleName]
				,[Currency]
				,[PaymentId]
				,[PaymentDate]
				,[ScheduledDate]
				,[PaymentNumber]
				,[PaymentStatusId]
				,[PaymentStatusCode]
				,[TransactionTypeId]
				,[TransactionTypeCode]
				,[TransactionDate]
				,[ExternalTransactionID]
				,[Amount]
				,[Fee]
				,[Remarks]
				,[SellerUserId]
				,[SellerEmail]
				,[SellerNickName]
				,[SellerFirstName]
				,[SellerLastName]
				,[PriceLineId]
				,[CurrencyId]
				,[CurrencyName]
				,[ISO]
				,[Symbol]
				,[RequestId]
		  FROM [dbo].[vw_SALE_Transactions]
		  WHERE (TransactionDate BETWEEN @from  AND @to)
				AND (@SellerUserId IS NULL OR SellerUserId = @SellerUserId)
				AND (@BuyerUserId IS NULL OR BuyerUserId = @BuyerUserId)
				AND (@CourseId IS NULL OR (CourseId IS NOT NULL AND CourseId = @CourseId))
				AND (@BundleId IS NULL OR (BundleId IS NOT NULL AND BundleId = @BundleId))
				AND (@TrxTypeId IS NULL OR TransactionTypeId = @TrxTypeId)

)

GO
/****** Object:  View [dbo].[vw_FACT_WidgetHostEvents]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_FACT_WidgetHostEvents]
AS
SELECT        dbo.fn_BASE_GetUrlHostName(s.HostName) AS HostName, et.TypeCode, et.TypeId, e.EventDate
FROM            dbo.UserSessionsEventLogs AS e INNER JOIN
                         dbo.UserEventTypesLOV AS et ON e.EventTypeID = et.TypeId INNER JOIN
                         dbo.UserSessions AS s ON e.SessionId = s.SessionId
WHERE        (s.HostName IS NOT NULL) AND (s.HostName NOT LIKE 'http://editor.wix.com/html/editor%') AND (s.HostName NOT LIKE 'http://127.0.0.1%') AND 
                         (s.HostName LIKE 'http://%') AND (et.TypeCode IN ('REGISTRATION_SUCCESS', 'PURCHASE_COMPLETE', 'COURSE_PREVIEW_ENTER', 'COURSE_VIEWER_ENTER', 
                         'CHECKOUT_REGISTER', 'BUY_PAGE_ENTERED', 'STORE_VIEW'))

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_GetHostEvents]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-11-20
-- Description:	Get Host name with events
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_GetHostEvents]
(	
	@from DATETIME ,
	@to DATETIME ,
	@groupBy VARCHAR(15),
	@host NVARCHAR(100) 
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT p.period
			   ,p.HostName
			   ,ISNULL(rs.event_amount,0)	 AS REGISTRATION_SUCCESS
			   ,ISNULL(sv.event_amount,0)	 AS STORE_VIEW
			   ,ISNULL(pc.event_amount,0)	 AS PURCHASE_COMPLETE
			   ,ISNULL(cpe.event_amount,0)	 AS COURSE_PREVIEW_ENTER
			   ,ISNULL(cve.event_amount,0)	 AS COURSE_VIEWER_ENTER
			   ,ISNULL(cr.event_amount,0)	 AS CHECKOUT_REGISTER
			   ,ISNULL(bpe.event_amount,0)	 AS BUY_PAGE_ENTERED
		FROM (
			 SELECT DISTINCT HostName ,p.period
				FROM    vw_FACT_WidgetHostEvents CROSS JOIN dbo.[tvf_ADMIN_PeriodTable](@from,@to,@groupBy) as p
				WHERE   EventDate BETWEEN @from AND @to
						AND (@host IS NULL OR  HostName = @host)
		) AS p

		LEFT OUTER JOIN ( 
						 SELECT     HostName ,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END	AS period ,
									COUNT(*) AS event_amount
						  FROM      vw_FACT_WidgetHostEvents
						  WHERE     EventDate BETWEEN @from AND @to
									AND TypeCode IN ( 'REGISTRATION_SUCCESS')
									AND (@host IS NULL OR  HostName = @host)
						  GROUP BY  HostName ,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END
						) AS rs ON p.period = rs.period AND p.HostName = rs.HostName

		
		LEFT OUTER JOIN ( 
						 SELECT    HostName ,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END	AS period ,
									COUNT(*) AS event_amount
						  FROM      vw_FACT_WidgetHostEvents
						  WHERE     EventDate BETWEEN @from AND @to
									AND TypeCode IN ( 'STORE_VIEW')
									AND (@host IS NULL OR  HostName = @host)
						  GROUP BY  HostName,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END
						) AS sv ON p.period = sv.period AND p.HostName = sv.HostName

	
	    LEFT OUTER JOIN ( 
						 SELECT    HostName ,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END	AS period ,
									COUNT(*) AS event_amount
						  FROM      vw_FACT_WidgetHostEvents
						  WHERE     EventDate BETWEEN @from AND @to
									AND TypeCode IN ( 'BUY_PAGE_ENTERED')
									AND (@host IS NULL OR  HostName = @host)
						  GROUP BY  HostName,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END
						) AS bpe ON p.period = bpe.period AND p.HostName = bpe.HostName

			LEFT OUTER JOIN ( 
						 SELECT    HostName ,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END	AS period ,
									COUNT(*) AS event_amount
						  FROM      vw_FACT_WidgetHostEvents
						  WHERE     EventDate BETWEEN @from AND @to
									AND TypeCode IN ( 'CHECKOUT_REGISTER')
									AND (@host IS NULL OR  HostName = @host)
						  GROUP BY  HostName,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END
						) AS cr ON p.period = cr.period AND p.HostName = cr.HostName

			LEFT OUTER JOIN ( 
						 SELECT    HostName ,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END	AS period ,
									COUNT(*) AS event_amount
						  FROM      vw_FACT_WidgetHostEvents
						  WHERE     EventDate BETWEEN @from AND @to
									AND TypeCode IN ( 'COURSE_VIEWER_ENTER')
									AND (@host IS NULL OR  HostName = @host)
						  GROUP BY  HostName,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END
						) AS cve ON p.period = cve.period AND p.HostName = cve.HostName

			LEFT OUTER JOIN ( 
						 SELECT    HostName ,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END	AS period ,
									COUNT(*) AS event_amount
						  FROM      vw_FACT_WidgetHostEvents
						  WHERE     EventDate BETWEEN @from AND @to
									AND TypeCode IN ( 'COURSE_PREVIEW_ENTER')
									AND (@host IS NULL OR  HostName = @host)
						  GROUP BY  HostName,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END
						) AS cpe ON p.period = cpe.period AND p.HostName = cpe.HostName

			LEFT OUTER JOIN ( 
						 SELECT    HostName ,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END	AS period ,
									COUNT(*) AS event_amount
						  FROM      vw_FACT_WidgetHostEvents
						  WHERE     EventDate BETWEEN @from AND @to
									AND TypeCode IN ( 'PURCHASE_COMPLETE')
									AND (@host IS NULL OR  HostName = @host)
						  GROUP BY  HostName,
									CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(EventDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, EventDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, EventDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, EventDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, EventDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, EventDate) AS VARCHAR) + '-' + CAST(DATEPART(month, EventDate) AS VARCHAR)
									END
						) AS pc ON p.period = pc.period AND p.HostName = pc.HostName
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_GetOwnerEventsDailyStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-9-8
-- Description:	Get User vents rep
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_GetOwnerEventsDailyStats]
(	
	@from DATETIME, 
	@to DATETIME
)
RETURNS TABLE 
AS
RETURN 
(

	
		SELECT  CAST(d.EventDate AS DATE) AS EventDate ,
        d.OwnerTypeId ,
        ISNULL(ev.cnt, 0) AS cnt
FROM    ( SELECT    p.period AS EventDate ,
                    lov.OwnerTypeId ,
                    lov.OwnerCode 
          FROM      dbo.tvf_ADMIN_PeriodTable(@from, @to, 'day') AS p ,
                    dbo.UserEventTypeOwnersLOV AS lov
        ) AS d
        LEFT OUTER JOIN ( SELECT    COUNT(ev.EventID) AS cnt ,
                                    CAST(ev.EventDate AS DATE) AS EventDate ,
                                    ownr.OwnerTypeId ,
                                    ownr.OwnerCode
                          FROM      dbo.UserSessionsEventLogs AS ev
                                    INNER JOIN dbo.UserEventTypesLOV AS lov ON ev.EventTypeID = lov.TypeId
                                    INNER JOIN dbo.UserEventTypeOwnersLOV AS ownr ON lov.OwnerTypeId = ownr.OwnerTypeId
                                    LEFT OUTER JOIN dbo.UserSessions AS ss ON ev.SessionId = ss.SessionId
                          WHERE     ( CAST(ev.EventDate AS DATE) BETWEEN @from AND @to )
                          GROUP BY  CAST(ev.EventDate AS DATE) ,
                                    ownr.OwnerTypeId ,
                                    ownr.OwnerCode
                        ) AS ev ON d.OwnerTypeId = ev.OwnerTypeId
                                   AND d.EventDate = ev.EventDate
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_GetEventsDailyStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-7-28
-- Description:	Get User vents rep
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_GetEventsDailyStats]
(	
	@from DATETIME, 
	@to DATETIME,
	@UserId INT = NULL,
	@CourseId INT = NULL,
	@BundleId INT = NULL,
	@StoreId  INT = NULL,	
	@EventTypeID SMALLINT = NULL
)
RETURNS TABLE 
AS
RETURN 
(

	
			SELECT   CAST(d.EventDate AS DATE) AS EventDate ,
					d.TypeId ,
					ISNULL(ev.cnt, 0) AS cnt
			FROM    ( SELECT    p.period AS EventDate ,
								lov.TypeId ,
								lov.TypeCode ,
								lov.TypeName
					  FROM      dbo.tvf_ADMIN_PeriodTable(@from, @to, 'day') AS p,dbo.UserEventTypesLOV AS lov
					) AS d
			LEFT OUTER JOIN ( SELECT    COUNT(ev.EventID) AS cnt ,
                                    ev.EventTypeID ,
                                    CAST(ev.EventDate AS DATE) AS EventDate
                          FROM      dbo.UserSessionsEventLogs AS ev
                                    LEFT OUTER JOIN dbo.UserSessions AS ss ON ev.SessionId = ss.SessionId
                          WHERE     ( CAST(ev.EventDate AS DATE) BETWEEN @from AND @to )
                                    AND ( @UserId IS NULL OR ss.UserID = @UserId)
                                    AND ( @CourseId IS NULL OR ev.CourseId = @CourseId)
                                    AND ( @BundleId IS NULL OR ev.BundleId = @BundleId)
                                    AND ( @StoreId IS NULL OR ev.WebStoreId = @StoreId)
                                    AND ( @EventTypeID IS NULL OR ev.EventTypeID = @EventTypeID)
                          GROUP BY  ev.EventTypeID ,
                                    CAST(ev.EventDate AS DATE)
                        ) AS ev ON d.TypeId = ev.EventTypeID
                                   AND d.EventDate = ev.EventDate
)

GO
/****** Object:  View [dbo].[vw_EVENT_Logs]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_EVENT_Logs]
AS
SELECT        TOP (100) PERCENT ev.EventID, s.UserID, u.Email, u.Nickname, u.FirstName, u.LastName, ev.EventTypeID, t.TypeCode, ev.EventDate, ev.WebStoreId, 
                         ws.TrackingID, ws.StoreName, ev.CourseId, c.CourseName, ev.BundleId, b.BundleName, CASE WHEN ev.CourseId IS NOT NULL 
                         THEN 'COURSE' WHEN ev.BundleId IS NOT NULL THEN 'BUNDLE' ELSE 'Unknown' END AS ItemType, b.AuthorId AS BundleAuthorId, 
                         c.AuthorUserId AS CourseAuthorId, ev.AdditionalData, ev.AubsoluteUri, ev.SessionId, ev.ExportToFact, ws.OwnerUserID AS StoreOwnerUserID
FROM            dbo.UserEventTypesLOV AS t INNER JOIN
                         dbo.UserSessionsEventLogs AS ev ON t.TypeId = ev.EventTypeID LEFT OUTER JOIN
                         dbo.Users AS u INNER JOIN
                         dbo.UserSessions AS s ON u.Id = s.UserID ON ev.SessionId = s.SessionId LEFT OUTER JOIN
                         dbo.CRS_Bundles AS b ON ev.BundleId = b.BundleId LEFT OUTER JOIN
                         dbo.WebStores AS ws ON ev.WebStoreId = ws.StoreID LEFT OUTER JOIN
                         dbo.Courses AS c ON ev.CourseId = c.Id

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_GetEventsDailyLiveAggregates]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-11-26
-- Description:	Get User Events Stats
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_GetEventsDailyLiveAggregates]
(	
	@from DATETIME, 
	@to DATETIME,
	@AuthorId INT = NULL,
	@StoreId INT = NULL
)
RETURNS TABLE 
AS
RETURN 
(

	
			SELECT  CAST(d.EventDate AS DATE) AS EventDate ,
					d.TypeId ,
					ISNULL(ev.EventCount, 0) AS cnt
			FROM    ( SELECT    p.period AS EventDate ,
								lov.TypeId ,
								lov.TypeCode ,
								lov.TypeName
					  FROM      dbo.tvf_ADMIN_PeriodTable(@from, @to, 'day') AS p ,
								dbo.UserEventTypesLOV AS lov
					) AS d
			LEFT OUTER JOIN ( 
								SELECT    f.EventCount ,
										f.EventTypeID ,
										t.TypeCode ,
										f.EventDate ,
										f.WebStoreId ,
										f.ItemId ,
										f.ItemType ,
										f.AuthorId ,
										f.ItemName ,
										ws.StoreName ,
										u.Email ,
										u.Nickname ,
										u.FirstName ,
										u.LastName
								FROM      dbo.WebStores AS ws
										RIGHT OUTER JOIN dbo.Users AS u
										RIGHT OUTER JOIN ( SELECT COUNT(DISTINCT SessionId) AS EventCount ,
																	EventTypeID ,
																	CAST(EventDate AS DATE) AS EventDate ,
																	WebStoreId ,
																	ISNULL(CourseId,BundleId) AS ItemId ,
																	ItemType ,
																	ISNULL(CourseName,BundleName) AS ItemName ,
																	ISNULL(ISNULL(CourseAuthorId,BundleAuthorId),StoreOwnerUserID) AS AuthorId
															FROM   vw_EVENT_Logs
															WHERE  ( WebStoreId IS NOT NULL OR CourseId IS NOT NULL OR BundleId IS NOT NULL)
																	AND ( CAST(EventDate AS DATE) BETWEEN @from AND @to )
															GROUP BY EventTypeID ,
																	CAST(EventDate AS DATE) ,
																	WebStoreId ,
																	ISNULL(CourseId,BundleId) ,
																	ItemType ,
																	ISNULL(ISNULL(CourseAuthorId,BundleAuthorId),StoreOwnerUserID) ,
																	ISNULL(CourseName,BundleName)
															) AS f
										INNER JOIN dbo.UserEventTypesLOV AS t ON f.EventTypeID = t.TypeId ON u.Id = f.AuthorId ON ws.StoreID = f.WebStoreId
								WHERE     ( @AuthorId IS NULL OR f.AuthorId = @AuthorId)
										AND ( @StoreId IS NULL OR f.WebStoreId = @StoreId)
						) AS ev ON d.TypeId = ev.EventTypeID
									AND d.EventDate = ev.EventDate
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_ADMIN_GetSystemLogs]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-10-24
-- Description:	Get system logs
-- =============================================
CREATE FUNCTION [dbo].[tvf_ADMIN_GetSystemLogs]
    (
      @from DATETIME ,
      @to DATETIME ,
      @Module VARCHAR(150) = NULL ,
      @Level VARCHAR(150) = NULL ,
      @UserId INT = NULL ,
      @SessionId BIGINT = NULL ,
      @IpAddress VARCHAR(150) = NULL
    )
RETURNS TABLE
AS
RETURN
    ( SELECT   l.id ,
                l.Origin ,
                l.LogLevel ,
                l.Message ,
                l.Exception ,
                l.StackTrace ,
                l.Logger ,
                l.RecordIntId ,
                l.RecordGuidId ,
                l.CreateDate ,
                l.RecordObjectType ,
                l.IPAddress ,
                l.HostName ,
                l.UserId ,
                MAX(us.SessionId) AS SessionId ,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName
      FROM      dbo.LogTable AS l
                LEFT OUTER JOIN dbo.UserSessions AS us ON l.SessionId = us.NetSessionId
                LEFT OUTER JOIN dbo.Users AS u ON l.UserId = u.Id
	  WHERE (l.CreateDate BETWEEN @from AND @to) 
		 --   AND (@Module IS NULL OR l.RecordObjectType = @Module)
		--	AND (@Level IS NULL OR l.LogLevel = @Level)
		--	AND (@IpAddress IS NULL OR l.IPAddress = @IpAddress)
		--	AND (@SessionId IS NULL OR us.NetSessionId = @SessionId)
		--	AND (@UserId IS NULL OR l.UserId = @UserId)
      GROUP BY  l.id ,
                l.Origin ,
                l.LogLevel ,
                l.Logger ,
                l.RecordIntId ,
                l.RecordGuidId ,
                l.CreateDate ,
                l.RecordObjectType ,
                l.IPAddress ,
                l.HostName ,
                l.UserId ,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
                l.Message ,
                l.Exception ,
                l.StackTrace
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_ADMIN_GetUnusedVideos]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[tvf_ADMIN_GetUnusedVideos] ( )
RETURNS TABLE
AS
RETURN
( 
	  --SELECT    v.BcIdentifier
   --   FROM      dbo.USER_Videos AS v
   --             INNER JOIN ( SELECT MAX(ISNULL(l.LoginDate, u.LastLogin)) AS LastLogin ,
   --                                 u.FirstName ,
   --                                 u.LastName ,
   --                                 u.Id ,
   --                                 u.Email
   --                          FROM   dbo.USER_Logins AS l
   --                                 RIGHT OUTER JOIN dbo.Users AS u ON l.UserId = u.Id
   --                          GROUP BY u.FirstName ,
   --                                 u.LastName ,
   --                                 u.Id ,
   --                                 u.Email
   --                        ) AS u ON v.UserId = u.Id
   --   WHERE     ( v.Attached2Chapter = 0 )
			--	AND (v.UserId NOT IN (1655,1585,306))
   --             AND ( u.LastLogin < DATEADD(DAY, -45, GETDATE()) )
   --   UNION
      SELECT    v.BcIdentifier
      FROM      dbo.USER_Videos AS v
      WHERE     ( v.Attached2Chapter = 0 )
				AND (v.UserId NOT IN (1655,1585,306))
                AND ( v.CreationDate < DATEADD(DAY, -45, GETDATE()) )
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_APP_PluginsInstallationsRep]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alexander Shnirman
-- Create date: 19.10.2014
-- =============================================
CREATE FUNCTION [dbo].[tvf_APP_PluginsInstallationsRep]
(	
	@from DATETIME = NULL,
	@to DATETIME = NULL,
	@typeId INT = NULL,
	@userId INT = NULL,
	@isactive BIT = NULL
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT  i.InstallationId ,
        i.TypeId ,
        i.UId ,
        i.Domain ,
        i.Version ,
        i.UserId ,
        i.IsActive ,
        i.AddOn ,
        i.UpdateDate ,
        u.FirstName ,
        u.LastName ,
        u.Email ,
        u.Nickname ,
        u.Created AS UserAddOn
	FROM    dbo.APP_PluginInstallations AS i
			LEFT OUTER JOIN dbo.Users AS u ON i.UserId = u.Id
	WHERE   (@from IS NULL OR i.AddOn >= @from) AND
			(@to IS NULL OR i.AddOn < @to) AND
			(@typeId IS NULL OR i.TypeId = @typeId) AND
			(@userId IS NULL OR @userId = i.UserId) AND
			(@isactive IS NULL OR @isactive = i.IsActive)
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CAT_GetCategories]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-7-18
-- Description:	Get categories for manage
-- =============================================
CREATE FUNCTION [dbo].[tvf_CAT_GetCategories] ()
RETURNS TABLE
AS
RETURN
    ( SELECT    c.Id ,
                c.CategoryName ,
                ISNULL(cnt.cnt, 0) AS CoursesCnt ,
                ISNULL(bcnt.cnt, 0) AS BundlesCnt ,
                c.IsActive 
      FROM      ( SELECT    CategoryId ,
                            COUNT(CourseId) AS cnt
                  FROM      dbo.CourseCategories
                  GROUP BY  CategoryId
                ) AS cnt
                RIGHT OUTER JOIN dbo.Categories AS c ON cnt.CategoryId = c.Id
                LEFT OUTER JOIN ( SELECT    CategoryId ,
                                            COUNT(BundleId) AS cnt
                                  FROM      dbo.CRS_BundleCategories
                                  GROUP BY  CategoryId
                                ) AS bcnt ON bcnt.CategoryId = c.Id
      GROUP BY  c.Id ,
                c.CategoryName ,
                ISNULL(cnt.cnt, 0) ,
                ISNULL(bcnt.cnt, 0) ,
                c.IsActive 
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CAT_GetCategoriesWithCourseCount]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-3
-- Description:	Get Active categories with related courses count
-- =============================================
CREATE FUNCTION [dbo].[tvf_CAT_GetCategoriesWithCourseCount] ( )
RETURNS TABLE
AS
RETURN
    ( SELECT    c.Id ,
                c.CategoryName ,
                ISNULL(cnt.cnt, 0) AS CoursesCnt,
                ISNULL(bcnt.cnt, 0) AS BundlesCnt
      FROM      ( SELECT    CategoryId ,
                            COUNT(CourseId) AS cnt
                  FROM      dbo.CourseCategories
                  GROUP BY  CategoryId
                ) AS cnt
                RIGHT OUTER JOIN dbo.Categories AS c ON cnt.CategoryId = c.Id
                LEFT OUTER JOIN ( SELECT    CategoryId ,
                                            COUNT(BundleId) AS cnt
                                  FROM      dbo.CRS_BundleCategories
                                  GROUP BY  CategoryId
                                ) AS bcnt ON bcnt.CategoryId = c.Id
      WHERE     ( c.IsActive = 1 )
                AND ( ISNULL(cnt.cnt, 0) > 0
                      OR ISNULL(bcnt.cnt, 0) > 0
                    )
      GROUP BY  c.Id ,
                c.CategoryName ,
                ISNULL(cnt.cnt, 0) ,
                ISNULL(bcnt.cnt, 0)
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CAT_GetCategoryItems]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-3
-- Update date: 2014-1-26
-- Description:	Get Category Courses
-- =============================================
CREATE FUNCTION [dbo].[tvf_CAT_GetCategoryItems] ( @CategoryID INT )
RETURNS TABLE
AS
RETURN
    ( 
		 SELECT     c.Id AS ItemId ,
					c.CourseName AS ItemName ,
					'COURSE' AS ItemType
		  FROM      dbo.CourseCategories AS cc
					INNER JOIN dbo.Courses AS c ON cc.CourseId = c.Id
		  WHERE     cc.CategoryId = @CategoryID
		 
		  UNION
		 
		  SELECT    c.BundleId AS ItemId ,
					c.BundleName AS ItemName ,
					'BUNDLE' AS ItemType
		  FROM      dbo.CRS_BundleCategories AS cc
					INNER JOIN dbo.CRS_Bundles AS c ON cc.BundleId = c.BundleId
		  WHERE     cc.CategoryId = @CategoryID
    )


GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_FindCourseByUrlName]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-4-13
-- Description:	Find course
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_FindCourseByUrlName]
(
    @CourseUrlName NVARCHAR(256) ,
    @AuthorUrlName NVARCHAR(256)
)
RETURNS TABLE
AS
RETURN
( 

	SELECT c.[Id]
		  ,c.[ProvisionUid]
		  ,c.[uid]
		  ,c.[CourseName]
		  ,c.[CourseUrlName]
		  ,c.[AuthorUserId]
		  ,c.[AffiliateCommission]
		  ,c.[SmallImage]
		  ,c.[Description]
		  ,c.[OverviewVideoIdentifier]
		  ,c.[Rating]
		  ,c.[MetaTags]
		  ,c.[ClassRoomId]
		  ,c.[FbObjectId]
		  ,c.[FbObjectPublished]
		  ,c.[IsFreeCourse]
		  ,c.[DisplayOtherLearnersTab]
		  ,c.[PublishDate]
		  ,c.[StatusId]
		  ,c.[Created]
		  ,c.[LastModified]
		  ,c.[IsDownloadEnabled]
	FROM      dbo.Courses AS c
			INNER JOIN dbo.Users AS u ON c.AuthorUserId = u.Id
	WHERE   (c.CourseUrlName = @CourseUrlName)
			AND REPLACE(( u.FirstName + '-' + u.LastName ), ' ', '-') = @AuthorUrlName
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetAuthorsCoupons]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014_1_30
-- Description:	Get Author Coupons
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetAuthorsCoupons] ( @AuthorId INT )
RETURNS TABLE
AS
RETURN
    ( SELECT    cpn.Id ,
                cpn.CouponName ,
                cpn.Description ,
                cpn.CourseId ,
                cpn.BundleId ,
				crs.CourseName, 
				b.BundleName,
                cpn.CouponTypeId ,
                cpn.CouponTypeAmount ,
                cpn.AutoGenerate ,
                cpn.ExpirationDate ,
                cpn.SubscriptionMonths ,
                ci_1.UsageLimit ,
                ci_1.Code ,
                trx.cnt AS ActualUsage ,
                CAST(( CASE ISNULL(trx.cnt, 0)
                         WHEN 0 THEN 1
                         ELSE 0
                       END ) AS BIT) AS IsDeleteAllowed
      FROM      dbo.Coupons AS cpn
                LEFT OUTER JOIN dbo.CRS_Bundles AS b ON cpn.BundleId = b.BundleId
                LEFT OUTER JOIN dbo.Courses AS crs ON cpn.CourseId = crs.Id
                LEFT OUTER JOIN ( SELECT    COUNT(t.LineId) AS cnt ,
                                            ci.CouponId
                                  FROM      dbo.SALE_OrderLines AS t
                                            INNER JOIN dbo.CouponInstances AS ci ON t.CouponInstanceId = ci.Id
                                  WHERE     ( t.CouponInstanceId IS NOT NULL )
                                  GROUP BY  ci.CouponId
                                ) AS trx ON cpn.Id = trx.CouponId
                LEFT OUTER JOIN ( SELECT    CouponId ,
                                            CASE COUNT(c.Id)
                                              WHEN 1 THEN UsageLimit
                                              ELSE COUNT(c.Id)
                                            END AS UsageLimit ,
                                            CASE COUNT(c.Id)
                                              WHEN 1
                                              THEN ( SELECT CouponCode
                                                     FROM   CouponInstances AS ci
                                                     WHERE  ci.CouponId = c.CouponId
                                                   )
                                              ELSE 'Auto generated'
                                            END AS Code
                                  FROM      dbo.CouponInstances AS c
                                  GROUP BY  CouponId ,
                                            UsageLimit
                                ) AS ci_1 ON cpn.Id = ci_1.CouponId
      WHERE     ( cpn.OwnerUserId = @AuthorId )
                OR ( crs.AuthorUserId = @AuthorId )
                OR ( b.AuthorId = @AuthorId )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetAvailableCourses4Bundle]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-1-23
-- Description:	Get available courses for bundle
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetAvailableCourses4Bundle] ( @BundleId INT )
RETURNS TABLE
AS
RETURN
    ( SELECT    c.Id ,
                c.CourseName ,
                c.SmallImage,
				c.StatusId
      FROM      ( SELECT    BundleCourseId ,
                            CourseId ,
                            IsActive
                  FROM      dbo.CRS_BundleCourses
                  WHERE     ( BundleId = @BundleId )
                            AND ( IsActive = 1 )
                ) AS bc
                RIGHT OUTER JOIN dbo.Courses AS c ON bc.CourseId = c.Id
      WHERE     ( ISNULL(bc.BundleCourseId, -1) < 0 )
                AND ( c.AuthorUserId = ( SELECT AuthorId
                                         FROM   dbo.CRS_Bundles
                                         WHERE  BundleId = @BundleId
                                       ) )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetBundleCourses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-01-21
-- Description:	Get Bundle Courses
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetBundleCourses] ( @BundleId INT )
RETURNS TABLE
AS
RETURN
    ( 
	  SELECT    bc.BundleCourseId ,
                bc.BundleId ,
                bc.CourseId ,
                bc.IsActive ,
                bc.OrderIndex ,
                c.CourseName ,
                c.CourseUrlName ,
                c.Description AS CourseDescription ,
                c.SmallImage ,
                c.OverviewVideoIdentifier ,
                c.StatusId ,
                c.AuthorUserId ,
                u.Nickname AS AuthorNickName ,
                u.FirstName AS AuthorFirstName ,
                u.LastName AS AuthorLastName
      FROM      dbo.Courses AS c
                INNER JOIN dbo.CRS_BundleCourses AS bc ON c.Id = bc.CourseId
                INNER JOIN dbo.Users AS u ON c.AuthorUserId = u.Id
      WHERE     ( bc.BundleId = @BundleId )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetBundleInfo]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-5-20
-- Description:	Get bundle info by bundleId
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetBundleInfo] (@CurrencyId SMALLINT = 2, @BundleId INT )
RETURNS TABLE
AS
RETURN
    ( SELECT    b.BundleId ,
                b.BundleName ,
				b.BundleUrlName,
                b.BundleDescription ,
                b.AuthorId ,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
                u.FacebookID ,
                b.BannerImage ,                
                dbo.fn_BILL_GetItemPrice(b.BundleId,2,@CurrencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
				dbo.fn_BILL_GetItemPrice(b.BundleId,2,@CurrencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
                b.OverviewVideoIdentifier ,
                b.MetaTags ,
                b.uid ,
                b.StatusId ,
                s.StatusCode ,
                s.StatusName ,
                b.FbObjectId ,
                b.FbObjectPublished
      FROM      dbo.StatusLOV AS s
                INNER JOIN dbo.CRS_Bundles AS b ON s.StatusId = b.StatusId
                INNER JOIN dbo.Users AS u ON b.AuthorId = u.Id
      WHERE     ( b.BundleId = @BundleId )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetBundlesCoupons]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014_1_22
-- Description:	Get Bundle Coupons
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetBundlesCoupons] ( @BundleId INT )
RETURNS TABLE
AS
RETURN
    ( 
		SELECT  cpn.Id ,
				cpn.CouponName ,
				cpn.Description ,
				cpn.CourseId ,
				cpn.BundleId ,
				'' AS CourseName, 
				'' AS BundleName,
				cpn.CouponTypeId ,
				cpn.CouponTypeAmount ,
				cpn.AutoGenerate ,
				cpn.ExpirationDate ,
				cpn.SubscriptionMonths,
				ci.UsageLimit ,
				ci.Code ,
				trx.cnt AS ActualUsage,
				CAST(( CASE ISNULL(trx.cnt, 0)
						 WHEN 0 THEN 1
						 ELSE 0
					   END ) AS BIT) AS IsDeleteAllowed
				FROM    dbo.Coupons AS cpn
				LEFT OUTER JOIN ( SELECT    COUNT(t.LineId) AS cnt ,
											ci.CouponId
								  FROM      dbo.SALE_OrderLines AS t
											INNER JOIN dbo.CouponInstances AS ci ON t.CouponInstanceId = ci.Id
								  WHERE     ( t.CouponInstanceId IS NOT NULL )
								  GROUP BY  ci.CouponId
								) AS trx ON cpn.Id = trx.CouponId
				LEFT OUTER JOIN ( SELECT    CouponId ,
												  --  COUNT(Id) AS cnt ,
											CASE COUNT(c.Id)
											  WHEN 1 THEN UsageLimit
											  ELSE COUNT(c.Id)
											END AS UsageLimit ,
											CASE COUNT(c.Id)
											  WHEN 1
											  THEN ( SELECT CouponCode
													 FROM   CouponInstances AS ci
													 WHERE  ci.CouponId = c.CouponId
												   )
											  ELSE 'Auto generated'
											END AS Code
								  FROM      dbo.CouponInstances AS c
								  GROUP BY  CouponId ,
											UsageLimit
								) AS ci ON cpn.Id = ci.CouponId
				WHERE cpn.BundleId = @BundleId
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetChaptersByUid]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013_10_17
-- Description:	Get chapters by course UID
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetChaptersByUid]
(	
	@Uid UNIQUEIDENTIFIER
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT  cc.*
	FROM    dbo.CourseChapters AS cc 
				INNER JOIN dbo.Courses AS c 
					ON cc.CourseId = c.Id
	WHERE (c.uid=@Uid)
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetCourseCategories]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-10-8
-- Description:	Get course category entities
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetCourseCategories]
(	
	@CourseId INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT  c.Id ,
			c.CategoryName ,
			c.CategoryUrlName ,
			c.CategoryDescription ,
			c.IsOnHomePage ,
			c.Ordinal ,
			c.BannerImageUrl ,
			c.Keywords ,
			c.IsActive
	FROM    dbo.Categories AS c
			INNER JOIN dbo.CourseCategories AS cc ON c.Id = cc.CategoryId
	WHERE   ( cc.CourseId = @CourseId )
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetCourseContentCnt]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013_11_06
-- Description:	Check if contents was created for course
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetCourseContentCnt] ( @CourseId INT )
RETURNS TABLE
AS
RETURN
    ( SELECT    ISNULL(v.cntV + l.cntL,0) AS cnt
      FROM      ( SELECT    ISNULL(COUNT(dbo.ChapterVideos.Id), 0) AS cntV ,
                            dbo.CourseChapters.CourseId
                  FROM      dbo.CourseChapters
                            LEFT OUTER JOIN dbo.ChapterVideos ON dbo.CourseChapters.Id = dbo.ChapterVideos.CourseChapterId
                  WHERE     ( dbo.CourseChapters.CourseId = @CourseId )
                  GROUP BY  dbo.CourseChapters.CourseId
                ) AS v
                CROSS JOIN ( SELECT ISNULL(COUNT(dbo.ChapterLinks.Id), 0) AS cntL ,
                                    CourseChapters_1.CourseId
                             FROM   dbo.CourseChapters AS CourseChapters_1
                                    LEFT OUTER JOIN dbo.ChapterLinks ON CourseChapters_1.Id = dbo.ChapterLinks.CourseChapterId
                             WHERE  ( CourseChapters_1.CourseId = @CourseId )
                             GROUP BY CourseChapters_1.CourseId
                           ) AS l
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetCourseCoupons]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013_6_20
-- Description:	Get Course Coupons
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetCourseCoupons] ( @CourseId INT )
RETURNS TABLE
AS
RETURN
    ( SELECT  cpn.Id ,
        cpn.CouponName ,
        cpn.Description ,
        cpn.CourseId ,
		cpn.BundleId ,
		'' AS CourseName, 
		'' AS BundleName,
        cpn.CouponTypeId ,
        cpn.CouponTypeAmount ,
        cpn.AutoGenerate ,
        cpn.ExpirationDate ,
		cpn.SubscriptionMonths,
        ci.UsageLimit ,
        ci.Code ,
		trx.cnt AS ActualUsage,
        CAST(( CASE ISNULL(trx.cnt, 0)
                 WHEN 0 THEN 1
                 ELSE 0
               END ) AS BIT) AS IsDeleteAllowed
		FROM    dbo.Coupons AS cpn
        LEFT OUTER JOIN ( SELECT    COUNT(t.LineId) AS cnt ,
                                    ci.CouponId
                          FROM      dbo.SALE_OrderLines AS t
                                    INNER JOIN dbo.CouponInstances AS ci ON t.CouponInstanceId = ci.Id
                          WHERE     ( t.CouponInstanceId IS NOT NULL )
                          GROUP BY  ci.CouponId
                        ) AS trx ON cpn.Id = trx.CouponId
        LEFT OUTER JOIN ( SELECT    CouponId ,
                                          --  COUNT(Id) AS cnt ,
                                    CASE COUNT(c.Id)
                                      WHEN 1 THEN UsageLimit
                                      ELSE COUNT(c.Id)
                                    END AS UsageLimit ,
                                    CASE COUNT(c.Id)
                                      WHEN 1
                                      THEN ( SELECT CouponCode
                                             FROM   CouponInstances AS ci
                                             WHERE  ci.CouponId = c.CouponId
                                           )
                                      ELSE 'Auto generated'
                                    END AS Code
                          FROM      dbo.CouponInstances AS c
                          GROUP BY  CouponId ,
                                    UsageLimit
                        ) AS ci ON cpn.Id = ci.CouponId
		WHERE cpn.CourseId = @CourseId
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetCourseInfo]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-11-27
-- Description:	Get course info by courseId
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetCourseInfo] (@CurrencyId SMALLINT = 2,  @CourseId INT )
RETURNS TABLE
AS
RETURN
( 
	 SELECT     c.Id AS CourseId ,
				c.ProvisionUid,
                c.CourseName ,
				c.CourseUrlName,
                c.AuthorUserId ,
				c.DisplayOtherLearnersTab,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
				u.FacebookID ,
                c.IsFreeCourse ,
                c.SmallImage ,
                c.Description AS CourseDescription ,
                dbo.fn_BILL_GetItemPrice(c.Id,1,@CurrencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
				dbo.fn_BILL_GetItemPrice(c.Id,1,@CurrencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
                c.OverviewVideoIdentifier ,
                c.MetaTags ,
                c.uid ,
                c.StatusId ,
                s.StatusCode ,
                s.StatusName ,
                c.FbObjectId ,
                c.FbObjectPublished,
				c.IsDownloadEnabled
      FROM      dbo.Users AS u
                INNER JOIN dbo.Courses AS c ON u.Id = c.AuthorUserId
                INNER JOIN dbo.StatusLOV AS s ON c.StatusId = s.StatusId
      WHERE     ( c.Id = @CourseId ) 
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetCourseInfoByUrlName]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-12-11
-- Description:	Get course info by courseUrlName
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetCourseInfoByUrlName] (@CurrencyId SMALLINT = 2,  @UrlName NVARCHAR(256) )
RETURNS TABLE
AS
RETURN
( 
	  SELECT    c.Id AS CourseId ,
				c.ProvisionUid,
                c.CourseName ,
				c.CourseUrlName,
                c.AuthorUserId ,
				c.DisplayOtherLearnersTab,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
				u.FacebookID ,
                c.IsFreeCourse ,
                c.SmallImage ,
                c.Description AS CourseDescription,
                dbo.fn_BILL_GetItemPrice(c.Id,1,@CurrencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
				dbo.fn_BILL_GetItemPrice(c.Id,1,@CurrencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
                c.OverviewVideoIdentifier ,
                c.MetaTags ,
                c.uid ,
				c.IsDownloadEnabled,
                c.StatusId ,
                s.StatusCode ,
                s.StatusName ,
                c.FbObjectId ,
                c.FbObjectPublished
      FROM      dbo.Users AS u
                INNER JOIN dbo.Courses AS c ON u.Id = c.AuthorUserId
                INNER JOIN dbo.StatusLOV AS s ON c.StatusId = s.StatusId
      WHERE     ( c.CourseUrlName = @UrlName) 
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetOtherLearners]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-7-23
-- Description:	Get other learners for course page tab
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetOtherLearners]
    (
      @UserId INT ,
      @CourseId INT
    )
RETURNS TABLE
AS
RETURN
    ( SELECT    uc.UserId ,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
                u.FacebookID ,
                u.PictureURL ,
                u.AuthorPictureURL
      FROM      dbo.Users AS u
                INNER JOIN dbo.USER_Courses AS uc ON u.Id = uc.UserId
	  WHERE (uc.CourseId=@CourseId)
			AND (uc.UserId != @UserId)
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetReviewToken4Author]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-09-23
-- Description:	Get token for sending email or FB post to course author , when review was saved
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetReviewToken4Author]
(	
	@ReviewId INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT  r.ReviewDate ,
			r.ReviewText ,
			ur.Id AS ReviewWriterId ,
			ur.Nickname AS ReviewWriterNickname ,
			ur.FirstName AS ReviewWriterFirstName ,
			ur.LastName AS ReviewWriterLastName ,
			a.Nickname AS AuthorNickname ,
			a.FirstName AS AuthorFirstName ,
			a.LastName AS AuthorLastName ,
			a.FacebookID AS AuthorFacebookID ,
			a.Email AS AuthorEmail ,
			a.Id AS AuthorUserId,
			c.CourseName ,
			c.CourseUrlName ,
			c.SmallImage AS CourseThumbUrl,
			c.Description AS CourseDescription ,
			c.Id AS CourseId
	FROM    dbo.UserCourseReviews AS r
			INNER JOIN dbo.Courses AS c ON r.CourseId = c.Id
			INNER JOIN dbo.Users AS a ON c.AuthorUserId = a.Id
			INNER JOIN dbo.Users AS ur ON r.UserId = ur.Id
	WHERE   ( r.Id = @ReviewId )
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetReviewToken4Learners]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-09-23
-- Description:	Get token for sending email or FB post for course learners, when review was saved
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetReviewToken4Learners]
(	
	@ReviewId INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT  r.ReviewDate ,
			r.ReviewText ,
			ur.Id AS ReviewWriterId ,
			ur.Nickname AS ReviewWriterNickname ,
			ur.FirstName AS ReviewWriterFirstName ,
			ur.LastName AS ReviewWriterLastName ,
			a.Nickname AS AuthorNickname ,
			a.FirstName AS AuthorFirstName ,
			a.LastName AS AuthorLastName ,
			a.FacebookID AS AuthorFacebookID ,
			a.Id AS AuthorUserId ,
			ul.Id AS LearnerUserId ,
			ul.FacebookID AS LearnerFacebookID ,
			ul.Email AS LearnerEmail , 
            ul.Nickname AS LearnerNickname ,
			ul.FirstName AS LearnerFirstName ,
			ul.LastName AS LearnerLastName ,
			c.CourseName ,
			c.CourseUrlName ,
			c.SmallImage AS CourseThumbUrl,
			c.Description AS CourseDescription ,
			c.Id AS CourseId
	FROM    dbo.UserCourseReviews AS r
			INNER JOIN dbo.Courses AS c ON r.CourseId = c.Id
			INNER JOIN dbo.USER_Courses AS uc ON c.Id = uc.CourseId
			INNER JOIN dbo.Users AS a ON c.AuthorUserId = a.Id
			INNER JOIN dbo.Users AS ur ON r.UserId = ur.Id
			INNER JOIN dbo.Users AS ul ON uc.UserId = ul.Id
	WHERE   ( r.Id = @ReviewId )
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetSubscribers]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-10-30
-- Description:	Get Course Subscribers
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetSubscribers] ( @CourseId INT )
RETURNS TABLE
AS
RETURN
    ( SELECT    u.Id AS UserId,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
                u.FacebookID ,
                u.PictureURL ,
                u.AuthorPictureURL
      FROM      dbo.USER_Courses AS uc
                INNER JOIN dbo.Users AS u ON uc.UserId = u.Id
      WHERE (uc.CourseId = @CourseId)
      GROUP BY  u.Id ,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
                u.FacebookID ,
                u.PictureURL ,
                u.AuthorPictureURL
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_CRS_GetWebStores]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013_10_14
-- Description:	Get course web stores
-- =============================================
CREATE FUNCTION [dbo].[tvf_CRS_GetWebStores]
(	
	@CourseID INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT      cat.WebStoreID
	FROM        dbo.WebStoreCategories AS cat 
					INNER JOIN dbo.WebStoreItems AS c 
						ON cat.WebStoreCategoryID = c.WebStoreCategoryID
	WHERE       (c.CourseID = @CourseID)
	GROUP BY cat.WebStoreID
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DB_GetAuthorEventStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-11-1
-- Description:	Get author dashboard event stats
-- =============================================
CREATE FUNCTION [dbo].[tvf_DB_GetAuthorEventStats]
(	
	@UserId INT
)
RETURNS TABLE 
AS
RETURN 
(
		SELECT  crs.LastCoursePublish ,
				bnd.LastBundlePublish ,
				chap.LastChaperCreated ,
				fbs.LastFbStoreCreated,
				nfbs.LastStoreCreated
		FROM    ( SELECT    MAX(c.PublishDate) AS LastCoursePublish
				  FROM      dbo.Courses AS c
				  WHERE     c.AuthorUserId = @UserId
				) AS crs
				CROSS JOIN ( SELECT MAX(ISNULL(b.PublishDate, b.AddOn)) AS LastBundlePublish
							 FROM   dbo.CRS_Bundles AS b
							 WHERE  b.AuthorId = @UserId
						   ) AS bnd
				CROSS JOIN ( SELECT MAX(ch.Created) AS LastChaperCreated
							 FROM   dbo.Courses AS c
									INNER JOIN dbo.CourseChapters AS ch ON c.Id = ch.CourseId
							 WHERE  ( c.AuthorUserId = @UserId )
						   ) AS chap
				CROSS JOIN ( SELECT MAX(ws.AddOn) AS LastFbStoreCreated
							 FROM   dbo.WebStores AS ws
									INNER JOIN dbo.ADMIN_RegistrationSourcesLOV AS src ON ws.RegistrationSourceId = src.RegistrationTypeId
							 WHERE  ( ws.OwnerUserID = @UserId )
									AND ( src.RegistrationTypeCode = 'FB' )
						   ) AS fbs
				CROSS JOIN ( SELECT MAX(ws.AddOn) AS LastStoreCreated
							 FROM   dbo.WebStores AS ws
									INNER JOIN dbo.ADMIN_RegistrationSourcesLOV AS src ON ws.RegistrationSourceId = src.RegistrationTypeId
							 WHERE  ( ws.OwnerUserID = @UserId )
									AND ( src.RegistrationTypeCode <> 'FB' )
						   ) AS nfbs
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DSC_GetAuhtorRooms]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-7
-- Description:	Get Author Class Rooms
-- =============================================
CREATE FUNCTION [dbo].[tvf_DSC_GetAuhtorRooms] ( @AuthorId INT )
RETURNS TABLE
AS
RETURN
    ( SELECT    cr.ClassRoomId ,
                cr.Name ,
                cr.IsActive ,
                cr.AuthorId ,
                cr.AddOn ,
                ISNULL(cu.cnt, 0) AS Cnt
      FROM      dbo.DSC_ClassRoom AS cr
                LEFT OUTER JOIN ( SELECT    ClassRoomId ,
                                            COUNT(Id) AS cnt
                                  FROM      dbo.Courses AS c
                                  GROUP BY  ClassRoomId
                                ) AS cu ON cr.ClassRoomId = cu.ClassRoomId
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DSC_GetHashtagMessages]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-30
-- Description:	Get hashtag messages by hashtagId
-- =============================================
CREATE FUNCTION [dbo].[tvf_DSC_GetHashtagMessages] ( @HashtagId BIGINT )
RETURNS TABLE
AS
RETURN
    ( 
			SELECT  m.MessageId ,
					m.ParentMessageId ,
					m.Uid ,
					m.ClassRoomId ,
					r.Name AS RoomName ,
					m.CourseId ,
					c.CourseName ,
					c.CourseUrlName ,
					m.MessageKindId ,
					m.Text ,
					m.HtmlMessage ,
					u.Id AS UserId ,
					u.Nickname ,
					u.FirstName ,
					u.LastName ,
					u.PictureURL ,
					u.FacebookID ,
					m.AddOn ,
					c.AuthorUserId AS CourseAuthorId ,
					r.AuthorId AS RoomAuthorId
			FROM    dbo.DSC_Messages AS m
					INNER JOIN dbo.Users AS u ON m.CreatedBy = u.Id
					INNER JOIN dbo.Courses AS c ON m.CourseId = c.Id
					INNER JOIN dbo.DSC_ClassRoom AS r ON m.ClassRoomId = r.ClassRoomId
			WHERE   ( m.MessageId IN 
											(
											  SELECT    ISNULL(m.ParentMessageId, m.MessageId) AS MessageId
											  FROM      dbo.DSC_MessageHashtags AS mh
														INNER JOIN dbo.DSC_Messages AS m ON mh.MessageId = m.MessageId
														INNER JOIN dbo.DSC_Hashtags AS h ON mh.HashtagId = h.HashtagId
											  WHERE     ( h.HashtagId = @HashtagId  )
											  GROUP BY  ISNULL(m.ParentMessageId, m.MessageId) 
											 ) 
					)
					OR 
					( m.ParentMessageId IN 
											(
											  SELECT    ISNULL(m.ParentMessageId, m.MessageId) AS MessageId
											  FROM      dbo.DSC_MessageHashtags AS mh
														INNER JOIN dbo.DSC_Messages AS m ON mh.MessageId = m.MessageId
														INNER JOIN dbo.DSC_Hashtags AS h ON mh.HashtagId = h.HashtagId
											  WHERE     ( h.HashtagId = @HashtagId)
											  GROUP BY  ISNULL(m.ParentMessageId, m.MessageId) 
											) 
					 )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DSC_GetMessage]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-9
-- Description:	Get message by UID
-- =============================================
CREATE FUNCTION [dbo].[tvf_DSC_GetMessage] ( @Uid UNIQUEIDENTIFIER )
RETURNS TABLE
AS
RETURN
    ( SELECT    m.MessageId ,
				m.ParentMessageId,
				m.Uid,
                m.ClassRoomId ,
                r.Name AS RoomName ,
                m.CourseId ,
                c.CourseName ,
                c.CourseUrlName ,
                m.MessageKindId ,
                m.Text ,
                m.HtmlMessage ,
                u.Id AS UserId ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
				u.PictureURL, 
				u.FacebookID ,
                m.AddOn,
				c.AuthorUserId AS CourseAuthorId,
				r.AuthorId AS RoomAuthorId
      FROM      dbo.DSC_Messages AS m
                INNER JOIN dbo.Users AS u ON m.CreatedBy = u.Id
                INNER JOIN dbo.Courses AS c ON m.CourseId = c.Id
                INNER JOIN dbo.DSC_ClassRoom AS r ON m.ClassRoomId = r.ClassRoomId
      WHERE     ( m.Uid = @Uid)
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DSC_GetMessageFeed]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-30
-- Description:	Get message feed by messageId
-- =============================================
CREATE FUNCTION [dbo].[tvf_DSC_GetMessageFeed] ( @MessageId BIGINT )
RETURNS TABLE
AS
RETURN
    ( 
			SELECT  m.MessageId ,
					m.ParentMessageId ,
					m.Uid ,
					m.ClassRoomId ,
					r.Name AS RoomName ,
					m.CourseId ,
					c.CourseName ,
					c.CourseUrlName ,
					m.MessageKindId ,
					m.Text ,
					m.HtmlMessage ,
					u.Id AS UserId ,
					u.Nickname ,
					u.FirstName ,
					u.LastName ,
					u.PictureURL ,
					u.FacebookID ,
					m.AddOn ,
					c.AuthorUserId AS CourseAuthorId ,
					r.AuthorId AS RoomAuthorId
			FROM    dbo.DSC_Messages AS m
					INNER JOIN dbo.Users AS u ON m.CreatedBy = u.Id
					INNER JOIN dbo.Courses AS c ON m.CourseId = c.Id
					INNER JOIN dbo.DSC_ClassRoom AS r ON m.ClassRoomId = r.ClassRoomId
			WHERE   (m.MessageId = @MessageId) OR (m.ParentMessageId = @MessageId)
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DSC_GetMessageNotifications4FB]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-15
-- Description:	Get user notifications for fb post by messageId
-- =============================================
CREATE FUNCTION [dbo].[tvf_DSC_GetMessageNotifications4FB] ( @MessageId BIGINT )
RETURNS TABLE
AS
RETURN
    ( 
		SELECT  un.UserId ,
				us.FacebookID ,
				un.NotificationId ,
				un.FbPostRequired ,
				un.FbPostSendOn ,
				msg.Uid ,
				msg.MessageId ,
				msg.Text AS MessageText ,
				up.Nickname AS PosterNickname ,
				up.FirstName AS PosterFirstName ,
				up.LastName AS PosterLastName ,
				msg.AddOn ,
				c.CourseName ,
				c.CourseUrlName ,
				c.SmallImage AS CourseThumbUrl,
				c.Description AS CourseDescription ,
				c.AuthorUserId ,
				dbo.Users.Nickname AS AuthorNickname ,
				dbo.Users.FirstName AS AuthorFirstName ,
				dbo.Users.LastName AS AuthorLastName
		FROM    dbo.Courses AS c
				INNER JOIN dbo.Users ON c.AuthorUserId = dbo.Users.Id
				RIGHT OUTER JOIN dbo.UserNotifications AS un
				INNER JOIN dbo.Users AS us ON un.UserId = us.Id
				INNER JOIN dbo.DSC_Messages AS msg ON un.MessageId = msg.MessageId
				INNER JOIN dbo.Users AS up ON msg.CreatedBy = up.Id ON c.Id = msg.CourseId
		WHERE   ( un.FbPostRequired = 1 )
				AND ( un.FbPostSendOn IS NULL )
				AND ( msg.MessageId = @MessageId )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_DSC_GetRoomMessages]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-9
-- Description:	Get ClassRoom messages
-- =============================================
CREATE FUNCTION [dbo].[tvf_DSC_GetRoomMessages] ( @RoomId INT )
RETURNS TABLE
AS
RETURN
    ( SELECT    m.MessageId ,
			    m.ParentMessageId,
				m.Uid,
                m.ClassRoomId ,
                r.Name AS RoomName ,
                m.CourseId ,
                c.CourseName ,
                c.CourseUrlName ,
                m.MessageKindId ,
                m.Text ,
                m.HtmlMessage ,
                u.Id AS UserId ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
				u.PictureURL, 
				u.FacebookID,
                m.AddOn,
				c.AuthorUserId AS CourseAuthorId,
				r.AuthorId AS RoomAuthorId
      FROM      dbo.DSC_Messages AS m
                INNER JOIN dbo.Users AS u ON m.CreatedBy = u.Id
                INNER JOIN dbo.Courses AS c ON m.CourseId = c.Id
                INNER JOIN dbo.DSC_ClassRoom AS r ON m.ClassRoomId = r.ClassRoomId
      WHERE     ( m.ClassRoomId = @RoomId )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_EMAIL_GetNotificationMessages]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-20
-- Description:	Get Email rows by messageId
-- =============================================
CREATE FUNCTION [dbo].[tvf_EMAIL_GetNotificationMessages] ( @MessageId BIGINT )
RETURNS TABLE
AS
RETURN
    (
		SELECT  n.NotificationId ,
				n.UserId ,
				u.Email ,
				u.Nickname ,
				u.FirstName ,
				u.LastName ,
				m.MessageId ,
				m.Text ,
				m.HtmlEmailMessage,
				m.CreatedBy AS PosterId ,
				a.Nickname AS PosterNickname ,
				a.FirstName AS PosterFirstName ,
				a.LastName AS PosterLastName ,
				m.AddOn
		FROM    dbo.UserNotifications AS n
				INNER JOIN dbo.Users AS u ON n.UserId = u.Id
				INNER JOIN dbo.DSC_Messages AS m ON n.MessageId = m.MessageId
				INNER JOIN dbo.Users AS a ON m.CreatedBy = a.Id
		WHERE   ( n.EmailRequired = 1 )
				AND ( n.EmailSendOn IS NULL )
                AND ( m.MessageId = @MessageId )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_DASH_GetNewPeriodTotals]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-18
-- Description:	Get totals for admin dashboard
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_DASH_GetNewPeriodTotals]
(	
	 @from DATE, @to DATE
)
RETURNS TABLE 
AS
RETURN 
(

	SELECT FactDate
		  ,NewAuthors
		  ,NewCourses
		  ,NewBundles
		  ,NewStores
		  ,NewLearners
		  ,NumOfOneTimeSales
		  ,NumOfSubscriptionSales
		  ,NumOfRentalSales
		  ,NumOfFreeSales
		  ,NewMailchimpLists
		  ,NewMBGJoined
		  ,MBGCancelled
	  FROM dbo.FACT_DASH_DailyTotalStats
	   WHERE     ( FactDate >= CAST(@from AS DATE) )
                AND ( FactDate <= CAST(@to AS DATE) )
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_DASH_GetPlatformStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-17
-- Description:	Get platform stats for Admin dashboard
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_DASH_GetPlatformStats] ( @from DATE, @to DATE )
RETURNS TABLE
AS
RETURN
    ( 
	  SELECT    FactDate,
				RegistrationTypeId ,
				TotalPlatformNew,
                NewAuthors ,
                TotalAuhtors ,
                NewItems ,
                TotalItems ,
                NewStores ,
                TotalStores ,
                NewLearners ,
                TotalLearners ,
                NewSales ,
                TotalSales
      FROM      dbo.FACT_DASH_DailyPlatformStats
      WHERE     ( FactDate >= CAST(@from AS DATE) )
                AND ( FactDate <= CAST(@to AS DATE) )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_DASH_GetTotals]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-18
-- Description:	Get totals for admin dashboard
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_DASH_GetTotals]
(		
)
RETURNS TABLE 
AS
RETURN 
(

	SELECT  dbo.fn_USER_CountByRole('Author') AS TotalAuthors ,
            dbo.fn_USER_CountByRole('Learner') AS TotalLearners ,
            c.TotalCourses ,
            b.TotalBundles ,
            s.TotalStores ,
            v.TotalVideos ,
            av.TotalAttached2ActiveCourses ,
            uv.UnattachedVideos ,
            vp.VideoPreviews
   FROM     ( SELECT    COUNT(Id) AS TotalCourses
              FROM      dbo.Courses
            ) c
            CROSS JOIN ( SELECT COUNT(BundleId) AS TotalBundles
                         FROM   CRS_Bundles
                       ) AS b
            CROSS JOIN ( SELECT COUNT(StoreID) AS TotalStores
                         FROM   dbo.WebStores
                       ) AS s
            CROSS JOIN ( SELECT COUNT(VideoId) AS TotalVideos
                         FROM   USER_Videos
                       ) AS v
            CROSS JOIN ( SELECT COUNT(VideoId) AS UnattachedVideos
                         FROM   USER_Videos
                         WHERE  Attached2Chapter = 0
                       ) AS uv
            CROSS JOIN ( SELECT COUNT(v.VideoId) AS TotalAttached2ActiveCourses
                         FROM   USER_Videos AS v
                         WHERE  EXISTS ( SELECT 1
                                         FROM   dbo.CourseChapters AS ch
                                                INNER JOIN dbo.ChapterVideos
                                                AS cv ON ch.Id = cv.CourseChapterId
                                         WHERE  ch.CourseId IN (
                                                SELECT  l.CourseId
                                                FROM    dbo.UserSessionsEventLogs
                                                        AS l
                                                        INNER JOIN dbo.UserEventTypesLOV
                                                        AS t ON l.EventTypeID = t.TypeId
                                                        INNER JOIN dbo.Courses
                                                        AS c ON l.CourseId = c.Id
                                                WHERE   ( t.TypeCode = N'VIDEO_COURSE_WATCH' )
                                                        AND ( l.EventDate >= DATEADD(MONTH,
                                                              -3, GETDATE()) )
                                                        AND ( l.CourseId IS NOT NULL )
                                                GROUP BY l.CourseId )
                                                AND ( cv.VideoSupplierIdentifier = v.BcIdentifier ) )
                       ) AS av
            CROSS JOIN ( SELECT COUNT(l.EventID) AS VideoPreviews
                         FROM   dbo.UserSessionsEventLogs AS l
                                INNER JOIN dbo.UserEventTypesLOV AS t ON l.EventTypeID = t.TypeId
                         WHERE  ( t.TypeCode = N'VIDEO_PREVIEW_WATCH' )
                                AND ( l.VideoBcIdentifier IS NOT NULL )
                       ) AS vp
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_GetAbandonHosts]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2015-3-8
-- Description:	Get host which left a system
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_GetAbandonHosts]
    (
      @FromDate DATE ,
      @LastEventDate DATE
    )
RETURNS TABLE
AS
RETURN
    ( 
	
		SELECT    ev.HostName ,
                ev.LastEventDate ,
                ev.FirstEventDate ,
                ev.UserId ,
                ev.Email ,
                1 AS WebStoreId ,
                ev.FirstName ,
                ev.LastName ,
                ev.TotalEvents ,
                ev.PreviewCount ,
                ISNULL(COUNT(c.Id), 0) AS TotalCourses
      FROM      ( SELECT    CAST(MAX(e.EventDate) AS DATE) AS LastEventDate ,
                            CAST(MIN(e.EventDate) AS DATE) AS FirstEventDate ,
                            COUNT(e.EventID) AS TotalEvents ,
                            COUNT(CASE et.TypeCode
                                    WHEN 'COURSE_PREVIEW_ENTER' THEN 1
                                    ELSE 0
                                  END) AS PreviewCount ,
                            dbo.fn_BASE_GetUrlHostName(s.HostName) AS HostName ,
                         --   e.WebStoreId ,
                            u.Email ,
                            u.FirstName ,
                            u.LastName ,
                            ws.OwnerUserID AS UserId
                  FROM      dbo.UserSessionsEventLogs AS e
                            INNER JOIN dbo.UserEventTypesLOV AS et ON e.EventTypeID = et.TypeId
                            INNER JOIN dbo.UserSessions AS s ON e.SessionId = s.SessionId
                            INNER JOIN dbo.WebStores AS ws ON e.WebStoreId = ws.StoreID
                            INNER JOIN dbo.Users AS u ON ws.OwnerUserID = u.Id
                  WHERE     ( s.HostName IS NOT NULL )
                            AND ( e.EventDate >= @FromDate )
                            AND ( s.HostName NOT LIKE 'http://editor.wix.com/html/editor%' )
                            AND ( s.HostName NOT LIKE 'http://127.0.0.1%' )
                            AND ( s.HostName LIKE 'http://%' )
                            AND ( et.TypeCode IN ( 'REGISTRATION_SUCCESS',
                                                   'PURCHASE_COMPLETE',
                                                   'COURSE_PREVIEW_ENTER',
                                                   'COURSE_VIEWER_ENTER',
                                                   'CHECKOUT_REGISTER',
                                                   'BUY_PAGE_ENTERED',
                                                   'STORE_VIEW' ) )
                  GROUP BY  s.HostName ,
                       --     e.WebStoreId ,
                            u.Email ,
                            u.FirstName ,
                            u.LastName ,
                            ws.OwnerUserID
                ) AS ev
                LEFT OUTER JOIN dbo.Courses AS c ON ev.UserId = c.AuthorUserId
      WHERE ( ev.LastEventDate < @LastEventDate )
	  GROUP BY  ev.HostName ,
                ev.LastEventDate ,
                ev.FirstEventDate ,
                ev.UserId ,
                ev.Email ,
             --   ev.WebStoreId ,
                ev.FirstName ,
                ev.LastName ,
                ev.TotalEvents ,
                ev.PreviewCount
     
     
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_FACT_GetDailySotreStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-4-9
-- Description:	Get daily store stats
-- =============================================
CREATE FUNCTION [dbo].[tvf_FACT_GetDailySotreStats] 
( 
	@EventDate DATE ,
    @WixOnly BIT	
)
RETURNS TABLE
AS
RETURN
( 
	 SELECT     ws.WixInstanceId ,
                ws.StoreID ,
                ws.uid ,
                ws.TrackingID ,
                ws.StoreName ,
                ws.StatusId ,
                ws.AddOn ,
                ws.WixSiteUrl ,
                s.StatusCode ,
                ws.OwnerUserID ,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName
      FROM      dbo.WebStores AS ws
                INNER JOIN dbo.Users AS u ON ws.OwnerUserID = u.Id
                INNER JOIN dbo.StatusLOV AS s ON ws.StatusId = s.StatusId
      WHERE   (CAST(ws.AddOn AS DATE) = CAST(@EventDate AS DATE))
			  AND (@WixOnly = 0 OR ws.WixInstanceId IS NOT NULL )
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_LOG_EmailInterface]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-9-24
-- Description:	Get email interface logs
-- =============================================
CREATE FUNCTION [dbo].[tvf_LOG_EmailInterface]
(	
	@from DATETIME, 
	@to DATETIME,
	@UserId INT = NULL,
	@Status VARCHAR(50) = NULL
)
RETURNS TABLE 
AS
RETURN 
(
	 SELECT  u.Email ,
			u.Nickname ,
			u.FirstName ,
			u.LastName ,
			u.PictureURL ,
			u.FacebookID ,
			e.EmailId ,
			e.UserId ,
			e.Subject ,
			e.ToEmail ,
			e.ToName ,
			e.MessageBoby ,
			e.Status ,
			e.Error ,
			e.AddOn ,
			e.SendOn
	FROM    dbo.Users AS u
			INNER JOIN dbo.EMAIL_Messages AS e ON u.Id = e.UserId
	WHERE   ( @UserId IS NULL OR e.UserId = @UserId)
			AND ( @Status IS NULL OR e.Status = @Status)
			AND ( e.AddOn BETWEEN @from AND @to )
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_LOG_FbPostInterface]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-9-24
-- Description:	Get FB posts interface logs
-- =============================================
CREATE FUNCTION [dbo].[tvf_LOG_FbPostInterface]
(	
	@from DATETIME, 
	@to DATETIME,
	@UserId INT = NULL,
	@Status VARCHAR(50) = NULL
)
RETURNS TABLE 
AS
RETURN 
(
	 SELECT u.Email ,
			u.Nickname ,
			u.FirstName ,
			u.LastName ,
			u.PictureURL ,
			u.FacebookID ,
			f.PostId ,
			f.Title ,
			f.Message ,
			f.LinkedName ,
			f.Caption ,
			f.Description ,
			f.ImageUrl ,
			f.Error ,
			f.FbPostId ,
			f.Status ,
			f.AddOn ,
			f.PostOn ,
			f.UpdateOn ,
			f.UserId
	 FROM   dbo.Users AS u
			INNER JOIN dbo.FB_PostInterface AS f ON u.Id = f.UserId
	 WHERE  ( @UserId IS NULL OR f.UserId = @UserId)
			AND ( @Status IS NULL OR f.Status = @Status)
			AND ( f.AddOn BETWEEN @from AND @to )
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_LOG_FileInterface]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-9-24
-- Description:	Get file interface logs
-- =============================================
CREATE FUNCTION [dbo].[tvf_LOG_FileInterface]
(	
	@from DATETIME, 
	@to DATETIME,
	@UserId INT = NULL,
	@Status VARCHAR(50) = NULL
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT  i.FileId ,
			i.UserId ,
			u.Email ,
			u.Nickname ,
			u.FirstName ,
			u.LastName ,
			u.PictureURL ,
			u.FacebookID ,
			i.FilePath ,
			i.ETag ,
			i.ContentType ,
			i.BcIdentifier ,
			i.FileSize ,
			i.Title ,
			i.Tags ,
			i.Status ,
			i.AddOn ,
			i.UpdateOn
	FROM    dbo.UserS3FileInterface AS i
			INNER JOIN dbo.Users AS u ON i.UserId = u.Id
	WHERE (@UserId IS NULL OR i.UserId=@UserId)
		  AND (@Status IS NULL OR i.Status=@Status)
		  AND ( i.AddOn BETWEEN @from AND @to )
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_PO_GetPayoutExecutions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-10-30
-- Description:	Get payout execution records
-- =============================================
CREATE FUNCTION [dbo].[tvf_PO_GetPayoutExecutions]
    (
      @ExecutionId INT = NULL
    )
RETURNS TABLE
AS
RETURN
    ( SELECT    ps.ExecutionId ,
                ps.PayoutYear ,
                ps.PayoutMonth ,
                ISNULL(t.TotalRows, 0) AS TotalRows ,
                ISNULL(s.TotalCompletedRows, 0) AS TotalCompletedRows ,
                ps.StatusId ,
                uu.Id ,
                ps.AddOn ,
                ps.CreatedBy ,
                ps.UpdateOn ,
                ps.UpdatedBy ,
                uc.FirstName AS CreatorFirstName ,
                uc.LastName AS CreatorLastName ,
                uu.FirstName AS UpdatedByFirstName ,
                uu.LastName AS UpdatedByLastName
      FROM      dbo.PO_PayoutExecutions AS ps
                LEFT OUTER JOIN ( SELECT    COUNT(1) AS TotalCompletedRows ,
                                            ps.ExecutionId
                                  FROM      dbo.PO_UserPayoutStatments AS ps
                                            INNER JOIN dbo.PO_PayoutStatusesLOV
                                            AS st ON st.StatusId = ps.StatusId
                                  WHERE     ( st.StatusCode = 'COMPLETED' )
                                  GROUP BY  ps.ExecutionId
                                ) AS s ON ps.ExecutionId = s.ExecutionId
                LEFT OUTER JOIN ( SELECT    COUNT(1) AS TotalRows ,
                                            ExecutionId
                                  FROM      dbo.PO_UserPayoutStatments AS pt
                                  GROUP BY  ExecutionId
                                ) AS t ON ps.ExecutionId = t.ExecutionId
                LEFT OUTER JOIN dbo.Users AS uu ON ps.UpdatedBy = uu.Id
                LEFT OUTER JOIN dbo.Users AS uc ON ps.CreatedBy = uc.Id
      WHERE     ( @ExecutionId IS NULL
                  OR ps.ExecutionId = @ExecutionId
                )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_PO_GetPayoutStatments]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-10-30
-- Description:	Get payout execution user records
-- =============================================
CREATE FUNCTION [dbo].[tvf_PO_GetPayoutStatments]
    (
      @ExecutionId INT
    )
RETURNS TABLE
AS
RETURN
    (
	 SELECT     ps.ExecutionId ,
                ps.StatusId ,
                uu.Id ,
                ps.PayoutId ,
                ps.UserId ,
				ps.PayKey,
                ub.Email ,
                ub.Nickname ,
                ub.FirstName ,
				ub.LastName,
                ps.Payout ,
                ps.PayoutTypeId ,
                ps.PaypalEmail ,
                ps.CurrencyId ,
                ps.ErrorMessage ,
                c.CurrencyCode ,
                c.ISO ,
                c.Symbol ,
				ps.AddOn ,
                ps.CreatedBy ,
                ps.UpdateOn ,
                ps.UpdatedBy ,
                uc.FirstName AS CreatorFirstName ,
                uc.LastName AS CreatorLastName ,
                uu.FirstName AS UpdatedByFirstName ,
                uu.LastName AS UpdatedByLastName 
      FROM      dbo.PO_UserPayoutStatments AS ps
                INNER JOIN dbo.Users AS ub ON ps.UserId = ub.Id
                INNER JOIN dbo.BASE_CurrencyLib AS c ON ps.CurrencyId = c.CurrencyId
                LEFT OUTER JOIN dbo.Users AS uu ON ps.UpdatedBy = uu.Id
                LEFT OUTER JOIN dbo.Users AS uc ON ps.CreatedBy = uc.Id
      WHERE     ( ps.ExecutionId = @ExecutionId)
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_QZ_GetAttemptQuestionAnswerOptions]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2015-1-21
-- Description:	Get user quest answer options
-- =============================================
CREATE FUNCTION [dbo].[tvf_QZ_GetAttemptQuestionAnswerOptions]
(
    @QuestId INT ,
    @AttemptID UNIQUEIDENTIFIER
)
RETURNS TABLE
AS
RETURN
( 
	SELECT    qa.OptionId ,
                qa.QuestionId ,
                qa.OptionText ,
				 CAST(CASE WHEN ans.OptionId IS NULL THEN 0
                          ELSE 1
                     END AS BIT) AS Selected
      FROM      dbo.QZ_QuestionAnswerOptions AS qa
                LEFT OUTER JOIN ( SELECT    QuestionId ,
                                            OptionId
                                  FROM      dbo.QZ_StudentQuizAnswers
                                  WHERE     AttemptId = @AttemptID
                                ) AS ans ON qa.QuestionId = ans.QuestionId
                                            AND qa.OptionId = ans.OptionId
      WHERE     ( qa.QuestionId = @QuestId )
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_QZ_GetStudentAttempt]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2015-1-21
-- Description:	Get student attempt data
-- =============================================
CREATE FUNCTION [dbo].[tvf_QZ_GetStudentAttempt]
    (
      @AttemptID UNIQUEIDENTIFIER
    )
RETURNS TABLE
AS
RETURN
    ( 
		SELECT  a.AttemptId ,
                a.IsSuccess ,
                a.Score ,
                a.StatusId ,
                a.StartOn ,
                a.FinishedOn ,
                sq.StudentQuizId ,
                sq.AvailableAttempts ,
                sq.RequestSendOn ,
                sq.ResponseSendOn ,
                q.PassPercent ,
                q.TimeLimit ,
                q.Title ,
                q.QuizId ,
                q.Attempts ,
                q.IsMandatory ,
                q.AttachCertificate ,
                ISNULL(c.UserAttempts, 0) AS UserAttempts ,
                crs.AuthorUserId ,
                u.Email AS AuthorEmail,
                u.Nickname AS AuthorNickname,
                u.FirstName AS AuthorFirstName,
                u.LastName AS AuthorLastName
      FROM      dbo.QZ_StudentQuizAttempts AS a
                INNER JOIN dbo.QZ_StudentQuizzes AS sq ON a.StudentQuizId = sq.StudentQuizId
                INNER JOIN dbo.QZ_CourseQuizzes AS q ON sq.QuizId = q.QuizId
                INNER JOIN ( SELECT COUNT(AttemptId) AS UserAttempts ,
                                    StudentQuizId
                             FROM   dbo.QZ_StudentQuizAttempts
                             GROUP BY StudentQuizId
                           ) AS c ON sq.StudentQuizId = c.StudentQuizId
                INNER JOIN dbo.Courses AS crs ON q.CourseId = crs.Id
                INNER JOIN dbo.Users AS u ON crs.AuthorUserId = u.Id
      WHERE     a.AttemptId = @AttemptID
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_QZ_GetStudentBestAttempt]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2015-2-3
-- Description:	Get student best attempt data
-- =============================================
CREATE FUNCTION [dbo].[tvf_QZ_GetStudentBestAttempt]
    (
      @QuizId UNIQUEIDENTIFIER ,
      @UserId INT
    )
RETURNS TABLE
AS
RETURN
( 
	
	  SELECT    best.AttemptId ,
                best.IsSuccess ,
                best.Score ,
                best.StatusId ,
                best.StartOn ,
                best.FinishedOn ,
				sq.StudentQuizId,
                sq.AvailableAttempts ,
				sq.RequestSendOn,
				sq.ResponseSendOn,
                q.PassPercent ,
                q.TimeLimit ,
                q.Title ,
                q.QuizId ,
                q.Attempts ,
				q.IsMandatory,
				q.AttachCertificate,
                ISNULL(c.UserAttempts, 0) AS UserAttempts,
				crs.AuthorUserId ,
                u.Email AS AuthorEmail,
                u.Nickname AS AuthorNickname,
                u.FirstName AS AuthorFirstName,
                u.LastName AS AuthorLastName
      FROM      ( SELECT    a.StudentQuizId ,
                            a.AttemptId ,
                            a.IsSuccess ,
                            a.Score ,
                            a.StatusId ,
                            a.StartOn ,
                            a.FinishedOn ,
                            ROW_NUMBER() OVER ( ORDER BY a.Score DESC ) AS rownum
                  FROM      dbo.QZ_StudentQuizAttempts AS a
                            INNER JOIN dbo.QZ_StudentQuizzes AS sq ON a.StudentQuizId = sq.StudentQuizId
                  WHERE     ( sq.QuizId = @QuizId )
                            AND ( sq.UserId = @UserId )
                ) AS best
                INNER JOIN dbo.QZ_StudentQuizzes AS sq ON best.StudentQuizId = sq.StudentQuizId
                INNER JOIN dbo.QZ_CourseQuizzes AS q ON sq.QuizId = q.QuizId
				INNER JOIN dbo.Courses AS crs ON q.CourseId = crs.Id
                INNER JOIN dbo.Users AS u ON crs.AuthorUserId = u.Id
                INNER JOIN ( SELECT COUNT(AttemptId) AS UserAttempts ,
                                    StudentQuizId
                             FROM   dbo.QZ_StudentQuizAttempts
                             GROUP BY StudentQuizId
                           ) AS c ON sq.StudentQuizId = c.StudentQuizId
      WHERE     rownum = 1
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_QZ_GetStudentQuizInfo]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2015-2-3
-- Description:	Get student quiz info
-- =============================================
CREATE FUNCTION [dbo].[tvf_QZ_GetStudentQuizInfo]
(
      @QuizId UNIQUEIDENTIFIER = NULL,      
	  @StudentQuizId UNIQUEIDENTIFIER = NULL,
	  @UserId INT = NULL
)
RETURNS TABLE
AS
RETURN
    ( 
		  SELECT    s.StudentQuizId ,
					s.Score ,
					s.UserId ,
					us.Email ,
					us.Nickname AS StudentNickname ,
					us.FirstName AS StudentFirstName ,
					us.LastName AS StudentLastName,
					s.IsSuccess ,
					s.LastAttemptStartDate ,
					s.RequestSendOn,
					s.ResponseSendOn,
					s.AvailableAttempts ,
					ISNULL(ac.UserAttempts, 0) AS UserAttempts ,
					q.QuizId ,
					q.Title ,
					q.PassPercent ,
					q.Attempts ,
					q.TimeLimit ,
					q.IsMandatory ,
					c.AuthorUserId ,
					ua.Email AS AuthorEmail ,
					ua.FirstName AS AuthorFirstName ,
					ua.LastName AS AuthorLastName ,
					ua.Nickname AS AuthorNickname 					
		  FROM      dbo.QZ_StudentQuizzes AS s
					INNER JOIN dbo.QZ_CourseQuizzes AS q ON s.QuizId = q.QuizId
					INNER JOIN dbo.Courses AS c ON q.CourseId = c.Id
					INNER JOIN dbo.Users AS ua ON c.AuthorUserId = ua.Id
					INNER JOIN dbo.Users AS us ON s.UserId = us.Id
					INNER JOIN ( SELECT COUNT(AttemptId) AS UserAttempts ,
										StudentQuizId
								 FROM   dbo.QZ_StudentQuizAttempts
								 GROUP BY StudentQuizId
							   ) AS ac ON s.StudentQuizId = ac.StudentQuizId
		  WHERE     (@QuizId IS NULL OR q.QuizId = @QuizId )
					AND (@StudentQuizId IS NULL OR s.StudentQuizId = @StudentQuizId)
					AND (@UserId IS NULL OR s.UserId = @UserId )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_SALE_GetLineCurrencyISO]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-5-30
-- Description:	Get ISO by order lineId
-- =============================================
CREATE FUNCTION [dbo].[tvf_SALE_GetLineCurrencyISO] ( @LineId INT )
RETURNS TABLE
AS
RETURN
    ( 
		SELECT    ISNULL(c.ISO, 'USD') AS ISO
		FROM      dbo.BASE_CurrencyLib AS c 
					INNER JOIN dbo.BILL_ItemsPriceList AS pl ON c.CurrencyId = pl.CurrencyId
					RIGHT OUTER JOIN dbo.SALE_OrderLines AS l ON pl.PriceLineId = l.PriceLineId
		WHERE     ( l.LineId = @LineId )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetAllCourseReviews]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Idan Tam
-- Create date: 2013-8-20
-- Description:	bring all  course reviews
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetAllCourseReviews] 
(	
	@CourseId INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT    c.Id AS CourseId ,
                c.CourseName ,
                c.AuthorUserId AS AuthorId,
                r.Id AS ReviewId ,
                r.ReviewDate ,
                r.ReviewRating ,
                r.ReviewTitle ,
                r.ReviewText ,
                u.Id AS LearnerId ,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName
      FROM      dbo.UserCourseReviews AS r
                INNER JOIN dbo.Users AS u ON r.UserId = u.Id
                INNER JOIN dbo.Courses AS c ON r.CourseId = c.Id
      WHERE     c.Id = @CourseId 
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetAllSubscribers]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-10-30
-- Description:	Get Author Subscribers
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetAllSubscribers] 
(
	 @AuthorId INT 
 )
RETURNS TABLE
AS
RETURN
    ( 
		 SELECT u.Id AS UserId,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
                u.FacebookID ,
                u.PictureURL ,
                u.AuthorPictureURL
      FROM      dbo.USER_Courses AS uc
                INNER JOIN dbo.Users AS u ON uc.UserId = u.Id
                INNER JOIN dbo.Courses AS c ON uc.CourseId = c.Id
      WHERE     ( c.AuthorUserId = @AuthorId )
      GROUP BY  u.Id ,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
                u.FacebookID ,
                u.PictureURL ,
                u.AuthorPictureURL     
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetAuthorsWithCourseCount]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-3
-- Description:	Get Authors with related courses count
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetAuthorsWithCourseCount] ( 
	@OnlyPublished BIT = 0
)
RETURNS TABLE
AS
RETURN
    ( 	 
	SELECT     u.Id ,
                u.Nickname ,
				u.FirstName ,
				u.LastName,
                ISNULL(cnt.cnt, 0) AS CoursesCnt,
                ISNULL(bcnt.cnt, 0) AS BundlesCnt
      FROM      (SELECT        COUNT(Id) AS cnt, AuthorUserId
				FROM            dbo.Courses AS c
				WHERE (@OnlyPublished = 0 OR c.StatusId=2)
				GROUP BY AuthorUserId
                ) AS cnt
                RIGHT OUTER JOIN dbo.Users AS u ON cnt.AuthorUserId = u.Id
				LEFT OUTER JOIN ( SELECT    AuthorId ,
                                            COUNT(BundleId) AS cnt
                                  FROM      dbo.CRS_Bundles
								  WHERE (@OnlyPublished = 0 OR StatusId=2)
                                  GROUP BY  AuthorId
                                ) AS bcnt ON bcnt.AuthorId = u.Id
      WHERE     ( ISNULL(cnt.cnt, 0) > 0 OR ISNULL(bcnt.cnt, 0) > 0 )
      GROUP BY  u.Id ,
                u.Nickname ,
				u.FirstName ,
				u.LastName,
                ISNULL(cnt.cnt, 0) ,
				ISNULL(bcnt.cnt, 0)  
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetBillingAddresses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-12-16
-- Description:	Get user billing addresses
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetBillingAddresses]
    (
      @UserId INT = NULL ,
      @AddressId INT = NULL
    )
RETURNS TABLE
AS
RETURN
    ( 
		SELECT      a.AddressId ,
					a.UserId ,
					a.CountryId ,
					c.CountryName ,
					c.A2 ,
					c.A3 ,
					a.StateId ,
					s.StateName ,
					s.StateCode ,
					a.FirstName ,
					a.LastName ,
					a.CityName ,
					a.Street1 ,
					a.Street2 ,
					a.PostalCode ,
					a.IsActive ,
					a.IsDefault ,
					a.Phone ,
					a.CellPhone ,
					a.Fax ,
					a.Email ,
					a.Region ,
					a.Description
		  FROM      dbo.GEO_CountriesLib AS c
					RIGHT OUTER JOIN dbo.USER_Addresses AS a ON c.CountryId = a.CountryId
					LEFT OUTER JOIN dbo.GEO_States AS s ON a.StateId = s.StateId
		  WHERE (@UserId IS NULL OR(a.UserId=@UserId) )
				AND (@AddressId IS NULL OR (a.AddressId=@AddressId)
    )
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetCourseReviews]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-6-9
-- Description:	bring course reviews
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetCourseReviews] (
	@from DATE, 
	@to DATE, 
	@AuthorId INT = NULL,
	@CourseId INT = NULL
)
RETURNS TABLE
AS
RETURN
    ( SELECT    c.Id AS CourseId ,
                c.CourseName ,
                c.AuthorUserId AS AuthorId,
                r.Id AS ReviewId ,
                r.ReviewDate ,
                r.ReviewRating ,
                r.ReviewTitle ,
                r.ReviewText ,
                u.Id AS LearnerId ,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName
      FROM      dbo.UserCourseReviews AS r
                INNER JOIN dbo.Users AS u ON r.UserId = u.Id
                INNER JOIN dbo.Courses AS c ON r.CourseId = c.Id
      WHERE    (ReviewDate BETWEEN @from  AND @to) 
			    AND (@AuthorId iS NULL OR c.AuthorUserId = @AuthorId )
				AND (@CourseId iS NULL OR c.Id = @CourseId )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetMonthlyStatementRefunds]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-5-5
-- Description:	Get user monthly statment refunds
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetMonthlyStatementRefunds]
(		
	@Year INT, 
	@Month INT ,
	@UserId INT,
	@CurrencyId SMALLINT  = 2 -- USD     
)
RETURNS TABLE 
AS
RETURN 
(
			SELECT     ISNULL(SUM(r.Amount),0) AS total,
					   ISNULL(SUM(ABS(r.Fee)),0) AS fee,
					   'REFUND' AS PaymentSource,
						r.SellerUserId 
			FROM      ( SELECT  rf.Amount ,
								trx.Fee,
								rf.RefundDate ,
								ro.SellerUserId
						FROM    dbo.SALE_OrderLinePayments AS rp
								INNER JOIN dbo.SALE_OrderLinePaymentRefunds AS rf ON rp.PaymentId = rf.PaymentId
								INNER JOIN dbo.SALE_OrderLines AS rl ON rp.OrderLineId = rl.LineId
								INNER JOIN dbo.SALE_Transactions AS trx ON rf.RefundId = trx.RefundId
								INNER JOIN dbo.SALE_Orders AS ro ON rl.OrderId = ro.OrderId
								INNER JOIN dbo.BILL_ItemsPriceList AS pl ON rl.PriceLineId = pl.PriceLineId
						WHERE  ( @UserId IS NULL OR ro.SellerUserId = @UserId)
								AND ( DATEPART(year,rf.RefundDate) = @Year ) 
								AND ( DATEPART(month,rf.RefundDate) = @Month )
								AND ( pl.CurrencyId IS NULL OR pl.CurrencyId = @CurrencyId ) 
					) AS r
			GROUP BY r.SellerUserId
               
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetNotification]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-11
-- Description:	Get user notifications
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetNotification] ( @MessageId INT )
RETURNS TABLE
AS
RETURN
    ( SELECT    m.MessageId ,
			    m.Uid,
                m.ClassRoomId ,
                r.Name AS RoomName ,
                m.CourseId ,
                c.CourseName ,
                c.CourseUrlName ,
                m.MessageKindId ,
                m.Text ,
                m.HtmlMessage ,
                u.Id AS UserId ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
                u.PictureURL ,
            	u.FacebookID ,
                m.AddOn ,
                un.IsRead
      FROM      dbo.DSC_Messages AS m
                INNER JOIN dbo.Users AS u ON m.CreatedBy = u.Id
                INNER JOIN dbo.Courses AS c ON m.CourseId = c.Id
                INNER JOIN dbo.DSC_ClassRoom AS r ON m.ClassRoomId = r.ClassRoomId
                INNER JOIN dbo.UserNotifications AS un ON m.MessageId = un.MessageId
      WHERE     ( m.MessageId = @MessageId )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetNotifications]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-11
-- Description:	Get user notifications
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetNotifications] ( @UserId INT )
RETURNS TABLE
AS
RETURN
    ( SELECT    m.MessageId ,
			    m.Uid,
                m.ClassRoomId ,
                r.Name AS RoomName ,
                m.CourseId ,
                c.CourseName ,
                c.CourseUrlName ,
                m.MessageKindId ,
                m.Text ,
                m.HtmlMessage ,
                u.Id AS UserId ,
                u.Nickname ,
                u.FirstName ,
                u.LastName ,
                u.PictureURL ,
            	u.FacebookID ,
                m.AddOn ,
                un.IsRead
      FROM      dbo.DSC_Messages AS m
                INNER JOIN dbo.Users AS u ON m.CreatedBy = u.Id
                INNER JOIN dbo.Courses AS c ON m.CourseId = c.Id
                INNER JOIN dbo.DSC_ClassRoom AS r ON m.ClassRoomId = r.ClassRoomId
                INNER JOIN dbo.UserNotifications AS un ON m.MessageId = un.MessageId
      WHERE     ( un.UserId = @UserId )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetUsers]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-6-1
-- Description:	Find users by id/status/type
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetUsers]
(	
	 @UserId INT = NULL
	,@StatusId INT = NULL
	,@TypeId INT = NULL
)
RETURNS TABLE 
AS
RETURN 
(

	SELECT u.Id
		  ,u.Email
		  ,u.Nickname
		  ,u.FirstName
		  ,u.LastName
		  ,u.ActivationToken
		  ,u.ActivationExpiration
		  ,u.FacebookID
		  ,u.StatusType
		  ,u.AffiliateCommission
		  ,u.PasswordDigest
		  ,u.PictureURL
		  ,u.BirthDate
		  ,u.Gender
		  ,u.BioHtml
		  ,u.AuthorPictureURL
		  ,u.AutoplayEnabled
		  ,u.UserTypeID
		  ,u.LastLogin
		  ,u.salesforce_id
		  ,u.salesforce_checksum
		  ,u.DisplayActivitiesOnFB
		  ,u.ReceiveMonthlyNewsletterOnEmail
		  ,u.DisplayDiscussionFeedDailyOnFB
		  ,u.ReceiveDiscussionFeedDailyOnEmail
		  ,u.DisplayCourseNewsWeeklyOnFB
		  ,u.ReceiveCourseNewsWeeklyOnEmail
		  ,u.RegistrationTypeId
		  ,u.RegisterStoreId
		  ,u.RegisterHostName
		  ,u.FbAccessToken
		  ,u.FbAccessTokenExpired
		  ,u.PayoutTypeId
		  ,u.PayoutAddressID
		  ,u.PaypalEmail
		  ,u.Created
		  ,u.LastModified
		  ,u.JoinedToRefundProgram
		  ,u.ProvisionUid
	FROM    dbo.Users AS u
			INNER JOIN dbo.UserStatusTypes AS s ON u.StatusType = s.Id
			INNER JOIN dbo.UserTypes AS t ON u.UserTypeID = t.id
	WHERE (@UserId IS NULL OR u.Id = @UserId)
			AND (@StatusId IS NULL OR u.StatusType=@StatusId)
			AND (@TypeId IS NULL OR u.UserTypeID = @TypeId)
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_GetVideos]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-6-1
-- Description:	Get User Videos
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_GetVideos] ( @UserId INT = NULL )
RETURNS TABLE
AS
RETURN
    ( 
		SELECT  crs.AuthorUserId,v.VideoSupplierIdentifier
		FROM    dbo.ChapterVideos AS v
				INNER JOIN dbo.CourseChapters AS ch ON v.CourseChapterId = ch.Id
				INNER JOIN dbo.Courses AS crs ON ch.CourseId = crs.Id
		WHERE   ( @UserId IS NULL OR crs.AuthorUserId = @UserId)
		GROUP BY crs.AuthorUserId ,
				v.VideoSupplierIdentifier  
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_USER_SearchVideos]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge
-- Create date: 2014-5-4
-- Description:	Search videos
-- =============================================
CREATE FUNCTION [dbo].[tvf_USER_SearchVideos]
    (
      @from DATETIME ,
      @to DATETIME ,
      @UserId INT = NULL ,
      @AttachedOnly BIT = NULL
    )
RETURNS TABLE
AS
RETURN
    ( 
		  SELECT    v.VideoId ,
					u.Id AS UserId ,
					v.BcIdentifier ,
					v.Name ,
					v.ThumbUrl ,
					v.Duration ,
					v.Attached2Chapter ,
					v.CreationDate ,
					u.Nickname ,
					u.FirstName ,
					u.LastName
			FROM      dbo.Users AS u
					INNER JOIN dbo.USER_Videos AS v ON u.Id = v.UserId
			WHERE     ( v.CreationDate BETWEEN @from AND @to )
					AND ( @UserId IS NULL OR v.UserId = @UserId)
					AND ( @AttachedOnly IS NULL OR v.Attached2Chapter = @AttachedOnly)
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_WS_GetAuthorNonIncludedCourses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno	
-- Create date: 2013-10-8
-- Description:	Get Author courses to be attach to store
-- =============================================
CREATE FUNCTION [dbo].[tvf_WS_GetAuthorNonIncludedCourses]
(	
	@StoreId INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT  c.Id AS CourseId
	FROM    dbo.WebStores AS ws
			INNER JOIN dbo.Courses AS c ON ws.OwnerUserID = c.AuthorUserId
	WHERE   ( ws.StoreID = @StoreId )
			AND ( 
					c.Id NOT IN (
								  SELECT    sc.CourseID
								  FROM      dbo.WebStoreItems AS sc
												INNER JOIN dbo.WebStoreCategories AS c 
													ON sc.WebStoreCategoryID = c.WebStoreCategoryID
								  WHERE     ( c.WebStoreID = @StoreId ) 
								 ) 
				 )
)

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_WS_GetCoursesByAuthor]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno	
-- Create date: 2013-8-3
-- Description:	Get Courses by authorId for WebStore Category contents
-- =============================================
CREATE FUNCTION [dbo].[tvf_WS_GetCoursesByAuthor]
    (
      @AuthorId INT ,
      @WebStoreCategoryId INT
    )
RETURNS TABLE
AS
RETURN
    ( 
	
		 SELECT  c.Id AS ItemId,
				 c.ProvisionUid,
				 c.CourseName AS ItemName,
                 wcc.WebstoreItemId,
				 'COURSE' AS ItemType,
				 c.StatusId
		  FROM      dbo.Courses AS c
					LEFT OUTER JOIN ( SELECT    CourseID ,
												WebStoreCategoryID ,
												WebstoreItemId
									  FROM      dbo.WebStoreItems AS wc
									  WHERE     ( WebStoreCategoryID = @WebStoreCategoryId )
									) AS wcc ON c.Id = wcc.CourseID
		  WHERE     ( c.AuthorUserId = @AuthorId )

		  UNION

		 SELECT    c.BundleId AS ItemId,
				   c.ProvisionUid,
					c.BundleName AS ItemName,
					wcc.WebstoreItemId,
					'BUNDLE' AS ItemType,
					c.StatusId
		  FROM      dbo.CRS_Bundles AS c
					LEFT OUTER JOIN ( SELECT    BundleId ,
												WebStoreCategoryID ,
												WebstoreItemId
									  FROM      dbo.WebStoreItems AS wc
									  WHERE     ( WebStoreCategoryID = @WebStoreCategoryId )
									) AS wcc ON c.BundleId = wcc.BundleId
		  WHERE     ( c.AuthorId = @AuthorId )
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_WS_GetCoursesByCategory]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno	
-- Create date: 2013-8-3
-- Description:	Get Courses by categoryId for WebStore Category contents
-- =============================================
CREATE FUNCTION [dbo].[tvf_WS_GetCoursesByCategory]
    (
      @CategoryId INT ,
      @WebStoreCategoryId INT
    )
RETURNS TABLE
AS
RETURN
    ( 
	 SELECT     c.Id AS ItemId,
				c.ProvisionUid,
				c.CourseName AS ItemName,
                wcc.WebstoreItemId,
				'COURSE' AS ItemType,
				c.StatusId
      FROM      dbo.CourseCategories AS cc
                INNER JOIN dbo.Courses AS c ON cc.CourseId = c.Id
                LEFT OUTER JOIN ( SELECT    CourseID ,
                                            WebstoreItemId
                                  FROM      dbo.WebStoreItems AS wc
                                  WHERE     ( WebStoreCategoryID = @WebStoreCategoryId )
                                ) AS wcc ON c.Id = wcc.CourseID
      WHERE     ( cc.CategoryId = @CategoryId )

	  UNION

	  SELECT    c.BundleId AS ItemId,
				c.ProvisionUid,
                c.BundleName AS ItemName,
                wcc.WebstoreItemId,
				'BUNDLE' AS ItemType,
				c.StatusId
      FROM      dbo.CRS_BundleCategories AS cc
                INNER JOIN dbo.CRS_Bundles AS c ON cc.BundleId = c.BundleId
                LEFT OUTER JOIN ( SELECT    BundleId ,
                                            WebstoreItemId
                                  FROM      dbo.WebStoreItems AS wc
                                  WHERE     ( WebStoreCategoryID = @WebStoreCategoryId )
                                ) AS wcc ON c.BundleId = wcc.BundleId
      WHERE     ( cc.CategoryId = @CategoryId )
		
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_WS_GetStores]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-1
-- Description:	Get WebStores report data
-- =============================================
CREATE FUNCTION [dbo].[tvf_WS_GetStores] ( @OwnerId INT = NULL)
RETURNS TABLE
AS
RETURN
    (
	SELECT  ws.StoreID ,
			ws.uid ,
			ws.TrackingID,
			ws.StoreName ,
			ws.AddOn ,
			ws.OwnerUserID ,
			ws.StatusId ,
			ws.DefaultCurrencyId,
			s.StatusName ,
			cn.cnt AS C_Courses ,
			0 AS C_Subscribers ,
			u.Nickname ,
			u.FirstName ,
			u.LastName,
			ws.WixSiteUrl
	FROM    dbo.WebStores AS ws
			INNER JOIN dbo.StatusLOV AS s ON ws.StatusId = s.StatusId
			INNER JOIN dbo.Users AS u ON ws.OwnerUserID = u.Id
			LEFT OUTER JOIN ( SELECT    COUNT(wcs.WebstoreItemId) AS cnt ,
										wct.WebStoreID
							  FROM      dbo.WebStoreItems AS wcs
										INNER JOIN dbo.WebStoreCategories AS wct ON wcs.WebStoreCategoryID = wct.WebStoreCategoryID
							  GROUP BY  wct.WebStoreID
							) AS cn ON ws.StoreID = cn.WebStoreID
	  WHERE (@OwnerId IS NULL OR ws.OwnerUserID = @OwnerId)
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_WS_GetUserAffiliateItems]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-2-3
-- Description:	Get user items in affiliates stores
-- =============================================
CREATE FUNCTION [dbo].[tvf_WS_GetUserAffiliateItems] 
( 
  @CurrencyId SMALLINT = 2 -- USD
 ,@UserId INT 
)
RETURNS TABLE
AS
RETURN
    ( SELECT    i.WebstoreItemId ,
                i.LineType ,
                i.ItemId ,
				i.ProvisionUid,
                i.ItemName ,
                i.ItemUrlName ,
                dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@CurrencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
				dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@CurrencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
                i.StoreID ,
                i.TrackingID ,
                i.StoreName ,
                i.OwnerUserID ,
                i.OwnerNickName ,
                i.OwnerFirstName ,
                i.OwnerLastName ,
                i.WebStoreCategoryID ,
                i.CategoryName ,
                i.CategoryUrlName ,
                i.AuthorId ,
                i.AuthorNickName ,
                i.AuthorFirstName ,
                i.AuthorLastName
      FROM      ( SELECT    si.WebstoreItemId ,
                            'COURSE' AS LineType ,
                            si.CourseId AS ItemId ,
							c.ProvisionUid,
							1 AS ItemTypeId, 
                            c.CourseName AS ItemName ,
                            c.CourseUrlName AS ItemUrlName ,                           
                            s.StoreID ,
                            s.TrackingID ,
                            s.StoreName ,
                            s.OwnerUserID ,
                            su.Nickname AS OwnerNickName ,
                            su.FirstName AS OwnerFirstName ,
                            su.LastName AS OwnerLastName ,
                            sc.WebStoreCategoryID ,
                            sc.CategoryName ,
                            sc.CategoryUrlName ,
                            c.AuthorUserId AS AuthorId ,
                            ua.Nickname AS AuthorNickName ,
                            ua.FirstName AS AuthorFirstName ,
                            ua.LastName AS AuthorLastName
                  FROM      dbo.Courses AS c
                            INNER JOIN dbo.WebStoreItems AS si ON c.Id = si.CourseId
                            INNER JOIN dbo.WebStoreCategories AS sc ON si.WebStoreCategoryID = sc.WebStoreCategoryID
                            INNER JOIN dbo.WebStores AS s ON sc.WebStoreID = s.StoreID
                            INNER JOIN dbo.Users AS su ON s.OwnerUserID = su.Id
                            INNER JOIN dbo.Users AS ua ON c.AuthorUserId = ua.Id
                  WHERE     ( c.AuthorUserId = @UserId )
                            AND ( s.OwnerUserID <> @UserId )
                  UNION
                  SELECT    si.WebstoreItemId ,
                            'BUNDLE' AS LineType ,
                            si.BundleId AS ItemId ,
							b.ProvisionUid,
							2 AS ItemTypeId, 
                            b.BundleName AS ItemName ,
                            b.BundleUrlName AS ItemUrlName ,                         
                            s.StoreID ,
                            s.TrackingID ,
                            s.StoreName ,
                            s.OwnerUserID ,
                            su.Nickname AS OwnerNickName ,
                            su.FirstName AS OwnerFirstName ,
                            su.LastName AS OwnerLastName ,
                            sc.WebStoreCategoryID ,
                            sc.CategoryName ,
                            sc.CategoryUrlName ,
                            b.AuthorId ,
                            ua.Nickname AS AuthorNickName ,
                            ua.FirstName AS AuthorFirstName ,
                            ua.LastName AS AuthorLastName
                  FROM      dbo.Users AS ua
                            INNER JOIN dbo.CRS_Bundles AS b ON ua.Id = b.AuthorId
                            INNER JOIN dbo.WebStoreCategories AS sc
                            INNER JOIN dbo.WebStoreItems AS si ON sc.WebStoreCategoryID = si.WebStoreCategoryID
                            INNER JOIN dbo.WebStores AS s ON sc.WebStoreID = s.StoreID
                            INNER JOIN dbo.Users AS su ON s.OwnerUserID = su.Id ON b.BundleId = si.BundleId
                  WHERE     ( b.AuthorId = @UserId )
                            AND ( s.OwnerUserID <> @UserId )
                ) AS i
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_WS_GetUserAffiliateStoresLOV]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-2-3
-- Description:	get user affiliate stores LOV
-- =============================================
CREATE FUNCTION [dbo].[tvf_WS_GetUserAffiliateStoresLOV] ( @UserId INT )
RETURNS TABLE
AS
RETURN
    ( SELECT    s.StoreID ,
                s.TrackingID ,
                s.StoreName
      FROM      dbo.CRS_Bundles AS b
                INNER JOIN dbo.WebStoreCategories AS sc
                INNER JOIN dbo.WebStoreItems AS si ON sc.WebStoreCategoryID = si.WebStoreCategoryID
                INNER JOIN dbo.WebStores AS s ON sc.WebStoreID = s.StoreID ON b.BundleId = si.BundleId
      WHERE     ( s.OwnerUserID <> @UserId )
                AND ( b.AuthorId = @UserId )
      GROUP BY  s.StoreID ,
                s.TrackingID ,
                s.StoreName
      UNION
      SELECT    s.StoreID ,
                s.TrackingID ,
                s.StoreName
      FROM      dbo.Courses AS b
                INNER JOIN dbo.WebStoreCategories AS sc
                INNER JOIN dbo.WebStoreItems AS si ON sc.WebStoreCategoryID = si.WebStoreCategoryID
                INNER JOIN dbo.WebStores AS s ON sc.WebStoreID = s.StoreID ON b.Id = si.CourseId
      WHERE     ( s.OwnerUserID <> @UserId )
                AND ( b.AuthorUserId = @UserId )
      GROUP BY  s.StoreID ,
                s.TrackingID ,
                s.StoreName
    )

GO
/****** Object:  UserDefinedFunction [dbo].[tvf_WS_GetWixStores]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-2-7
-- Description:	Stores registered in WIX
-- =============================================
CREATE FUNCTION [dbo].[tvf_WS_GetWixStores] ( @OwnerId INT = NULL )
RETURNS TABLE
AS
RETURN
( 
	  SELECT    ws.WixInstanceId ,
                ws.StoreID ,
                ws.uid ,
                ws.TrackingID ,
                ws.StoreName ,
                ws.StatusId ,
				ws.AddOn,
				ws.WixSiteUrl,
                s.StatusCode ,
                ws.OwnerUserID ,
                u.Email ,
                u.Nickname ,
                u.FirstName ,
                u.LastName
      FROM      dbo.WebStores AS ws
                INNER JOIN dbo.Users AS u ON ws.OwnerUserID = u.Id
                INNER JOIN dbo.StatusLOV AS s ON ws.StatusId = s.StatusId
      WHERE     ( ws.WixInstanceId IS NOT NULL )
                AND ( @OwnerId IS NULL OR ws.OwnerUserID = @OwnerId)
)

GO
/****** Object:  View [dbo].[v_AuthirsOfLast90daysCourses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[v_AuthirsOfLast90daysCourses]
AS
SELECT c.CourseName, c.AuthorUserId, u.FirstName, u.LastName, u.Email, s.StatusName, c.PublishDate
  FROM dbo.Courses AS c
  JOIN dbo.StatusLOV AS s ON s.StatusId = c.StatusId 
  JOIN dbo.Users AS u On u.Id = c.AuthorUserId
    LEFT JOIN dbo.USER_Addresses AS ua ON ua.UserId = c.AuthorUserId
    
 WHERE DATEDIFF(DAY, c.Created, GETDATE()) <= 90 


GO
/****** Object:  View [dbo].[v_Events_URL]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_Events_URL]
AS
SELECT TOP 100 PERCENT AubsoluteUri, TypeName, event_amount 
  FROM (SELECT AubsoluteUri, et.TypeName, COUNT(*) AS  event_amount, TypeId 
		  FROM dbo.UserSessionsEventLogs AS l
		  JOIN dbo.UserEventTypesLOV AS et ON l.EventTypeID = et.TypeId
		 WHERE AubsoluteUri IS NOT NULL
		GROUP BY AubsoluteUri, et.TypeName, TypeId 
		UNION
		SELECT AubsoluteUri, 'Total', COUNT(*), 999 
		  FROM dbo.UserSessionsEventLogs
		 WHERE AubsoluteUri IS NOT NULL
		GROUP BY AubsoluteUri) AS s
 ORDER BY AubsoluteUri, TypeId

GO
/****** Object:  View [dbo].[vw_CERT_StudentCertificates]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_CERT_StudentCertificates]
AS
SELECT        sc.StudentCertificateId, sc.UserId AS StudentUserId, su.Email AS StudentEmail, su.Nickname AS StudentNickname, su.FirstName AS StudentFirstName, 
                         su.LastName AS StudentLastName, sc.CertificateId, sc.TemplateId, sc.Title, sc.CourseName, sc.SitgnatureUrl, sc.PresentedBy, sc.Description, sc.SendOn, 
                         crs.AuthorUserId, au.Email AS AuthorEmail, au.Nickname AS AuthorNickname, au.FirstName AS AuthorFirstName, au.LastName AS AuthorLastName, cert.CourseId, 
                         t.ImageName AS TemplateImageName, sc.AddOn
FROM            dbo.CERT_CertificateLib AS cert INNER JOIN
                         dbo.CERT_StudentCertificates AS sc ON cert.CertificateId = sc.CertificateId INNER JOIN
                         dbo.Courses AS crs ON cert.CourseId = crs.Id INNER JOIN
                         dbo.Users AS su ON sc.UserId = su.Id INNER JOIN
                         dbo.Users AS au ON crs.AuthorUserId = au.Id INNER JOIN
                         dbo.CERT_TemplatesLOV AS t ON sc.TemplateId = t.TemplateId

GO
/****** Object:  View [dbo].[vw_DSC_MessageHashtags]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_DSC_MessageHashtags]
AS
SELECT        m.MessageId, t.HashtagId AS HashtagId, t.HashTag
FROM            dbo.DSC_MessageHashtags AS m INNER JOIN
                         dbo.DSC_Hashtags AS t ON m.HashtagId = t.HashtagId

GO
/****** Object:  View [dbo].[vw_FACT_DASH_UserLogins]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_FACT_DASH_UserLogins]
AS
SELECT        TOP (100) PERCENT u.Id AS UserId, ISNULL(p.LastLogin, u.LastLogin) AS LastLogin
FROM            dbo.Users AS u LEFT OUTER JOIN
                         dbo.UserProfile AS p ON p.RefUserId = u.Id

GO
/****** Object:  View [dbo].[vw_QZ_QuizQuestionsLib]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_QZ_QuizQuestionsLib]
AS
SELECT        q.QuestionId, q.QuizId, qz.Sid AS QuizSid, q.TypeId, q.QuestionText, q.Score, q.Description, q.BcIdentifier, q.ImageUrl, q.OrderIndex, q.IsActive, q.AddOn, 
                         ISNULL(ans.cnt, 0) AS TotalAnswers, ISNULL(ans.CorrectAnswer, 0) AS CorrectAnswer
FROM            dbo.QZ_QuizQuestionsLib AS q INNER JOIN
                         dbo.QZ_CourseQuizzes AS qz ON q.QuizId = qz.QuizId LEFT OUTER JOIN
                             (SELECT        COUNT(a.OptionId) AS cnt, COUNT(ca.OptionId) AS CorrectAnswer, a.QuestionId
                               FROM            dbo.QZ_QuestionAnswerOptions AS a LEFT OUTER JOIN
                                                             (SELECT        OptionId, QuestionId
                                                               FROM            dbo.QZ_QuestionAnswerOptions AS c
                                                               WHERE        (IsCorrect = 1)) AS ca ON ca.QuestionId = a.QuestionId AND ca.OptionId = a.OptionId
                               GROUP BY a.QuestionId) AS ans ON ans.QuestionId = q.QuestionId

GO
ALTER TABLE [dbo].[ADMIN_DeletedVideosLog] ADD  CONSTRAINT [DF_ADMIN_DeletedVideosLog_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[ADMIN_RegistrationSourcesLOV] ADD  CONSTRAINT [DF_ADMIN_RegistrationSourcesLOV_IsActive]  DEFAULT ((1)) FOR [IncludeInStats]
GO
ALTER TABLE [dbo].[APP_PluginInstallations] ADD  CONSTRAINT [DF_APP_PluginInstallations_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BASE_CurrencyLib] ADD  CONSTRAINT [DF_CurrencyLib_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BASE_CurrencyLib] ADD  CONSTRAINT [DF_BASE_CurrencyLib_KeepDecimal]  DEFAULT ((1)) FOR [KeepDecimal]
GO
ALTER TABLE [dbo].[BASE_CurrencyLib] ADD  CONSTRAINT [DF_CurrencyLib_InsertDate]  DEFAULT (getdate()) FOR [InsertDate]
GO
ALTER TABLE [dbo].[BILL_ItemsPriceList] ADD  CONSTRAINT [DF_BILL_ItemsPriceList_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[BILL_ItemsPriceList] ADD  CONSTRAINT [DF_BILL_ItemsPriceList_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[Categories] ADD  CONSTRAINT [DF_Categories_IsOnHomePage]  DEFAULT ((1)) FOR [IsOnHomePage]
GO
ALTER TABLE [dbo].[Categories] ADD  CONSTRAINT [DF_Categories_Ordinal]  DEFAULT ((0)) FOR [Ordinal]
GO
ALTER TABLE [dbo].[Categories] ADD  CONSTRAINT [DF_Categories_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[CERT_CertificateLib] ADD  CONSTRAINT [DF_QZ_CertificateLib_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[CERT_TemplatesLOV] ADD  CONSTRAINT [DF_QZ_CertificateTemplatesLOV_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[CERT_TemplatesLOV] ADD  CONSTRAINT [DF_QZ_CertificateTemplatesLOV_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[ChapterLinks] ADD  CONSTRAINT [DF_ChapterLinks_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[ChapterVideos] ADD  CONSTRAINT [DF_ChapterVideos_IsOpen]  DEFAULT ((0)) FOR [IsOpen]
GO
ALTER TABLE [dbo].[ChapterVideos] ADD  CONSTRAINT [DF_ChapterVideos_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[CHIMP_ListSegments] ADD  CONSTRAINT [DF_CHIMP_ListSegments_TotalSubscribers]  DEFAULT ((0)) FOR [TotalSubscribers]
GO
ALTER TABLE [dbo].[CHIMP_SegmentTypesLOV] ADD  CONSTRAINT [DF_CHIMP_SegmentTypesLOV_IsStatic]  DEFAULT ((0)) FOR [IsStatic]
GO
ALTER TABLE [dbo].[CHIMP_UserLists] ADD  CONSTRAINT [DF_CHIMP_UserLists_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[CHIMP_UserLists] ADD  CONSTRAINT [DF_CHIMP_UserLists_TotalSubscribers]  DEFAULT ((0)) FOR [TotalSubscribers]
GO
ALTER TABLE [dbo].[CouponInstances] ADD  CONSTRAINT [DF_CouponInstances_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[Coupons] ADD  CONSTRAINT [DF_Coupons_AutoGenerate]  DEFAULT ((0)) FOR [AutoGenerate]
GO
ALTER TABLE [dbo].[Coupons] ADD  CONSTRAINT [DF_Coupons_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[CourseChapters] ADD  CONSTRAINT [DF_CourseChapters_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Courses] ADD  CONSTRAINT [DF_Courses_uid]  DEFAULT (newid()) FOR [uid]
GO
ALTER TABLE [dbo].[Courses] ADD  CONSTRAINT [DF_Courses_IsFreeCourse]  DEFAULT ((0)) FOR [IsFreeCourse]
GO
ALTER TABLE [dbo].[Courses] ADD  CONSTRAINT [DF_Courses_IsDownloadEnabled]  DEFAULT ((0)) FOR [IsDownloadEnabled]
GO
ALTER TABLE [dbo].[Courses] ADD  CONSTRAINT [DF_Courses_AffiliateCommission]  DEFAULT ((30)) FOR [AffiliateCommission]
GO
ALTER TABLE [dbo].[Courses] ADD  CONSTRAINT [DF_Courses_DisplayOtherLearnersTab]  DEFAULT ((1)) FOR [DisplayOtherLearnersTab]
GO
ALTER TABLE [dbo].[Courses] ADD  CONSTRAINT [DF_Courses_FbPublish]  DEFAULT ((0)) FOR [FbObjectPublished]
GO
ALTER TABLE [dbo].[Courses] ADD  CONSTRAINT [DF_Courses_StatusId]  DEFAULT ((1)) FOR [StatusId]
GO
ALTER TABLE [dbo].[CRS_Assets] ADD  CONSTRAINT [DF_CRS_Assets_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[CRS_Assets] ADD  CONSTRAINT [DF_CRS_Assets_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[CRS_Bundles] ADD  CONSTRAINT [DF_CRS_Bundles_uid]  DEFAULT (newid()) FOR [uid]
GO
ALTER TABLE [dbo].[CRS_Bundles] ADD  CONSTRAINT [DF_CRS_Bundles_AffiliateCommission]  DEFAULT ((30)) FOR [AffiliateCommission]
GO
ALTER TABLE [dbo].[CRS_Bundles] ADD  CONSTRAINT [DF_CRS_Bundles_FbObjectPublished]  DEFAULT ((0)) FOR [FbObjectPublished]
GO
ALTER TABLE [dbo].[CRS_Bundles] ADD  CONSTRAINT [DF_CRS_Bundles_StatusId]  DEFAULT ((1)) FOR [StatusId]
GO
ALTER TABLE [dbo].[CRS_Bundles] ADD  CONSTRAINT [DF_CourseBundles_Created]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[CRS_WizardStepsLOV] ADD  CONSTRAINT [DF_CRS_WizardSteps_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[DROP_Jobs] ADD  CONSTRAINT [DF_DROP_Jobs_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[DSC_Messages] ADD  CONSTRAINT [DF_DSC_Messages_Uid]  DEFAULT (newid()) FOR [Uid]
GO
ALTER TABLE [dbo].[EMAIL_TemplateKindsLOV] ADD  CONSTRAINT [DF_EMAIL_TemplateKindsLOV_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[EMAIL_Templates] ADD  CONSTRAINT [DF_EMAIL_Templates_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[FACT_DailyStats] ADD  CONSTRAINT [DF_FACT_DailyStats_ItemsCreated]  DEFAULT ((0)) FOR [ItemsCreated]
GO
ALTER TABLE [dbo].[FACT_DailyStats] ADD  CONSTRAINT [DF_FACT_DailyStats_ItemsPublished]  DEFAULT ((0)) FOR [ItemsPublished]
GO
ALTER TABLE [dbo].[FACT_DailyStats] ADD  CONSTRAINT [DF_FACT_DailyStats_UsersCreated]  DEFAULT ((0)) FOR [UsersCreated]
GO
ALTER TABLE [dbo].[FACT_DailyStats] ADD  CONSTRAINT [DF_FACT_DailyStats_WixUsersCreated]  DEFAULT ((0)) FOR [WixUsersCreated]
GO
ALTER TABLE [dbo].[FACT_DailyStats] ADD  CONSTRAINT [DF_FACT_DailyStats_UserLogins]  DEFAULT ((0)) FOR [UserLogins]
GO
ALTER TABLE [dbo].[FACT_DailyStats] ADD  CONSTRAINT [DF_FACT_DailyStats_ReturnUsersLogins]  DEFAULT ((0)) FOR [ReturnUsersLogins]
GO
ALTER TABLE [dbo].[FACT_DailyStats] ADD  CONSTRAINT [DF_FACT_DailyStats_ItemsPurchased]  DEFAULT ((0)) FOR [ItemsPurchased]
GO
ALTER TABLE [dbo].[FACT_DailyStats] ADD  CONSTRAINT [DF_FACT_DailyStats_StoresCreated]  DEFAULT ((0)) FOR [StoresCreated]
GO
ALTER TABLE [dbo].[FACT_DailyStats] ADD  CONSTRAINT [DF_FACT_DailyStats_StoresCreated1]  DEFAULT ((0)) FOR [WixStoresCreated]
GO
ALTER TABLE [dbo].[FACT_DailyTotals] ADD  CONSTRAINT [DF_Table_1_TotalCourses]  DEFAULT ((0)) FOR [TotalItems]
GO
ALTER TABLE [dbo].[FACT_DailyTotals] ADD  CONSTRAINT [DF_FACT_Totals_TotalPublished]  DEFAULT ((0)) FOR [TotalPublished]
GO
ALTER TABLE [dbo].[FACT_DailyTotals] ADD  CONSTRAINT [DF_FACT_Totals_Attached2Stores]  DEFAULT ((0)) FOR [Attached2Stores]
GO
ALTER TABLE [dbo].[FACT_DailyTotals] ADD  CONSTRAINT [DF_FACT_Totals_Attached2WixStores]  DEFAULT ((0)) FOR [Attached2WixStores]
GO
ALTER TABLE [dbo].[FACT_DailyTotals] ADD  CONSTRAINT [DF_FACT_Totals_TotalUsers]  DEFAULT ((0)) FOR [TotalUsers]
GO
ALTER TABLE [dbo].[FACT_DailyTotals] ADD  CONSTRAINT [DF_FACT_DailyTotals_ItemsPurchased]  DEFAULT ((0)) FOR [ItemsPurchased]
GO
ALTER TABLE [dbo].[FACT_DailyTotals] ADD  CONSTRAINT [DF_FACT_DailyTotals_StoresCreated]  DEFAULT ((0)) FOR [StoresCreated]
GO
ALTER TABLE [dbo].[FACT_DailyTotals] ADD  CONSTRAINT [DF_FACT_DailyTotals_WixStoresCreated]  DEFAULT ((0)) FOR [WixStoresCreated]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyPlatformStats_TotalPlatformNew]  DEFAULT ((0)) FOR [TotalPlatformNew]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyStats_NewAuthors]  DEFAULT ((0)) FOR [NewAuthors]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyStats_TotalAuhtors]  DEFAULT ((0)) FOR [TotalAuhtors]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyStats_NewItems]  DEFAULT ((0)) FOR [NewItems]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyStats_TotalItems]  DEFAULT ((0)) FOR [TotalItems]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyStats_NewStores]  DEFAULT ((0)) FOR [NewStores]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyStats_TotalStores]  DEFAULT ((0)) FOR [TotalStores]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyStats_NewLearners]  DEFAULT ((0)) FOR [NewLearners]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyStats_TotalLearners]  DEFAULT ((0)) FOR [TotalLearners]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyStats_NewSales]  DEFAULT ((0)) FOR [NewSales]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyStats_TotalSales]  DEFAULT ((0)) FOR [TotalSales]
GO
ALTER TABLE [dbo].[FACT_DASH_DailySalesStats] ADD  CONSTRAINT [DF_FACT_DASH_DailySalesStats_TotalSubscriptionSales]  DEFAULT ((0)) FOR [TotalSubscriptionSales]
GO
ALTER TABLE [dbo].[FACT_DASH_DailySalesStats] ADD  CONSTRAINT [DF_FACT_DASH_DailySalesStats_TotalRentalSales]  DEFAULT ((0)) FOR [TotalRentalSales]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyTotalStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyTotalStats_NewAuhtors]  DEFAULT ((0)) FOR [NewAuthors]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyTotalStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyTotalStats_NewCourses]  DEFAULT ((0)) FOR [NewCourses]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyTotalStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyTotalStats_NewBundles]  DEFAULT ((0)) FOR [NewBundles]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyTotalStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyTotalStats_NewStores]  DEFAULT ((0)) FOR [NewStores]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyTotalStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyTotalStats_NewLearners]  DEFAULT ((0)) FOR [NewLearners]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyTotalStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyTotalStats_NumOfOneTimeSales]  DEFAULT ((0)) FOR [NumOfOneTimeSales]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyTotalStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyTotalStats_NumOfSubscriptionSales]  DEFAULT ((0)) FOR [NumOfSubscriptionSales]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyTotalStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyTotalStats_NumOfRentalSales]  DEFAULT ((0)) FOR [NumOfRentalSales]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyTotalStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyTotalStats_NumOfFreeSales]  DEFAULT ((0)) FOR [NumOfFreeSales]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyTotalStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyTotalStats_NewVideos]  DEFAULT ((0)) FOR [NewMailchimpLists]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyTotalStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyTotalStats_NewMBGJoined]  DEFAULT ((0)) FOR [NewMBGJoined]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyTotalStats] ADD  CONSTRAINT [DF_FACT_DASH_DailyTotalStats_MBGCancelled]  DEFAULT ((0)) FOR [MBGCancelled]
GO
ALTER TABLE [dbo].[FB_ActionsLOV] ADD  CONSTRAINT [DF_FB_ActionsLOV_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[FB_PostInterface] ADD  CONSTRAINT [DF_FB_PostInterface_IsAppPagePost]  DEFAULT ((0)) FOR [IsAppPagePost]
GO
ALTER TABLE [dbo].[LogTable] ADD  CONSTRAINT [DF_LogTable_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[PAYPAL_IpnLogs] ADD  CONSTRAINT [DF_PAYPAL_IpnLogs_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_TotalSales]  DEFAULT ((0)) FOR [TotalSales]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_AuthorSales]  DEFAULT ((0)) FOR [AuthorSales]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_AffiliateSales]  DEFAULT ((0)) FOR [AffiliateSales]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_TotalFees]  DEFAULT ((0)) FOR [TotalFees]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_RefundProgramHold]  DEFAULT ((0)) FOR [RefundProgramHold]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_RefundProgramReleased]  DEFAULT ((0)) FOR [RefundProgramReleased]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_AffiliateCommission]  DEFAULT ((0)) FOR [AffiliateCommission]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_AffiliateFees]  DEFAULT ((0)) FOR [AffiliateFees]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_TotalRefunded]  DEFAULT ((0)) FOR [TotalRefunded]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_TotalRefundedFees]  DEFAULT ((0)) FOR [TotalRefundedFees]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_TotalBalance]  DEFAULT ((0)) FOR [TotalBalance]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_LfeCommissions]  DEFAULT ((0)) FOR [LfeCommissions]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] ADD  CONSTRAINT [DF_PO_UserPayoutStatments_Payout]  DEFAULT ((0)) FOR [Payout]
GO
ALTER TABLE [dbo].[QZ_CourseQuizzes] ADD  CONSTRAINT [DF_QZ_CourseQuizzes_RandomOrder]  DEFAULT ((0)) FOR [RandomOrder]
GO
ALTER TABLE [dbo].[QZ_CourseQuizzes] ADD  CONSTRAINT [DF_QZ_CourseQuizzes_IsMandatory]  DEFAULT ((0)) FOR [IsMandatory]
GO
ALTER TABLE [dbo].[QZ_CourseQuizzes] ADD  CONSTRAINT [DF_QZ_CourseQuizzes_IsBackAllowed]  DEFAULT ((0)) FOR [IsBackAllowed]
GO
ALTER TABLE [dbo].[QZ_CourseQuizzes] ADD  CONSTRAINT [DF_QZ_CourseQuizzes_AttachCertificate]  DEFAULT ((0)) FOR [AttachCertificate]
GO
ALTER TABLE [dbo].[QZ_CourseQuizzes] ADD  CONSTRAINT [DF_QZ_CourseQuizzes_IsAttached]  DEFAULT ((0)) FOR [IsAttached]
GO
ALTER TABLE [dbo].[QZ_QuestionAnswerOptions] ADD  CONSTRAINT [DF_QZ_QustionAnswerOptions_IsCorrect]  DEFAULT ((0)) FOR [IsCorrect]
GO
ALTER TABLE [dbo].[QZ_QuestionAnswerOptions] ADD  CONSTRAINT [DF_QZ_QustionAnswerOptions_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[QZ_QuizQuestionsLib] ADD  CONSTRAINT [DF_QZ_QuizQuestionsLib_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[QZ_StudentQuizAnswers] ADD  CONSTRAINT [DF_QZ_StudentQuizAnswers_IsCorrect]  DEFAULT ((0)) FOR [IsCorrect]
GO
ALTER TABLE [dbo].[QZ_StudentQuizAttempts] ADD  CONSTRAINT [DF_QZ_StudentQuizAttempts_IsSuccess]  DEFAULT ((0)) FOR [IsSuccess]
GO
ALTER TABLE [dbo].[QZ_StudentQuizAttempts] ADD  CONSTRAINT [DF_QZ_StudentQuizAttempts_CurrentIndex]  DEFAULT ((0)) FOR [CurrentIndex]
GO
ALTER TABLE [dbo].[QZ_StudentQuizzes] ADD  CONSTRAINT [DF_QZ_StudentQuizzes_IsSuccess]  DEFAULT ((0)) FOR [IsSuccess]
GO
ALTER TABLE [dbo].[SALE_OrderLines] ADD  CONSTRAINT [DF_SALE_OrderLines_Price]  DEFAULT ((0)) FOR [Price]
GO
ALTER TABLE [dbo].[SALE_OrderLines] ADD  CONSTRAINT [DF_SALE_OrderLines_Discount]  DEFAULT ((0)) FOR [Discount]
GO
ALTER TABLE [dbo].[SALE_OrderLines] ADD  CONSTRAINT [DF_SALE_OrderLines_Fee]  DEFAULT ((0)) FOR [Fee]
GO
ALTER TABLE [dbo].[SALE_OrderLines] ADD  CONSTRAINT [DF_SALE_OrderLines_TotalPrice]  DEFAULT ((0)) FOR [TotalPrice]
GO
ALTER TABLE [dbo].[SALE_OrderLines] ADD  CONSTRAINT [DF_SALE_OrderLines_IsUnderRGP]  DEFAULT ((0)) FOR [IsUnderRGP]
GO
ALTER TABLE [dbo].[SALE_RefundRequests] ADD  CONSTRAINT [DF_SALE_RefundRequests_ReferenceKey]  DEFAULT (newid()) FOR [ReferenceKey]
GO
ALTER TABLE [dbo].[USER_Addresses] ADD  CONSTRAINT [DF_BASE_ContactsLib_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[USER_Addresses] ADD  CONSTRAINT [DF_USER_Addresses_IsDefault]  DEFAULT ((1)) FOR [IsDefault]
GO
ALTER TABLE [dbo].[USER_PaymentInstruments] ADD  CONSTRAINT [DF_USER_PaymentInstruments_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[USER_PaymentInstruments] ADD  CONSTRAINT [DF_BILL_UserPreferences_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[USER_Videos] ADD  CONSTRAINT [DF_USER_Videos_Attached2Chapter]  DEFAULT ((0)) FOR [Attached2Chapter]
GO
ALTER TABLE [dbo].[USER_Videos] ADD  CONSTRAINT [DF_USER_Videos_Plays]  DEFAULT ((0)) FOR [PlaysTotal]
GO
ALTER TABLE [dbo].[USER_Videos] ADD  CONSTRAINT [DF_USER_Videos_Length]  DEFAULT ((0)) FOR [Length]
GO
ALTER TABLE [dbo].[USER_VideosRenditions] ADD  CONSTRAINT [DF_USER_VideosRenditions_AudioOnly]  DEFAULT ((0)) FOR [AudioOnly]
GO
ALTER TABLE [dbo].[USER_VideosRenditions] ADD  CONSTRAINT [DF_USER_VideosRenditions_CreatedInS3]  DEFAULT ((0)) FOR [CreatedInS3]
GO
ALTER TABLE [dbo].[UserCourseReviews] ADD  CONSTRAINT [DF_UserCourseReviews_Approved]  DEFAULT ((0)) FOR [Approved]
GO
ALTER TABLE [dbo].[UserNotifications] ADD  CONSTRAINT [DF_UserNotifications_IsRead]  DEFAULT ((0)) FOR [IsRead]
GO
ALTER TABLE [dbo].[UserNotifications] ADD  CONSTRAINT [DF_UserNotifications_EmailRequired]  DEFAULT ((0)) FOR [EmailRequired]
GO
ALTER TABLE [dbo].[UserNotifications] ADD  CONSTRAINT [DF_UserNotifications_FbPostRequired]  DEFAULT ((0)) FOR [FbPostRequired]
GO
ALTER TABLE [dbo].[UserNotifications] ADD  CONSTRAINT [DF_UserNotifications_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[UserProfile] ADD  CONSTRAINT [DF_UserProfile_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_AffiliateCommission]  DEFAULT ((30)) FOR [AffiliateCommission]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_AutoplayEnabled]  DEFAULT ((0)) FOR [AutoplayEnabled]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_DisplayActivitiesOnFB]  DEFAULT ((1)) FOR [DisplayActivitiesOnFB]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_ReceiveMonthlyNewsletterOnEmail]  DEFAULT ((1)) FOR [ReceiveMonthlyNewsletterOnEmail]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_DisplayDiscussionFeedDailyOnFB]  DEFAULT ((1)) FOR [DisplayDiscussionFeedDailyOnFB]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_ReceiveDiscussionFeedDailyOnEmail]  DEFAULT ((1)) FOR [ReceiveDiscussionFeedDailyOnEmail]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_DisplayDiscussionFeedDailyOnFB1]  DEFAULT ((1)) FOR [DisplayCourseNewsWeeklyOnFB]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_ReceiveDiscussionFeedDailyOnEmail1]  DEFAULT ((1)) FOR [ReceiveCourseNewsWeeklyOnEmail]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_RegistrationTypeId]  DEFAULT ((1)) FOR [RegistrationTypeId]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_JoinedToRefundProgram]  DEFAULT ((0)) FOR [JoinedToRefundProgram]
GO
ALTER TABLE [dbo].[UserSessionsEventLogs] ADD  CONSTRAINT [DF_UserSessionsEventLogs_ExportToFact]  DEFAULT ((0)) FOR [ExportToFact]
GO
ALTER TABLE [dbo].[webpages_Membership] ADD  CONSTRAINT [DF__webpages___IsCon__762C88DA]  DEFAULT ((0)) FOR [IsConfirmed]
GO
ALTER TABLE [dbo].[webpages_Membership] ADD  CONSTRAINT [DF__webpages___Passw__7720AD13]  DEFAULT ((0)) FOR [PasswordFailuresSinceLastSuccess]
GO
ALTER TABLE [dbo].[WebStoreCategories] ADD  CONSTRAINT [DF_WebStoreCategories_IsPublic]  DEFAULT ((1)) FOR [IsPublic]
GO
ALTER TABLE [dbo].[WebStoreCategories] ADD  CONSTRAINT [DF_WebStoreCategories_IsAutoUpdate]  DEFAULT ((0)) FOR [IsAutoUpdate]
GO
ALTER TABLE [dbo].[WebStoreCategories] ADD  CONSTRAINT [DF_WebStoreCategories_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[WebStoreItems] ADD  CONSTRAINT [DF_WebStoreItems_ItemTypeId]  DEFAULT ((1)) FOR [ItemTypeId]
GO
ALTER TABLE [dbo].[WebStoreItems] ADD  CONSTRAINT [DF_WebstoreCourses_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[WebStores] ADD  CONSTRAINT [DF_WebStores_uid]  DEFAULT (newid()) FOR [uid]
GO
ALTER TABLE [dbo].[WebStores] ADD  CONSTRAINT [DF_WebStores_StatusId]  DEFAULT ((1)) FOR [StatusId]
GO
ALTER TABLE [dbo].[WebStores] ADD  CONSTRAINT [DF_WebStores_AddOn]  DEFAULT (getdate()) FOR [AddOn]
GO
ALTER TABLE [dbo].[ApiSessions]  WITH CHECK ADD  CONSTRAINT [FK_ApiSessions_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[ApiSessions] CHECK CONSTRAINT [FK_ApiSessions_Users]
GO
ALTER TABLE [dbo].[APP_PluginInstallations]  WITH CHECK ADD  CONSTRAINT [FK_APP_PluginInstallations_APP_PluginLOV] FOREIGN KEY([TypeId])
REFERENCES [dbo].[APP_PluginLOV] ([Id])
GO
ALTER TABLE [dbo].[APP_PluginInstallations] CHECK CONSTRAINT [FK_APP_PluginInstallations_APP_PluginLOV]
GO
ALTER TABLE [dbo].[APP_PluginInstallations]  WITH CHECK ADD  CONSTRAINT [FK_APP_PluginInstallations_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[APP_PluginInstallations] CHECK CONSTRAINT [FK_APP_PluginInstallations_Users]
GO
ALTER TABLE [dbo].[APP_PluginInstallationStores]  WITH CHECK ADD  CONSTRAINT [FK_APP_PluginInstallationStores_APP_PluginInstallations] FOREIGN KEY([InstallationId])
REFERENCES [dbo].[APP_PluginInstallations] ([InstallationId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[APP_PluginInstallationStores] CHECK CONSTRAINT [FK_APP_PluginInstallationStores_APP_PluginInstallations]
GO
ALTER TABLE [dbo].[APP_PluginInstallationStores]  WITH CHECK ADD  CONSTRAINT [FK_APP_PluginInstallationStores_WebStores] FOREIGN KEY([StoreId])
REFERENCES [dbo].[WebStores] ([StoreID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[APP_PluginInstallationStores] CHECK CONSTRAINT [FK_APP_PluginInstallationStores_WebStores]
GO
ALTER TABLE [dbo].[BILL_ItemsPriceList]  WITH CHECK ADD  CONSTRAINT [FK_BILL_ItemsPriceList_BASE_CurrencyLib] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[BASE_CurrencyLib] ([CurrencyId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[BILL_ItemsPriceList] CHECK CONSTRAINT [FK_BILL_ItemsPriceList_BASE_CurrencyLib]
GO
ALTER TABLE [dbo].[BILL_ItemsPriceList]  WITH CHECK ADD  CONSTRAINT [FK_BILL_ItemsPriceList_BASE_ItemTypesLOV] FOREIGN KEY([ItemTypeId])
REFERENCES [dbo].[BASE_ItemTypesLOV] ([ItemTypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[BILL_ItemsPriceList] CHECK CONSTRAINT [FK_BILL_ItemsPriceList_BASE_ItemTypesLOV]
GO
ALTER TABLE [dbo].[BILL_ItemsPriceList]  WITH CHECK ADD  CONSTRAINT [FK_BILL_ItemsPriceList_BILL_PeriodTypesLOV] FOREIGN KEY([PeriodTypeId])
REFERENCES [dbo].[BILL_PeriodTypesLOV] ([PeriodTypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[BILL_ItemsPriceList] CHECK CONSTRAINT [FK_BILL_ItemsPriceList_BILL_PeriodTypesLOV]
GO
ALTER TABLE [dbo].[BILL_ItemsPriceList]  WITH CHECK ADD  CONSTRAINT [FK_BILL_ItemsPriceList_BILL_PricingTypesLOV] FOREIGN KEY([PriceTypeId])
REFERENCES [dbo].[BILL_PricingTypesLOV] ([TypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[BILL_ItemsPriceList] CHECK CONSTRAINT [FK_BILL_ItemsPriceList_BILL_PricingTypesLOV]
GO
ALTER TABLE [dbo].[CERT_CertificateLib]  WITH CHECK ADD  CONSTRAINT [FK_QZ_CertificateLib_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CERT_CertificateLib] CHECK CONSTRAINT [FK_QZ_CertificateLib_Courses]
GO
ALTER TABLE [dbo].[CERT_CertificateLib]  WITH CHECK ADD  CONSTRAINT [FK_QZ_CertificateLib_QZ_CertificateTemplatesLOV] FOREIGN KEY([TemplateId])
REFERENCES [dbo].[CERT_TemplatesLOV] ([TemplateId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[CERT_CertificateLib] CHECK CONSTRAINT [FK_QZ_CertificateLib_QZ_CertificateTemplatesLOV]
GO
ALTER TABLE [dbo].[CERT_StudentCertificates]  WITH CHECK ADD  CONSTRAINT [FK_CERT_StudentCertificates_CERT_CertificateLib] FOREIGN KEY([CertificateId])
REFERENCES [dbo].[CERT_CertificateLib] ([CertificateId])
GO
ALTER TABLE [dbo].[CERT_StudentCertificates] CHECK CONSTRAINT [FK_CERT_StudentCertificates_CERT_CertificateLib]
GO
ALTER TABLE [dbo].[CERT_StudentCertificates]  WITH CHECK ADD  CONSTRAINT [FK_CERT_StudentCertificates_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CERT_StudentCertificates] CHECK CONSTRAINT [FK_CERT_StudentCertificates_Users]
GO
ALTER TABLE [dbo].[ChapterLinks]  WITH CHECK ADD  CONSTRAINT [FK_ChapterLinks_CourseChapters] FOREIGN KEY([CourseChapterId])
REFERENCES [dbo].[CourseChapters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ChapterLinks] CHECK CONSTRAINT [FK_ChapterLinks_CourseChapters]
GO
ALTER TABLE [dbo].[ChapterLinks]  WITH CHECK ADD  CONSTRAINT [FK_ChapterLinks_CRS_ChapterLinkTypesLOV] FOREIGN KEY([LinkType])
REFERENCES [dbo].[CRS_ChapterLinkTypesLOV] ([LinkTypeId])
GO
ALTER TABLE [dbo].[ChapterLinks] CHECK CONSTRAINT [FK_ChapterLinks_CRS_ChapterLinkTypesLOV]
GO
ALTER TABLE [dbo].[ChapterVideos]  WITH CHECK ADD  CONSTRAINT [FK_ChapterVideos_CourseChapters] FOREIGN KEY([CourseChapterId])
REFERENCES [dbo].[CourseChapters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ChapterVideos] CHECK CONSTRAINT [FK_ChapterVideos_CourseChapters]
GO
ALTER TABLE [dbo].[CHIMP_ListSegments]  WITH CHECK ADD  CONSTRAINT [FK_CHIMP_ListSegments_CHIMP_SegmentTypesLOV] FOREIGN KEY([SegmentTypeId])
REFERENCES [dbo].[CHIMP_SegmentTypesLOV] ([SegmentTypeId])
GO
ALTER TABLE [dbo].[CHIMP_ListSegments] CHECK CONSTRAINT [FK_CHIMP_ListSegments_CHIMP_SegmentTypesLOV]
GO
ALTER TABLE [dbo].[CHIMP_ListSegments]  WITH CHECK ADD  CONSTRAINT [FK_CHIMP_ListSegments_CHIMP_UserLists] FOREIGN KEY([ListId])
REFERENCES [dbo].[CHIMP_UserLists] ([ListId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CHIMP_ListSegments] CHECK CONSTRAINT [FK_CHIMP_ListSegments_CHIMP_UserLists]
GO
ALTER TABLE [dbo].[CHIMP_ListSegments]  WITH CHECK ADD  CONSTRAINT [FK_CHIMP_ListSegments_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
GO
ALTER TABLE [dbo].[CHIMP_ListSegments] CHECK CONSTRAINT [FK_CHIMP_ListSegments_Courses]
GO
ALTER TABLE [dbo].[CHIMP_ListSegments]  WITH CHECK ADD  CONSTRAINT [FK_CHIMP_ListSegments_CRS_Bundles] FOREIGN KEY([BundleId])
REFERENCES [dbo].[CRS_Bundles] ([BundleId])
GO
ALTER TABLE [dbo].[CHIMP_ListSegments] CHECK CONSTRAINT [FK_CHIMP_ListSegments_CRS_Bundles]
GO
ALTER TABLE [dbo].[CHIMP_UserLists]  WITH CHECK ADD  CONSTRAINT [FK_CHIMP_UserLists_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CHIMP_UserLists] CHECK CONSTRAINT [FK_CHIMP_UserLists_Users]
GO
ALTER TABLE [dbo].[CouponInstances]  WITH CHECK ADD  CONSTRAINT [FK_CouponInstances_Coupons] FOREIGN KEY([CouponId])
REFERENCES [dbo].[Coupons] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CouponInstances] CHECK CONSTRAINT [FK_CouponInstances_Coupons]
GO
ALTER TABLE [dbo].[Coupons]  WITH CHECK ADD  CONSTRAINT [FK_Coupons_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
GO
ALTER TABLE [dbo].[Coupons] CHECK CONSTRAINT [FK_Coupons_Courses]
GO
ALTER TABLE [dbo].[Coupons]  WITH CHECK ADD  CONSTRAINT [FK_Coupons_CRS_Bundles] FOREIGN KEY([BundleId])
REFERENCES [dbo].[CRS_Bundles] ([BundleId])
GO
ALTER TABLE [dbo].[Coupons] CHECK CONSTRAINT [FK_Coupons_CRS_Bundles]
GO
ALTER TABLE [dbo].[Coupons]  WITH CHECK ADD  CONSTRAINT [FK_Coupons_CRS_CouponTypesLOV] FOREIGN KEY([CouponTypeId])
REFERENCES [dbo].[CRS_CouponTypesLOV] ([CouponTypeId])
GO
ALTER TABLE [dbo].[Coupons] CHECK CONSTRAINT [FK_Coupons_CRS_CouponTypesLOV]
GO
ALTER TABLE [dbo].[Coupons]  WITH CHECK ADD  CONSTRAINT [FK_Coupons_Users] FOREIGN KEY([OwnerUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Coupons] CHECK CONSTRAINT [FK_Coupons_Users]
GO
ALTER TABLE [dbo].[CourseCategories]  WITH CHECK ADD  CONSTRAINT [FK_CourseCategories_Categories] FOREIGN KEY([CategoryId])
REFERENCES [dbo].[Categories] ([Id])
GO
ALTER TABLE [dbo].[CourseCategories] CHECK CONSTRAINT [FK_CourseCategories_Categories]
GO
ALTER TABLE [dbo].[CourseCategories]  WITH CHECK ADD  CONSTRAINT [FK_CourseCategories_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CourseCategories] CHECK CONSTRAINT [FK_CourseCategories_Courses]
GO
ALTER TABLE [dbo].[CourseChapters]  WITH CHECK ADD  CONSTRAINT [FK_CourseChapters_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CourseChapters] CHECK CONSTRAINT [FK_CourseChapters_Courses]
GO
ALTER TABLE [dbo].[CourseLinks]  WITH CHECK ADD  CONSTRAINT [FK_CourseLinks_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
GO
ALTER TABLE [dbo].[CourseLinks] CHECK CONSTRAINT [FK_CourseLinks_Courses]
GO
ALTER TABLE [dbo].[Courses]  WITH CHECK ADD  CONSTRAINT [FK_Courses_CourseStatusLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[StatusLOV] ([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Courses] CHECK CONSTRAINT [FK_Courses_CourseStatusLOV]
GO
ALTER TABLE [dbo].[Courses]  WITH CHECK ADD  CONSTRAINT [FK_Courses_DSC_ClassRoom] FOREIGN KEY([ClassRoomId])
REFERENCES [dbo].[DSC_ClassRoom] ([ClassRoomId])
GO
ALTER TABLE [dbo].[Courses] CHECK CONSTRAINT [FK_Courses_DSC_ClassRoom]
GO
ALTER TABLE [dbo].[Courses]  WITH CHECK ADD  CONSTRAINT [FK_Courses_Users] FOREIGN KEY([AuthorUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Courses] CHECK CONSTRAINT [FK_Courses_Users]
GO
ALTER TABLE [dbo].[CRS_Assets]  WITH CHECK ADD  CONSTRAINT [FK_CRS_Assets_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CRS_Assets] CHECK CONSTRAINT [FK_CRS_Assets_Courses]
GO
ALTER TABLE [dbo].[CRS_Assets]  WITH CHECK ADD  CONSTRAINT [FK_CRS_Assets_CRS_AssetTypesLOV] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[CRS_AssetTypesLOV] ([AssetTypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[CRS_Assets] CHECK CONSTRAINT [FK_CRS_Assets_CRS_AssetTypesLOV]
GO
ALTER TABLE [dbo].[CRS_BundleCategories]  WITH CHECK ADD  CONSTRAINT [FK_BundleCategories_Bundles] FOREIGN KEY([BundleId])
REFERENCES [dbo].[CRS_Bundles] ([BundleId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CRS_BundleCategories] CHECK CONSTRAINT [FK_BundleCategories_Bundles]
GO
ALTER TABLE [dbo].[CRS_BundleCategories]  WITH CHECK ADD  CONSTRAINT [FK_BundleCategories_Categories] FOREIGN KEY([CategoryId])
REFERENCES [dbo].[Categories] ([Id])
GO
ALTER TABLE [dbo].[CRS_BundleCategories] CHECK CONSTRAINT [FK_BundleCategories_Categories]
GO
ALTER TABLE [dbo].[CRS_BundleCourses]  WITH CHECK ADD  CONSTRAINT [FK_CRS_BundleCourses_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CRS_BundleCourses] CHECK CONSTRAINT [FK_CRS_BundleCourses_Courses]
GO
ALTER TABLE [dbo].[CRS_BundleCourses]  WITH CHECK ADD  CONSTRAINT [FK_CRS_BundleCourses_CRS_Bundles] FOREIGN KEY([BundleId])
REFERENCES [dbo].[CRS_Bundles] ([BundleId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CRS_BundleCourses] CHECK CONSTRAINT [FK_CRS_BundleCourses_CRS_Bundles]
GO
ALTER TABLE [dbo].[CRS_Bundles]  WITH CHECK ADD  CONSTRAINT [FK_CourseBundles_Users] FOREIGN KEY([AuthorId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[CRS_Bundles] CHECK CONSTRAINT [FK_CourseBundles_Users]
GO
ALTER TABLE [dbo].[CRS_Bundles]  WITH CHECK ADD  CONSTRAINT [FK_CRS_Bundles_StatusLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[StatusLOV] ([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[CRS_Bundles] CHECK CONSTRAINT [FK_CRS_Bundles_StatusLOV]
GO
ALTER TABLE [dbo].[DB_CustomEvents]  WITH CHECK ADD  CONSTRAINT [FK_DB_CustomEvents_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DB_CustomEvents] CHECK CONSTRAINT [FK_DB_CustomEvents_Users]
GO
ALTER TABLE [dbo].[DROP_Jobs]  WITH CHECK ADD  CONSTRAINT [FK_DROP_Jobs_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DROP_Jobs] CHECK CONSTRAINT [FK_DROP_Jobs_Courses]
GO
ALTER TABLE [dbo].[DROP_Jobs]  WITH CHECK ADD  CONSTRAINT [FK_DROP_Jobs_DROP_JobStatusesLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[BASE_JobStatusesLOV] ([StatusId])
GO
ALTER TABLE [dbo].[DROP_Jobs] CHECK CONSTRAINT [FK_DROP_Jobs_DROP_JobStatusesLOV]
GO
ALTER TABLE [dbo].[DROP_Jobs]  WITH CHECK ADD  CONSTRAINT [FK_DROP_Jobs_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DROP_Jobs] CHECK CONSTRAINT [FK_DROP_Jobs_Users]
GO
ALTER TABLE [dbo].[DSC_Followers]  WITH CHECK ADD  CONSTRAINT [FK_DSC_ClassRoomFollowers_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
GO
ALTER TABLE [dbo].[DSC_Followers] CHECK CONSTRAINT [FK_DSC_ClassRoomFollowers_Courses]
GO
ALTER TABLE [dbo].[DSC_Followers]  WITH CHECK ADD  CONSTRAINT [FK_DSC_ClassRoomFollowers_DSC_ClassRoom] FOREIGN KEY([ClassRoomId])
REFERENCES [dbo].[DSC_ClassRoom] ([ClassRoomId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DSC_Followers] CHECK CONSTRAINT [FK_DSC_ClassRoomFollowers_DSC_ClassRoom]
GO
ALTER TABLE [dbo].[DSC_Followers]  WITH CHECK ADD  CONSTRAINT [FK_DSC_ClassRoomFollowers_Users] FOREIGN KEY([FollowerId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[DSC_Followers] CHECK CONSTRAINT [FK_DSC_ClassRoomFollowers_Users]
GO
ALTER TABLE [dbo].[DSC_Followers]  WITH CHECK ADD  CONSTRAINT [FK_DSC_ClassRoomFollowers_Users1] FOREIGN KEY([CreatedBy])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DSC_Followers] CHECK CONSTRAINT [FK_DSC_ClassRoomFollowers_Users1]
GO
ALTER TABLE [dbo].[DSC_Hashtags]  WITH CHECK ADD  CONSTRAINT [FK_DSC_Topics_Users] FOREIGN KEY([CreatedBy])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[DSC_Hashtags] CHECK CONSTRAINT [FK_DSC_Topics_Users]
GO
ALTER TABLE [dbo].[DSC_MessageHashtags]  WITH CHECK ADD  CONSTRAINT [FK_DSC_MessageTopics_DSC_Messages] FOREIGN KEY([MessageId])
REFERENCES [dbo].[DSC_Messages] ([MessageId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DSC_MessageHashtags] CHECK CONSTRAINT [FK_DSC_MessageTopics_DSC_Messages]
GO
ALTER TABLE [dbo].[DSC_MessageHashtags]  WITH CHECK ADD  CONSTRAINT [FK_DSC_MessageTopics_DSC_Topics] FOREIGN KEY([HashtagId])
REFERENCES [dbo].[DSC_Hashtags] ([HashtagId])
GO
ALTER TABLE [dbo].[DSC_MessageHashtags] CHECK CONSTRAINT [FK_DSC_MessageTopics_DSC_Topics]
GO
ALTER TABLE [dbo].[DSC_Messages]  WITH CHECK ADD  CONSTRAINT [FK_DSC_Messages_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
GO
ALTER TABLE [dbo].[DSC_Messages] CHECK CONSTRAINT [FK_DSC_Messages_Courses]
GO
ALTER TABLE [dbo].[DSC_Messages]  WITH CHECK ADD  CONSTRAINT [FK_DSC_Messages_DSC_ClassRoom] FOREIGN KEY([ClassRoomId])
REFERENCES [dbo].[DSC_ClassRoom] ([ClassRoomId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DSC_Messages] CHECK CONSTRAINT [FK_DSC_Messages_DSC_ClassRoom]
GO
ALTER TABLE [dbo].[DSC_Messages]  WITH CHECK ADD  CONSTRAINT [FK_DSC_Messages_DSC_MessageKindsLOV] FOREIGN KEY([MessageKindId])
REFERENCES [dbo].[DSC_MessageKindsLOV] ([MessageKindId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[DSC_Messages] CHECK CONSTRAINT [FK_DSC_Messages_DSC_MessageKindsLOV]
GO
ALTER TABLE [dbo].[DSC_Messages]  WITH CHECK ADD  CONSTRAINT [FK_DSC_Messages_DSC_MessagesParent] FOREIGN KEY([ParentMessageId])
REFERENCES [dbo].[DSC_Messages] ([MessageId])
GO
ALTER TABLE [dbo].[DSC_Messages] CHECK CONSTRAINT [FK_DSC_Messages_DSC_MessagesParent]
GO
ALTER TABLE [dbo].[DSC_MessageUsers]  WITH CHECK ADD  CONSTRAINT [FK_DSC_MessageUsers_DSC_Messages] FOREIGN KEY([MessageId])
REFERENCES [dbo].[DSC_Messages] ([MessageId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DSC_MessageUsers] CHECK CONSTRAINT [FK_DSC_MessageUsers_DSC_Messages]
GO
ALTER TABLE [dbo].[DSC_MessageUsers]  WITH CHECK ADD  CONSTRAINT [FK_DSC_MessageUsers_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DSC_MessageUsers] CHECK CONSTRAINT [FK_DSC_MessageUsers_Users]
GO
ALTER TABLE [dbo].[EMAIL_Messages]  WITH CHECK ADD  CONSTRAINT [FK_EMAIL_Messages_UserNotifications] FOREIGN KEY([NotificationId])
REFERENCES [dbo].[UserNotifications] ([NotificationId])
GO
ALTER TABLE [dbo].[EMAIL_Messages] CHECK CONSTRAINT [FK_EMAIL_Messages_UserNotifications]
GO
ALTER TABLE [dbo].[EMAIL_Messages]  WITH CHECK ADD  CONSTRAINT [FK_EMAIL_Messages_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EMAIL_Messages] CHECK CONSTRAINT [FK_EMAIL_Messages_Users]
GO
ALTER TABLE [dbo].[EMAIL_Templates]  WITH CHECK ADD  CONSTRAINT [FK_EMAIL_Templates_EMAIL_TemplateKindsLOV] FOREIGN KEY([TemplateKindId])
REFERENCES [dbo].[EMAIL_TemplateKindsLOV] ([TemplateKindId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[EMAIL_Templates] CHECK CONSTRAINT [FK_EMAIL_Templates_EMAIL_TemplateKindsLOV]
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats]  WITH CHECK ADD  CONSTRAINT [FK_FACT_DASH_DailyStats_ADMIN_RegistrationSourcesLOV] FOREIGN KEY([RegistrationTypeId])
REFERENCES [dbo].[ADMIN_RegistrationSourcesLOV] ([RegistrationTypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[FACT_DASH_DailyPlatformStats] CHECK CONSTRAINT [FK_FACT_DASH_DailyStats_ADMIN_RegistrationSourcesLOV]
GO
ALTER TABLE [dbo].[FACT_DASH_DailySalesStats]  WITH CHECK ADD  CONSTRAINT [FK_FACT_DASH_DailySalesStats_BASE_CurrencyLib] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[BASE_CurrencyLib] ([CurrencyId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[FACT_DASH_DailySalesStats] CHECK CONSTRAINT [FK_FACT_DASH_DailySalesStats_BASE_CurrencyLib]
GO
ALTER TABLE [dbo].[FACT_EventAgg]  WITH CHECK ADD  CONSTRAINT [FK_FACT_Agg_FACT_Agg] FOREIGN KEY([AuthorId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FACT_EventAgg] CHECK CONSTRAINT [FK_FACT_Agg_FACT_Agg]
GO
ALTER TABLE [dbo].[FACT_EventAgg]  WITH CHECK ADD  CONSTRAINT [FK_FACT_Agg_UserEventTypesLOV] FOREIGN KEY([EventTypeID])
REFERENCES [dbo].[UserEventTypesLOV] ([TypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[FACT_EventAgg] CHECK CONSTRAINT [FK_FACT_Agg_UserEventTypesLOV]
GO
ALTER TABLE [dbo].[FACT_EventAgg]  WITH CHECK ADD  CONSTRAINT [FK_FACT_Agg_WebStores] FOREIGN KEY([WebStoreId])
REFERENCES [dbo].[WebStores] ([StoreID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FACT_EventAgg] CHECK CONSTRAINT [FK_FACT_Agg_WebStores]
GO
ALTER TABLE [dbo].[FB_PostInterface]  WITH CHECK ADD  CONSTRAINT [FK_FB_PostInterface_ChapterVideos] FOREIGN KEY([ChapterVideoId])
REFERENCES [dbo].[ChapterVideos] ([Id])
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[FB_PostInterface] CHECK CONSTRAINT [FK_FB_PostInterface_ChapterVideos]
GO
ALTER TABLE [dbo].[FB_PostInterface]  WITH CHECK ADD  CONSTRAINT [FK_FB_PostInterface_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
GO
ALTER TABLE [dbo].[FB_PostInterface] CHECK CONSTRAINT [FK_FB_PostInterface_Courses]
GO
ALTER TABLE [dbo].[FB_PostInterface]  WITH CHECK ADD  CONSTRAINT [FK_FB_PostInterface_FB_ActionsLOV] FOREIGN KEY([ActionId])
REFERENCES [dbo].[FB_ActionsLOV] ([ActionId])
GO
ALTER TABLE [dbo].[FB_PostInterface] CHECK CONSTRAINT [FK_FB_PostInterface_FB_ActionsLOV]
GO
ALTER TABLE [dbo].[FB_PostInterface]  WITH CHECK ADD  CONSTRAINT [FK_FB_PostInterface_UserNotifications] FOREIGN KEY([NotificationId])
REFERENCES [dbo].[UserNotifications] ([NotificationId])
GO
ALTER TABLE [dbo].[FB_PostInterface] CHECK CONSTRAINT [FK_FB_PostInterface_UserNotifications]
GO
ALTER TABLE [dbo].[FB_PostInterface]  WITH CHECK ADD  CONSTRAINT [FK_FB_PostInterface_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FB_PostInterface] CHECK CONSTRAINT [FK_FB_PostInterface_Users]
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests]  WITH CHECK ADD  CONSTRAINT [FK_PAYPAL_AccountPaymentRequests_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests] CHECK CONSTRAINT [FK_PAYPAL_AccountPaymentRequests_Courses]
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests]  WITH CHECK ADD  CONSTRAINT [FK_PAYPAL_PaymentRequests_BILL_PaymentMethodsLOV] FOREIGN KEY([PaymentMethodId])
REFERENCES [dbo].[BILL_PaymentMethodsLOV] ([MethodId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests] CHECK CONSTRAINT [FK_PAYPAL_PaymentRequests_BILL_PaymentMethodsLOV]
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests]  WITH CHECK ADD  CONSTRAINT [FK_PAYPAL_PaymentRequests_CRS_Bundles] FOREIGN KEY([BundleId])
REFERENCES [dbo].[CRS_Bundles] ([BundleId])
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests] CHECK CONSTRAINT [FK_PAYPAL_PaymentRequests_CRS_Bundles]
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests]  WITH CHECK ADD  CONSTRAINT [FK_PAYPAL_PaymentRequests_PAYPAL_PaymentRequests] FOREIGN KEY([SourceRequestId])
REFERENCES [dbo].[PAYPAL_PaymentRequests] ([RequestId])
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests] CHECK CONSTRAINT [FK_PAYPAL_PaymentRequests_PAYPAL_PaymentRequests]
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests]  WITH CHECK ADD  CONSTRAINT [FK_PAYPAL_PaymentRequests_PAYPAL_RequestTypesLOV] FOREIGN KEY([RequestTypeId])
REFERENCES [dbo].[PAYPAL_RequestTypesLOV] ([TypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests] CHECK CONSTRAINT [FK_PAYPAL_PaymentRequests_PAYPAL_RequestTypesLOV]
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests]  WITH CHECK ADD  CONSTRAINT [FK_PAYPAL_PaymentRequests_USER_Addresses] FOREIGN KEY([AddressId])
REFERENCES [dbo].[USER_Addresses] ([AddressId])
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests] CHECK CONSTRAINT [FK_PAYPAL_PaymentRequests_USER_Addresses]
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests]  WITH CHECK ADD  CONSTRAINT [FK_PAYPAL_PaymentRequests_USER_PaymentInstruments] FOREIGN KEY([InstrumentId])
REFERENCES [dbo].[USER_PaymentInstruments] ([InstrumentId])
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests] CHECK CONSTRAINT [FK_PAYPAL_PaymentRequests_USER_PaymentInstruments]
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests]  WITH CHECK ADD  CONSTRAINT [FK_PAYPAL_PaymentRequests_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[PAYPAL_PaymentRequests] CHECK CONSTRAINT [FK_PAYPAL_PaymentRequests_Users]
GO
ALTER TABLE [dbo].[PO_BeneficiaryConditions]  WITH CHECK ADD  CONSTRAINT [FK_PO_BeneficiaryConditions_PO_Rules] FOREIGN KEY([RuleId])
REFERENCES [dbo].[PO_Rules] ([RuleId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PO_BeneficiaryConditions] CHECK CONSTRAINT [FK_PO_BeneficiaryConditions_PO_Rules]
GO
ALTER TABLE [dbo].[PO_PayoutExecutions]  WITH CHECK ADD  CONSTRAINT [FK_PO_PayoutExecutions_PO_PayoutStatusesLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[PO_PayoutStatusesLOV] ([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[PO_PayoutExecutions] CHECK CONSTRAINT [FK_PO_PayoutExecutions_PO_PayoutStatusesLOV]
GO
ALTER TABLE [dbo].[PO_RuleBeneficiaries]  WITH CHECK ADD  CONSTRAINT [FK_PO_RuleBeneficiaries_PO_BeneficiaryConditions] FOREIGN KEY([ConditionId])
REFERENCES [dbo].[PO_BeneficiaryConditions] ([ConditionId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PO_RuleBeneficiaries] CHECK CONSTRAINT [FK_PO_RuleBeneficiaries_PO_BeneficiaryConditions]
GO
ALTER TABLE [dbo].[PO_RuleBeneficiaries]  WITH CHECK ADD  CONSTRAINT [FK_PO_RuleBeneficiaries_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[PO_RuleBeneficiaries] CHECK CONSTRAINT [FK_PO_RuleBeneficiaries_Users]
GO
ALTER TABLE [dbo].[PO_Rules]  WITH CHECK ADD  CONSTRAINT [FK_PO_Rules_AffiliateAuthor] FOREIGN KEY([AffiliateUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[PO_Rules] CHECK CONSTRAINT [FK_PO_Rules_AffiliateAuthor]
GO
ALTER TABLE [dbo].[PO_Rules]  WITH CHECK ADD  CONSTRAINT [FK_PO_Rules_Author] FOREIGN KEY([AuthorId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[PO_Rules] CHECK CONSTRAINT [FK_PO_Rules_Author]
GO
ALTER TABLE [dbo].[PO_Rules]  WITH CHECK ADD  CONSTRAINT [FK_PO_Rules_StoreOwner] FOREIGN KEY([StoreOwnerId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[PO_Rules] CHECK CONSTRAINT [FK_PO_Rules_StoreOwner]
GO
ALTER TABLE [dbo].[PO_Rules]  WITH CHECK ADD  CONSTRAINT [FK_PO_Rules_WebStores] FOREIGN KEY([StoreId])
REFERENCES [dbo].[WebStores] ([StoreID])
GO
ALTER TABLE [dbo].[PO_Rules] CHECK CONSTRAINT [FK_PO_Rules_WebStores]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments]  WITH CHECK ADD  CONSTRAINT [FK_PO_UserPayoutStatments_BASE_CurrencyLib] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[BASE_CurrencyLib] ([CurrencyId])
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] CHECK CONSTRAINT [FK_PO_UserPayoutStatments_BASE_CurrencyLib]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments]  WITH CHECK ADD  CONSTRAINT [FK_PO_UserPayoutStatments_BILL_PayoutTypesLOV] FOREIGN KEY([PayoutTypeId])
REFERENCES [dbo].[BILL_PayoutTypesLOV] ([PayoutTypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] CHECK CONSTRAINT [FK_PO_UserPayoutStatments_BILL_PayoutTypesLOV]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments]  WITH CHECK ADD  CONSTRAINT [FK_PO_UserPayoutStatments_PO_PayoutExecutions] FOREIGN KEY([ExecutionId])
REFERENCES [dbo].[PO_PayoutExecutions] ([ExecutionId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] CHECK CONSTRAINT [FK_PO_UserPayoutStatments_PO_PayoutExecutions]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments]  WITH CHECK ADD  CONSTRAINT [FK_PO_UserPayoutStatments_PO_PayoutStatusesLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[PO_PayoutStatusesLOV] ([StatusId])
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] CHECK CONSTRAINT [FK_PO_UserPayoutStatments_PO_PayoutStatusesLOV]
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments]  WITH CHECK ADD  CONSTRAINT [FK_PO_UserPayoutStatments_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[PO_UserPayoutStatments] CHECK CONSTRAINT [FK_PO_UserPayoutStatments_Users]
GO
ALTER TABLE [dbo].[QZ_CourseQuizzes]  WITH CHECK ADD  CONSTRAINT [FK_QZ_CourseQuizzes_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[QZ_CourseQuizzes] CHECK CONSTRAINT [FK_QZ_CourseQuizzes_Courses]
GO
ALTER TABLE [dbo].[QZ_CourseQuizzes]  WITH CHECK ADD  CONSTRAINT [FK_QZ_CourseQuizzes_QZ_StatusesLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[QZ_StatusesLOV] ([StatusId])
GO
ALTER TABLE [dbo].[QZ_CourseQuizzes] CHECK CONSTRAINT [FK_QZ_CourseQuizzes_QZ_StatusesLOV]
GO
ALTER TABLE [dbo].[QZ_QuestionAnswerOptions]  WITH CHECK ADD  CONSTRAINT [FK_QZ_QustionAnswerOptions_QZ_QuizQuestionsLib] FOREIGN KEY([QuestionId])
REFERENCES [dbo].[QZ_QuizQuestionsLib] ([QuestionId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[QZ_QuestionAnswerOptions] CHECK CONSTRAINT [FK_QZ_QustionAnswerOptions_QZ_QuizQuestionsLib]
GO
ALTER TABLE [dbo].[QZ_QuizQuestionsLib]  WITH CHECK ADD  CONSTRAINT [FK_QZ_QuizQuestionsLib_QZ_QuestionTypesLOV] FOREIGN KEY([TypeId])
REFERENCES [dbo].[QZ_QuestionTypesLOV] ([TypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[QZ_QuizQuestionsLib] CHECK CONSTRAINT [FK_QZ_QuizQuestionsLib_QZ_QuestionTypesLOV]
GO
ALTER TABLE [dbo].[QZ_QuizQuestionsLib]  WITH CHECK ADD  CONSTRAINT [FK_QZ_QuizQuestionsLib_QZ_QuizzesLib] FOREIGN KEY([QuizId])
REFERENCES [dbo].[QZ_CourseQuizzes] ([QuizId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[QZ_QuizQuestionsLib] CHECK CONSTRAINT [FK_QZ_QuizQuestionsLib_QZ_QuizzesLib]
GO
ALTER TABLE [dbo].[QZ_StudentQuizAnswers]  WITH CHECK ADD  CONSTRAINT [FK_QZ_StudentQuizAnswers_QZ_StudentQuizzes] FOREIGN KEY([AttemptId])
REFERENCES [dbo].[QZ_StudentQuizAttempts] ([AttemptId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[QZ_StudentQuizAnswers] CHECK CONSTRAINT [FK_QZ_StudentQuizAnswers_QZ_StudentQuizzes]
GO
ALTER TABLE [dbo].[QZ_StudentQuizAttempts]  WITH CHECK ADD  CONSTRAINT [FK_QZ_StudentQuizAttempts_QZ_StudentQuizzes] FOREIGN KEY([StudentQuizId])
REFERENCES [dbo].[QZ_StudentQuizzes] ([StudentQuizId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[QZ_StudentQuizAttempts] CHECK CONSTRAINT [FK_QZ_StudentQuizAttempts_QZ_StudentQuizzes]
GO
ALTER TABLE [dbo].[QZ_StudentQuizAttempts]  WITH CHECK ADD  CONSTRAINT [FK_QZ_StudentQuizAttempts_QZ_UserQuizStatusesLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[QZ_StudentQuizStatusesLOV] ([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[QZ_StudentQuizAttempts] CHECK CONSTRAINT [FK_QZ_StudentQuizAttempts_QZ_UserQuizStatusesLOV]
GO
ALTER TABLE [dbo].[QZ_StudentQuizzes]  WITH CHECK ADD  CONSTRAINT [FK_QZ_StudentQuizzes_QZ_CourseQuizzes] FOREIGN KEY([QuizId])
REFERENCES [dbo].[QZ_CourseQuizzes] ([QuizId])
GO
ALTER TABLE [dbo].[QZ_StudentQuizzes] CHECK CONSTRAINT [FK_QZ_StudentQuizzes_QZ_CourseQuizzes]
GO
ALTER TABLE [dbo].[QZ_StudentQuizzes]  WITH CHECK ADD  CONSTRAINT [FK_QZ_StudentQuizzes_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[QZ_StudentQuizzes] CHECK CONSTRAINT [FK_QZ_StudentQuizzes_Users]
GO
ALTER TABLE [dbo].[SALE_OrderLinePaymentRefunds]  WITH CHECK ADD  CONSTRAINT [FK_SALE_OrderLinePaymentRefunds_SALE_OrderLinePayments] FOREIGN KEY([PaymentId])
REFERENCES [dbo].[SALE_OrderLinePayments] ([PaymentId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SALE_OrderLinePaymentRefunds] CHECK CONSTRAINT [FK_SALE_OrderLinePaymentRefunds_SALE_OrderLinePayments]
GO
ALTER TABLE [dbo].[SALE_OrderLinePaymentRefunds]  WITH CHECK ADD  CONSTRAINT [FK_SALE_OrderLinePaymentRefunds_SALE_PaymentTypesLOV] FOREIGN KEY([TypeId])
REFERENCES [dbo].[SALE_PaymentTypesLOV] ([TypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[SALE_OrderLinePaymentRefunds] CHECK CONSTRAINT [FK_SALE_OrderLinePaymentRefunds_SALE_PaymentTypesLOV]
GO
ALTER TABLE [dbo].[SALE_OrderLinePayments]  WITH CHECK ADD  CONSTRAINT [FK_SALE_OrderLinePayments_SALE_OrderLines] FOREIGN KEY([OrderLineId])
REFERENCES [dbo].[SALE_OrderLines] ([LineId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SALE_OrderLinePayments] CHECK CONSTRAINT [FK_SALE_OrderLinePayments_SALE_OrderLines]
GO
ALTER TABLE [dbo].[SALE_OrderLinePayments]  WITH CHECK ADD  CONSTRAINT [FK_SALE_OrderLinePayments_SALE_PaymentStatusesLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[SALE_PaymentStatusesLOV] ([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[SALE_OrderLinePayments] CHECK CONSTRAINT [FK_SALE_OrderLinePayments_SALE_PaymentStatusesLOV]
GO
ALTER TABLE [dbo].[SALE_OrderLinePayments]  WITH CHECK ADD  CONSTRAINT [FK_SALE_OrderLinePayments_SALE_PaymentTypesLOV] FOREIGN KEY([TypeId])
REFERENCES [dbo].[SALE_PaymentTypesLOV] ([TypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[SALE_OrderLinePayments] CHECK CONSTRAINT [FK_SALE_OrderLinePayments_SALE_PaymentTypesLOV]
GO
ALTER TABLE [dbo].[SALE_OrderLines]  WITH CHECK ADD  CONSTRAINT [FK_SALE_OrderLines_BILL_PaymentTermsLOV] FOREIGN KEY([PaymentTermId])
REFERENCES [dbo].[BILL_PaymentTermsLOV] ([PaymentTermId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[SALE_OrderLines] CHECK CONSTRAINT [FK_SALE_OrderLines_BILL_PaymentTermsLOV]
GO
ALTER TABLE [dbo].[SALE_OrderLines]  WITH CHECK ADD  CONSTRAINT [FK_SALE_OrderLines_CouponInstances] FOREIGN KEY([CouponInstanceId])
REFERENCES [dbo].[CouponInstances] ([Id])
GO
ALTER TABLE [dbo].[SALE_OrderLines] CHECK CONSTRAINT [FK_SALE_OrderLines_CouponInstances]
GO
ALTER TABLE [dbo].[SALE_OrderLines]  WITH CHECK ADD  CONSTRAINT [FK_SALE_OrderLines_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
GO
ALTER TABLE [dbo].[SALE_OrderLines] CHECK CONSTRAINT [FK_SALE_OrderLines_Courses]
GO
ALTER TABLE [dbo].[SALE_OrderLines]  WITH CHECK ADD  CONSTRAINT [FK_SALE_OrderLines_CRS_Bundles] FOREIGN KEY([BundleId])
REFERENCES [dbo].[CRS_Bundles] ([BundleId])
GO
ALTER TABLE [dbo].[SALE_OrderLines] CHECK CONSTRAINT [FK_SALE_OrderLines_CRS_Bundles]
GO
ALTER TABLE [dbo].[SALE_OrderLines]  WITH CHECK ADD  CONSTRAINT [FK_SALE_OrderLines_SALE_OrderLineTypesLOV] FOREIGN KEY([LineTypeId])
REFERENCES [dbo].[SALE_OrderLineTypesLOV] ([TypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[SALE_OrderLines] CHECK CONSTRAINT [FK_SALE_OrderLines_SALE_OrderLineTypesLOV]
GO
ALTER TABLE [dbo].[SALE_OrderLines]  WITH CHECK ADD  CONSTRAINT [FK_SALE_OrderLines_SALE_Orders] FOREIGN KEY([OrderId])
REFERENCES [dbo].[SALE_Orders] ([OrderId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SALE_OrderLines] CHECK CONSTRAINT [FK_SALE_OrderLines_SALE_Orders]
GO
ALTER TABLE [dbo].[SALE_OrderLines]  WITH CHECK ADD  CONSTRAINT [FK_SALE_OrderLines_Users] FOREIGN KEY([SellerUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[SALE_OrderLines] CHECK CONSTRAINT [FK_SALE_OrderLines_Users]
GO
ALTER TABLE [dbo].[SALE_Orders]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Orders_BILL_PaymentMethodsLOV] FOREIGN KEY([PaymentMethodId])
REFERENCES [dbo].[BILL_PaymentMethodsLOV] ([MethodId])
GO
ALTER TABLE [dbo].[SALE_Orders] CHECK CONSTRAINT [FK_SALE_Orders_BILL_PaymentMethodsLOV]
GO
ALTER TABLE [dbo].[SALE_Orders]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Orders_BuyerUser] FOREIGN KEY([BuyerUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[SALE_Orders] CHECK CONSTRAINT [FK_SALE_Orders_BuyerUser]
GO
ALTER TABLE [dbo].[SALE_Orders]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Orders_SALE_OrderStatusesLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[SALE_OrderStatusesLOV] ([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[SALE_Orders] CHECK CONSTRAINT [FK_SALE_Orders_SALE_OrderStatusesLOV]
GO
ALTER TABLE [dbo].[SALE_Orders]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Orders_SellerUsers] FOREIGN KEY([SellerUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[SALE_Orders] CHECK CONSTRAINT [FK_SALE_Orders_SellerUsers]
GO
ALTER TABLE [dbo].[SALE_Orders]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Orders_USER_Addresses] FOREIGN KEY([AddressId])
REFERENCES [dbo].[USER_Addresses] ([AddressId])
GO
ALTER TABLE [dbo].[SALE_Orders] CHECK CONSTRAINT [FK_SALE_Orders_USER_Addresses]
GO
ALTER TABLE [dbo].[SALE_Orders]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Orders_USER_PaymentInstruments] FOREIGN KEY([InstrumentId])
REFERENCES [dbo].[USER_PaymentInstruments] ([InstrumentId])
GO
ALTER TABLE [dbo].[SALE_Orders] CHECK CONSTRAINT [FK_SALE_Orders_USER_PaymentInstruments]
GO
ALTER TABLE [dbo].[SALE_Orders]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Orders_WebStores] FOREIGN KEY([WebStoreId])
REFERENCES [dbo].[WebStores] ([StoreID])
GO
ALTER TABLE [dbo].[SALE_Orders] CHECK CONSTRAINT [FK_SALE_Orders_WebStores]
GO
ALTER TABLE [dbo].[SALE_RefundRequests]  WITH CHECK ADD  CONSTRAINT [FK_SALE_RefundRequests_SALE_OrderLinePaymentRefunds] FOREIGN KEY([RefundId])
REFERENCES [dbo].[SALE_OrderLinePaymentRefunds] ([RefundId])
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[SALE_RefundRequests] CHECK CONSTRAINT [FK_SALE_RefundRequests_SALE_OrderLinePaymentRefunds]
GO
ALTER TABLE [dbo].[SALE_RefundRequests]  WITH CHECK ADD  CONSTRAINT [FK_SALE_RefundRequests_SALE_OrderLinePayments] FOREIGN KEY([PaymentId])
REFERENCES [dbo].[SALE_OrderLinePayments] ([PaymentId])
GO
ALTER TABLE [dbo].[SALE_RefundRequests] CHECK CONSTRAINT [FK_SALE_RefundRequests_SALE_OrderLinePayments]
GO
ALTER TABLE [dbo].[SALE_RefundRequests]  WITH CHECK ADD  CONSTRAINT [FK_SALE_RefundRequests_SALE_RefundRequestStatusesLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[SALE_RefundRequestStatusesLOV] ([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[SALE_RefundRequests] CHECK CONSTRAINT [FK_SALE_RefundRequests_SALE_RefundRequestStatusesLOV]
GO
ALTER TABLE [dbo].[SALE_Transactions]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Transactions_PAYPAL_PaymentRequests] FOREIGN KEY([RequestId])
REFERENCES [dbo].[PAYPAL_PaymentRequests] ([RequestId])
GO
ALTER TABLE [dbo].[SALE_Transactions] CHECK CONSTRAINT [FK_SALE_Transactions_PAYPAL_PaymentRequests]
GO
ALTER TABLE [dbo].[SALE_Transactions]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Transactions_SALE_OrderLinePaymentRefunds] FOREIGN KEY([RefundId])
REFERENCES [dbo].[SALE_OrderLinePaymentRefunds] ([RefundId])
GO
ALTER TABLE [dbo].[SALE_Transactions] CHECK CONSTRAINT [FK_SALE_Transactions_SALE_OrderLinePaymentRefunds]
GO
ALTER TABLE [dbo].[SALE_Transactions]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Transactions_SALE_OrderLinePayments] FOREIGN KEY([PaymentId])
REFERENCES [dbo].[SALE_OrderLinePayments] ([PaymentId])
GO
ALTER TABLE [dbo].[SALE_Transactions] CHECK CONSTRAINT [FK_SALE_Transactions_SALE_OrderLinePayments]
GO
ALTER TABLE [dbo].[SALE_Transactions]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Transactions_SALE_OrderLines] FOREIGN KEY([OrderLineId])
REFERENCES [dbo].[SALE_OrderLines] ([LineId])
GO
ALTER TABLE [dbo].[SALE_Transactions] CHECK CONSTRAINT [FK_SALE_Transactions_SALE_OrderLines]
GO
ALTER TABLE [dbo].[SALE_Transactions]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Transactions_SALE_Transactions] FOREIGN KEY([SourceTransactionId])
REFERENCES [dbo].[SALE_Transactions] ([TransactionId])
GO
ALTER TABLE [dbo].[SALE_Transactions] CHECK CONSTRAINT [FK_SALE_Transactions_SALE_Transactions]
GO
ALTER TABLE [dbo].[SALE_Transactions]  WITH CHECK ADD  CONSTRAINT [FK_SALE_Transactions_SALE_TransactionTypesLOV] FOREIGN KEY([TransactionTypeId])
REFERENCES [dbo].[SALE_TransactionTypesLOV] ([TransactionTypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[SALE_Transactions] CHECK CONSTRAINT [FK_SALE_Transactions_SALE_TransactionTypesLOV]
GO
ALTER TABLE [dbo].[USER_Addresses]  WITH CHECK ADD  CONSTRAINT [FK_CON_ContactsLib_GEO_CountriesLib] FOREIGN KEY([CountryId])
REFERENCES [dbo].[GEO_CountriesLib] ([CountryId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[USER_Addresses] CHECK CONSTRAINT [FK_CON_ContactsLib_GEO_CountriesLib]
GO
ALTER TABLE [dbo].[USER_Addresses]  WITH CHECK ADD  CONSTRAINT [FK_CON_ContactsLib_GEO_States] FOREIGN KEY([StateId])
REFERENCES [dbo].[GEO_States] ([StateId])
GO
ALTER TABLE [dbo].[USER_Addresses] CHECK CONSTRAINT [FK_CON_ContactsLib_GEO_States]
GO
ALTER TABLE [dbo].[USER_Addresses]  WITH CHECK ADD  CONSTRAINT [FK_CON_ContactsLib_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[USER_Addresses] CHECK CONSTRAINT [FK_CON_ContactsLib_Users]
GO
ALTER TABLE [dbo].[USER_Bundles]  WITH CHECK ADD  CONSTRAINT [FK_USER_Bundles_CRS_Bundles] FOREIGN KEY([BundleId])
REFERENCES [dbo].[CRS_Bundles] ([BundleId])
GO
ALTER TABLE [dbo].[USER_Bundles] CHECK CONSTRAINT [FK_USER_Bundles_CRS_Bundles]
GO
ALTER TABLE [dbo].[USER_Bundles]  WITH CHECK ADD  CONSTRAINT [FK_USER_Bundles_SALE_OrderLines] FOREIGN KEY([OrderLineId])
REFERENCES [dbo].[SALE_OrderLines] ([LineId])
GO
ALTER TABLE [dbo].[USER_Bundles] CHECK CONSTRAINT [FK_USER_Bundles_SALE_OrderLines]
GO
ALTER TABLE [dbo].[USER_Bundles]  WITH CHECK ADD  CONSTRAINT [FK_USER_Bundles_SALE_UserAccessStatusesLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[SALE_UserAccessStatusesLOV] ([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[USER_Bundles] CHECK CONSTRAINT [FK_USER_Bundles_SALE_UserAccessStatusesLOV]
GO
ALTER TABLE [dbo].[USER_Bundles]  WITH CHECK ADD  CONSTRAINT [FK_USER_Bundles_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[USER_Bundles] CHECK CONSTRAINT [FK_USER_Bundles_Users]
GO
ALTER TABLE [dbo].[USER_Courses]  WITH CHECK ADD  CONSTRAINT [FK_USER_Courses_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
GO
ALTER TABLE [dbo].[USER_Courses] CHECK CONSTRAINT [FK_USER_Courses_Courses]
GO
ALTER TABLE [dbo].[USER_Courses]  WITH CHECK ADD  CONSTRAINT [FK_USER_Courses_SALE_OrderLines] FOREIGN KEY([OrderLineId])
REFERENCES [dbo].[SALE_OrderLines] ([LineId])
GO
ALTER TABLE [dbo].[USER_Courses] CHECK CONSTRAINT [FK_USER_Courses_SALE_OrderLines]
GO
ALTER TABLE [dbo].[USER_Courses]  WITH CHECK ADD  CONSTRAINT [FK_USER_Courses_SALE_UserAccessStatusesLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[SALE_UserAccessStatusesLOV] ([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[USER_Courses] CHECK CONSTRAINT [FK_USER_Courses_SALE_UserAccessStatusesLOV]
GO
ALTER TABLE [dbo].[USER_Courses]  WITH CHECK ADD  CONSTRAINT [FK_USER_Courses_USER_Bundles] FOREIGN KEY([UserBundleId])
REFERENCES [dbo].[USER_Bundles] ([UserBundleId])
GO
ALTER TABLE [dbo].[USER_Courses] CHECK CONSTRAINT [FK_USER_Courses_USER_Bundles]
GO
ALTER TABLE [dbo].[USER_Courses]  WITH CHECK ADD  CONSTRAINT [FK_USER_Courses_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[USER_Courses] CHECK CONSTRAINT [FK_USER_Courses_Users]
GO
ALTER TABLE [dbo].[USER_CourseWatchState]  WITH CHECK ADD  CONSTRAINT [FK_USER_CourseWatchState_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[USER_CourseWatchState] CHECK CONSTRAINT [FK_USER_CourseWatchState_Courses]
GO
ALTER TABLE [dbo].[USER_CourseWatchState]  WITH CHECK ADD  CONSTRAINT [FK_USER_CourseWatchState_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[USER_CourseWatchState] CHECK CONSTRAINT [FK_USER_CourseWatchState_Users]
GO
ALTER TABLE [dbo].[USER_Logins]  WITH CHECK ADD  CONSTRAINT [FK_USER_Logins_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[USER_Logins] CHECK CONSTRAINT [FK_USER_Logins_Users]
GO
ALTER TABLE [dbo].[USER_PaymentInstruments]  WITH CHECK ADD  CONSTRAINT [FK_USER_PaymentInstruments_BILL_PaymentMethodsLOV] FOREIGN KEY([PaymentMethodId])
REFERENCES [dbo].[BILL_PaymentMethodsLOV] ([MethodId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[USER_PaymentInstruments] CHECK CONSTRAINT [FK_USER_PaymentInstruments_BILL_PaymentMethodsLOV]
GO
ALTER TABLE [dbo].[USER_PaymentInstruments]  WITH CHECK ADD  CONSTRAINT [FK_USER_PaymentInstruments_USER_Addresses] FOREIGN KEY([AddressId])
REFERENCES [dbo].[USER_Addresses] ([AddressId])
GO
ALTER TABLE [dbo].[USER_PaymentInstruments] CHECK CONSTRAINT [FK_USER_PaymentInstruments_USER_Addresses]
GO
ALTER TABLE [dbo].[USER_PaymentInstruments]  WITH CHECK ADD  CONSTRAINT [FK_USER_PaymentInstruments_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[USER_PaymentInstruments] CHECK CONSTRAINT [FK_USER_PaymentInstruments_Users]
GO
ALTER TABLE [dbo].[USER_RefundProgramRevisions]  WITH CHECK ADD  CONSTRAINT [FK_USER_RefundProgramRevisions_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[USER_RefundProgramRevisions] CHECK CONSTRAINT [FK_USER_RefundProgramRevisions_Users]
GO
ALTER TABLE [dbo].[USER_Videos]  WITH CHECK ADD  CONSTRAINT [FK_USER_Videos_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[USER_Videos] CHECK CONSTRAINT [FK_USER_Videos_Users]
GO
ALTER TABLE [dbo].[USER_VideosRenditions]  WITH CHECK ADD  CONSTRAINT [FK_USER_VideosRenditions_USER_Videos] FOREIGN KEY([VideoId])
REFERENCES [dbo].[USER_Videos] ([VideoId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[USER_VideosRenditions] CHECK CONSTRAINT [FK_USER_VideosRenditions_USER_Videos]
GO
ALTER TABLE [dbo].[USER_VideosRenditions]  WITH CHECK ADD  CONSTRAINT [FK_USER_VideosRenditions_USER_VideosRenditions] FOREIGN KEY([RenditionId])
REFERENCES [dbo].[USER_VideosRenditions] ([RenditionId])
GO
ALTER TABLE [dbo].[USER_VideosRenditions] CHECK CONSTRAINT [FK_USER_VideosRenditions_USER_VideosRenditions]
GO
ALTER TABLE [dbo].[USER_VideoStats]  WITH CHECK ADD  CONSTRAINT [FK_USER_VideoStats_CourseChapters] FOREIGN KEY([ChapterId])
REFERENCES [dbo].[CourseChapters] ([Id])
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[USER_VideoStats] CHECK CONSTRAINT [FK_USER_VideoStats_CourseChapters]
GO
ALTER TABLE [dbo].[USER_VideoStats]  WITH CHECK ADD  CONSTRAINT [FK_USER_VideoStats_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[USER_VideoStats] CHECK CONSTRAINT [FK_USER_VideoStats_Users]
GO
ALTER TABLE [dbo].[UserCourseReviews]  WITH CHECK ADD  CONSTRAINT [FK_UserCourseReviews_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
GO
ALTER TABLE [dbo].[UserCourseReviews] CHECK CONSTRAINT [FK_UserCourseReviews_Courses]
GO
ALTER TABLE [dbo].[UserCourseReviews]  WITH CHECK ADD  CONSTRAINT [FK_UserCourseReviews_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[UserCourseReviews] CHECK CONSTRAINT [FK_UserCourseReviews_Users]
GO
ALTER TABLE [dbo].[UserEventTypesLOV]  WITH CHECK ADD  CONSTRAINT [FK_UserEventTypesLOV_UserEventTypeOwnersLOV] FOREIGN KEY([OwnerTypeId])
REFERENCES [dbo].[UserEventTypeOwnersLOV] ([OwnerTypeId])
GO
ALTER TABLE [dbo].[UserEventTypesLOV] CHECK CONSTRAINT [FK_UserEventTypesLOV_UserEventTypeOwnersLOV]
GO
ALTER TABLE [dbo].[UserNotifications]  WITH CHECK ADD  CONSTRAINT [FK_UserNotifications_DSC_Messages] FOREIGN KEY([MessageId])
REFERENCES [dbo].[DSC_Messages] ([MessageId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserNotifications] CHECK CONSTRAINT [FK_UserNotifications_DSC_Messages]
GO
ALTER TABLE [dbo].[UserNotifications]  WITH CHECK ADD  CONSTRAINT [FK_UserNotifications_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserNotifications] CHECK CONSTRAINT [FK_UserNotifications_Users]
GO
ALTER TABLE [dbo].[UserProfile]  WITH CHECK ADD  CONSTRAINT [FK_UserProfile_Users_RefUserId] FOREIGN KEY([RefUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[UserProfile] CHECK CONSTRAINT [FK_UserProfile_Users_RefUserId]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_BILL_PayoutTypesLOV] FOREIGN KEY([PayoutTypeId])
REFERENCES [dbo].[BILL_PayoutTypesLOV] ([PayoutTypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [FK_Users_BILL_PayoutTypesLOV]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_USER_Addresses] FOREIGN KEY([PayoutAddressID])
REFERENCES [dbo].[USER_Addresses] ([AddressId])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [FK_Users_USER_Addresses]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_USER_RegistrationTypesLOV] FOREIGN KEY([RegistrationTypeId])
REFERENCES [dbo].[ADMIN_RegistrationSourcesLOV] ([RegistrationTypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [FK_Users_USER_RegistrationTypesLOV]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_UserStatusTypes] FOREIGN KEY([StatusType])
REFERENCES [dbo].[UserStatusTypes] ([Id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [FK_Users_UserStatusTypes]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_UserTypes] FOREIGN KEY([UserTypeID])
REFERENCES [dbo].[UserTypes] ([id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [FK_Users_UserTypes]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_WebStores] FOREIGN KEY([RegisterStoreId])
REFERENCES [dbo].[WebStores] ([StoreID])
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [FK_Users_WebStores]
GO
ALTER TABLE [dbo].[UserS3FileInterface]  WITH CHECK ADD  CONSTRAINT [FK_UserS3FileInterface_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserS3FileInterface] CHECK CONSTRAINT [FK_UserS3FileInterface_Users]
GO
ALTER TABLE [dbo].[UserSessions]  WITH CHECK ADD  CONSTRAINT [FK_UserSessions_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserSessions] CHECK CONSTRAINT [FK_UserSessions_Users]
GO
ALTER TABLE [dbo].[UserSessionsEventLogs]  WITH CHECK ADD  CONSTRAINT [FK_UserEvents_UserEventTypes] FOREIGN KEY([EventTypeID])
REFERENCES [dbo].[UserEventTypesLOV] ([TypeId])
GO
ALTER TABLE [dbo].[UserSessionsEventLogs] CHECK CONSTRAINT [FK_UserEvents_UserEventTypes]
GO
ALTER TABLE [dbo].[UserSessionsEventLogs]  WITH CHECK ADD  CONSTRAINT [FK_UserEvents_UserSessions] FOREIGN KEY([SessionId])
REFERENCES [dbo].[UserSessions] ([SessionId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserSessionsEventLogs] CHECK CONSTRAINT [FK_UserEvents_UserSessions]
GO
ALTER TABLE [dbo].[UserSessionsEventLogs]  WITH CHECK ADD  CONSTRAINT [FK_UserSessionsEventLogs_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserSessionsEventLogs] CHECK CONSTRAINT [FK_UserSessionsEventLogs_Courses]
GO
ALTER TABLE [dbo].[UserSessionsEventLogs]  WITH CHECK ADD  CONSTRAINT [FK_UserSessionsEventLogs_CRS_Bundles] FOREIGN KEY([BundleId])
REFERENCES [dbo].[CRS_Bundles] ([BundleId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserSessionsEventLogs] CHECK CONSTRAINT [FK_UserSessionsEventLogs_CRS_Bundles]
GO
ALTER TABLE [dbo].[UserSessionsEventLogs]  WITH CHECK ADD  CONSTRAINT [FK_UserSessionsEventLogs_WebStores] FOREIGN KEY([WebStoreId])
REFERENCES [dbo].[WebStores] ([StoreID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserSessionsEventLogs] CHECK CONSTRAINT [FK_UserSessionsEventLogs_WebStores]
GO
ALTER TABLE [dbo].[webpages_OAuthMembership]  WITH CHECK ADD  CONSTRAINT [FK_webpages_OAuthMembership_UserProfile] FOREIGN KEY([UserId])
REFERENCES [dbo].[UserProfile] ([UserId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[webpages_OAuthMembership] CHECK CONSTRAINT [FK_webpages_OAuthMembership_UserProfile]
GO
ALTER TABLE [dbo].[webpages_UsersInRoles]  WITH CHECK ADD  CONSTRAINT [fk_RoleId] FOREIGN KEY([RoleId])
REFERENCES [dbo].[webpages_Roles] ([RoleId])
GO
ALTER TABLE [dbo].[webpages_UsersInRoles] CHECK CONSTRAINT [fk_RoleId]
GO
ALTER TABLE [dbo].[webpages_UsersInRoles]  WITH CHECK ADD  CONSTRAINT [fk_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[UserProfile] ([UserId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[webpages_UsersInRoles] CHECK CONSTRAINT [fk_UserId]
GO
ALTER TABLE [dbo].[WebStoreCategories]  WITH CHECK ADD  CONSTRAINT [FK_WebStoreCategories_Categories] FOREIGN KEY([CategoryId])
REFERENCES [dbo].[Categories] ([Id])
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[WebStoreCategories] CHECK CONSTRAINT [FK_WebStoreCategories_Categories]
GO
ALTER TABLE [dbo].[WebStoreCategories]  WITH CHECK ADD  CONSTRAINT [FK_WebStoreCategories_WebStores] FOREIGN KEY([WebStoreID])
REFERENCES [dbo].[WebStores] ([StoreID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WebStoreCategories] CHECK CONSTRAINT [FK_WebStoreCategories_WebStores]
GO
ALTER TABLE [dbo].[WebStoreItems]  WITH CHECK ADD  CONSTRAINT [FK_WebstoreCourses_Courses] FOREIGN KEY([CourseId])
REFERENCES [dbo].[Courses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WebStoreItems] CHECK CONSTRAINT [FK_WebstoreCourses_Courses]
GO
ALTER TABLE [dbo].[WebStoreItems]  WITH CHECK ADD  CONSTRAINT [FK_WebstoreCourses_WebStoreCategories] FOREIGN KEY([WebStoreCategoryID])
REFERENCES [dbo].[WebStoreCategories] ([WebStoreCategoryID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WebStoreItems] CHECK CONSTRAINT [FK_WebstoreCourses_WebStoreCategories]
GO
ALTER TABLE [dbo].[WebStoreItems]  WITH CHECK ADD  CONSTRAINT [FK_WebStoreItems_CRS_Bundles] FOREIGN KEY([BundleId])
REFERENCES [dbo].[CRS_Bundles] ([BundleId])
GO
ALTER TABLE [dbo].[WebStoreItems] CHECK CONSTRAINT [FK_WebStoreItems_CRS_Bundles]
GO
ALTER TABLE [dbo].[WebStoreItems]  WITH CHECK ADD  CONSTRAINT [FK_WebStoreItems_SALE_ItemTypesLOV] FOREIGN KEY([ItemTypeId])
REFERENCES [dbo].[SALE_ItemTypesLOV] ([ItemTypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[WebStoreItems] CHECK CONSTRAINT [FK_WebStoreItems_SALE_ItemTypesLOV]
GO
ALTER TABLE [dbo].[WebStores]  WITH CHECK ADD  CONSTRAINT [FK_WebStores_ADMIN_RegistrationSourcesLOV] FOREIGN KEY([RegistrationSourceId])
REFERENCES [dbo].[ADMIN_RegistrationSourcesLOV] ([RegistrationTypeId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[WebStores] CHECK CONSTRAINT [FK_WebStores_ADMIN_RegistrationSourcesLOV]
GO
ALTER TABLE [dbo].[WebStores]  WITH CHECK ADD  CONSTRAINT [FK_WebStores_BASE_CurrencyLib] FOREIGN KEY([DefaultCurrencyId])
REFERENCES [dbo].[BASE_CurrencyLib] ([CurrencyId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[WebStores] CHECK CONSTRAINT [FK_WebStores_BASE_CurrencyLib]
GO
ALTER TABLE [dbo].[WebStores]  WITH CHECK ADD  CONSTRAINT [FK_WebStores_CourseStatusLOV] FOREIGN KEY([StatusId])
REFERENCES [dbo].[StatusLOV] ([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[WebStores] CHECK CONSTRAINT [FK_WebStores_CourseStatusLOV]
GO
ALTER TABLE [dbo].[WebStores]  WITH CHECK ADD  CONSTRAINT [FK_WebStores_Users] FOREIGN KEY([OwnerUserID])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[WebStores] CHECK CONSTRAINT [FK_WebStores_Users]
GO
ALTER TABLE [dbo].[WebStoresChangeLog]  WITH CHECK ADD  CONSTRAINT [FK_WebStoresChangeLog_WebStores] FOREIGN KEY([StoreId])
REFERENCES [dbo].[WebStores] ([StoreID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WebStoresChangeLog] CHECK CONSTRAINT [FK_WebStoresChangeLog_WebStores]
GO
/****** Object:  StoredProcedure [dbo].[sp_ADMIN_DeleteUser]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-9-21
-- Description:	Delete User
-- =============================================
CREATE PROCEDURE [dbo].[sp_ADMIN_DeleteUser]
(
	@UserId INT
)
AS
BEGIN

	DECLARE @Id INT
	
	SELECT @Id = UserId
	FROM	dbo.UserProfile WHERE RefUserId = @UserId
		

	DELETE FROM [dbo].[WebStores]
      WHERE OwnerUserID = @UserId

	DELETE FROM [dbo].[PAYPAL_PaymentRequests]
		WHERE UserId = @UserId

	DELETE FROM [dbo].[USER_Courses]
		  WHERE UserId = @UserId

	DELETE FROM [dbo].[USER_Bundles]
		  WHERE UserId = @UserId

	DELETE FROM [dbo].[SALE_Transactions]
		  WHERE TransactionId IN (SELECT TransactionId
		  FROM dbo.vw_SALE_Transactions
		  WHERE	BuyerUserId = @UserId)
	  
	DELETE FROM [dbo].[SALE_Orders]
		  WHERE BuyerUserId = @UserId

	--PRINT @UserId

	DELETE FROM [dbo].[webpages_Membership]
		  WHERE UserId = @Id


	DELETE FROM	dbo.UserProfile 
		WHERE UserId = @Id


	DELETE FROM [dbo].[Users]
		WHERE Id = @UserId

END

GO
/****** Object:  StoredProcedure [dbo].[sp_ADMIN_GetSalesSummaryReport]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-3-27
-- Description:	Get Summary report data
-- =============================================
CREATE PROCEDURE [dbo].[sp_ADMIN_GetSalesSummaryReport]
    (
      @Year INT ,
      @Month INT ,
      @UserId INT = NULL
    )
AS
    BEGIN
        
		SET NOCOUNT ON;
			
		   SELECT  ISNULL(sp.total, 0) AS total ,
					ISNULL(sp.fee, 0) AS fee ,
					ISNULL(sr.total, 0) AS refund ,
					ISNULL(sr.fee, 0) AS refundFee ,
					ISNULL(sp.SellerUserId, sr.SellerUserId) AS SellerUserId ,
					ISNULL(sp.Email, sr.Email) AS Email ,
					ISNULL(sp.Nickname, sr.Nickname) AS Nickname ,
					ISNULL(sp.FirstName, sr.FirstName) AS FirstName ,
					ISNULL(sp.LastName, sr.LastName) AS LastName ,
					ISNULL(sp.PayoutTypeId, sr.PayoutTypeId) AS PayoutTypeId ,
					ISNULL(sp.PaypalEmail, sr.PaypalEmail) AS PaypalEmail ,
					ISNULL(sp.PayoutAddressID, sr.PayoutAddressID) AS PayoutAddressID ,
					ISNULL(sp.CountryId, sr.CountryId) AS CountryId ,
					ISNULL(sp.CountryName, sr.CountryName) AS CountryName ,
					ISNULL(sp.StateId, sr.StateId) AS StateId ,
					ISNULL(sp.StateName, sr.StateName) AS StateName ,
					ISNULL(sp.AddressFirstName, sr.AddressFirstName) AS AddressFirstName ,
					ISNULL(sp.AddressLastName, sr.AddressLastName) AS AddressLastName ,
					ISNULL(sp.CityName, sr.CityName) AS CityName ,
					ISNULL(sp.Street1, sr.Street1) AS Street1 ,
					ISNULL(sp.Street2, sr.Street2) AS Street2 ,
					ISNULL(sp.PostalCode, sr.PostalCode) AS PostalCode ,
					ISNULL(sp.Region, sr.Region) AS Region,
					ISNULL(sp.CurrencyId,sr.CurrencyId) AS CurrencyId,
					ISNULL(sp.CurrencyName,sr.CurrencyName) AS CurrencyName,
					ISNULL(sp.ISO,sr.ISO) AS ISO,
					ISNULL(sp.Symbol,sr.Symbol) AS Symbol
			FROM    ( SELECT    s.SellerUserId ,
								u.Email ,
								u.Nickname ,
								u.FirstName ,
								u.LastName ,
								SUM(s.Amount) AS total ,
								SUM(s.Fee) AS fee ,
								u.PayoutTypeId ,
								u.PaypalEmail ,
								u.PayoutAddressID ,
								adr.CountryId ,
								cntr.CountryName ,
								adr.StateId ,
								st.StateName ,
								adr.FirstName AS AddressFirstName ,
								adr.LastName AS AddressLastName ,
								adr.CityName ,
								adr.Street1 ,
								adr.Street2 ,
								adr.PostalCode ,
								adr.Region ,
								ISNULL(s.CurrencyId,2) AS CurrencyId,
								ISNULL(s.CurrencyName,'U.S. Dollar') AS CurrencyName,
								ISNULL(s.ISO,'USD') AS ISO ,
								ISNULL(s.Symbol,'$') AS Symbol
					  FROM      dbo.GEO_CountriesLib AS cntr
								INNER JOIN dbo.USER_Addresses AS adr ON cntr.CountryId = adr.CountryId
								LEFT OUTER JOIN dbo.GEO_States AS st ON adr.StateId = st.StateId
								RIGHT OUTER JOIN ( SELECT   po.SellerUserId ,
															pp.Amount ,
															pp.PaymentDate ,
															trx.Fee ,
															ipl.CurrencyId ,
															c.CurrencyName ,
															c.ISO ,
															c.Symbol
												   FROM     dbo.BASE_CurrencyLib
															AS c
															INNER JOIN dbo.BILL_ItemsPriceList
															AS ipl ON c.CurrencyId = ipl.CurrencyId
															RIGHT OUTER JOIN dbo.SALE_OrderLinePayments
															AS pp
															INNER JOIN dbo.SALE_OrderLines
															AS pl ON pp.OrderLineId = pl.LineId
															INNER JOIN dbo.SALE_Orders
															AS po ON pl.OrderId = po.OrderId
															INNER JOIN dbo.SALE_PaymentStatusesLOV
															AS pt ON pp.StatusId = pt.StatusId
															INNER JOIN dbo.SALE_Transactions
															AS trx ON pp.PaymentId = trx.PaymentId
																  AND pl.LineId = trx.OrderLineId ON ipl.PriceLineId = pl.PriceLineId
												   WHERE    ( pt.StatusCode = 'COMPLETED' )
															AND ( DATEPART(year,
																  pp.PaymentDate) = @Year )
															AND ( DATEPART(month,
																  pp.PaymentDate) = @Month )
															AND ( @UserId IS NULL )
															OR ( pt.StatusCode = 'COMPLETED' )
															AND ( DATEPART(year,
																  pp.PaymentDate) = @Year )
															AND ( DATEPART(month,
																  pp.PaymentDate) = @Month )
															AND ( po.SellerUserId = @UserId )
												 ) AS s
								INNER JOIN dbo.Users AS u ON s.SellerUserId = u.Id ON adr.AddressId = u.PayoutAddressID
					  GROUP BY  s.SellerUserId ,
								u.Email ,
								u.Nickname ,
								u.FirstName ,
								u.LastName ,
								u.PayoutTypeId ,
								u.PaypalEmail ,
								u.PayoutAddressID ,
								adr.CountryId ,
								cntr.CountryName ,
								adr.StateId ,
								st.StateName ,
								adr.FirstName ,
								adr.LastName ,
								adr.CityName ,
								adr.Street1 ,
								adr.Street2 ,
								adr.PostalCode ,
								adr.Region ,
								ISNULL(s.CurrencyId,2),
								ISNULL(s.CurrencyName,'U.S. Dollar'),
								ISNULL(s.ISO,'USD'),
								ISNULL(s.Symbol,'$')
					) AS sp
					FULL OUTER JOIN ( SELECT    r.SellerUserId ,
												u.Email ,
												u.Nickname ,
												u.FirstName ,
												u.LastName ,
												SUM(ABS(r.Amount)) AS total ,
												SUM(ABS(r.Fee)) AS fee,
												u.PayoutTypeId ,
												u.PaypalEmail ,
												u.PayoutAddressID ,
												adr.CountryId ,
												cntr.CountryName ,
												adr.StateId ,
												st.StateName ,
												adr.FirstName AS AddressFirstName ,
												adr.LastName AS AddressLastName ,
												adr.CityName ,
												adr.Street1 ,
												adr.Street2 ,
												adr.PostalCode ,
												adr.Region,
												ISNULL(r.CurrencyId,2) AS CurrencyId,
												ISNULL(r.CurrencyName,'U.S. Dollar') AS CurrencyName,
												ISNULL(r.ISO,'USD') AS ISO ,
												ISNULL(r.Symbol,'$') AS Symbol
									  FROM      dbo.GEO_CountriesLib AS cntr
												INNER JOIN dbo.USER_Addresses AS adr ON cntr.CountryId = adr.CountryId
												LEFT OUTER JOIN dbo.GEO_States AS st ON adr.StateId = st.StateId
												RIGHT OUTER JOIN dbo.Users AS u
												INNER JOIN ( SELECT
																  rf.Amount ,
																   trx.Fee,
																  rf.RefundDate ,
																  ro.SellerUserId ,
																  ipl.CurrencyId ,
																  c.CurrencyName ,
																  c.ISO ,
																  c.Symbol
															 FROM dbo.BASE_CurrencyLib
																  AS c
																  INNER JOIN dbo.BILL_ItemsPriceList
																  AS ipl ON c.CurrencyId = ipl.CurrencyId
																  RIGHT OUTER JOIN dbo.SALE_OrderLinePayments
																  AS rp
																  INNER JOIN dbo.SALE_OrderLinePaymentRefunds
																  AS rf ON rp.PaymentId = rf.PaymentId
																  INNER JOIN dbo.SALE_OrderLines
																  AS rl ON rp.OrderLineId = rl.LineId
																   INNER JOIN dbo.SALE_Transactions
																	AS trx ON rf.RefundId = trx.RefundId
																  INNER JOIN dbo.SALE_Orders
																  AS ro ON rl.OrderId = ro.OrderId ON ipl.PriceLineId = rl.PriceLineId
															 WHERE (@UserId IS NULL OR ro.SellerUserId = @UserId)
														   ) AS r ON u.Id = r.SellerUserId ON adr.AddressId = u.PayoutAddressID
									  WHERE     ( DATEPART(year, r.RefundDate) = @Year )
												AND ( DATEPART(month, r.RefundDate) = @Month )
									  GROUP BY  r.SellerUserId ,
												u.Email ,
												u.Nickname ,
												u.FirstName ,
												u.LastName ,
												u.PayoutTypeId ,
												u.PaypalEmail ,
												u.PayoutAddressID ,
												adr.CountryId ,
												cntr.CountryName ,
												adr.StateId ,
												st.StateName ,
												adr.FirstName ,
												adr.LastName ,
												adr.CityName ,
												adr.Street1 ,
												adr.Street2 ,
												adr.PostalCode ,
												adr.Region,
												ISNULL(r.CurrencyId,2),
												ISNULL(r.CurrencyName,'U.S. Dollar'),
												ISNULL(r.ISO,'USD'),
												ISNULL(r.Symbol,'$')
									) AS sr ON sr.SellerUserId = sp.SellerUserId
    END

GO
/****** Object:  StoredProcedure [dbo].[sp_ADMIN_GetSummaryReport]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-2-25
-- Description:	Get Summary report data
-- =============================================
CREATE PROCEDURE [dbo].[sp_ADMIN_GetSummaryReport]
(
	@from DATETIME = '07/01/2012' ,
    @to DATETIME = NULL ,
	@groupBy VARCHAR(15) = 'month'

)
AS
BEGIN
	SET NOCOUNT ON;

		IF(@to IS NULL) SET @to=DATEADD(DAY, 1,GETDATE())

		SELECT p.period,
				ISNULL(usr.cnt,0) AS users,
				ISNULL(t.total,0) AS total,
				ISNULL(crs.cnt,0) AS courses,
				ISNULL(au.cnt,0) AS authors

		FROM dbo.[tvf_ADMIN_PeriodTable](@from,@to,@groupBy) as p

		LEFT OUTER JOIN ( 
							SELECT  CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(Created AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, Created) AS VARCHAR)  + '-' +  CAST(DATEPART(month, Created) AS VARCHAR)  + '-' +  CAST(DATEPART(week, Created) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, Created) AS VARCHAR) + '-' +  CAST(DATEPART(month, Created) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, Created) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, Created) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, Created) AS VARCHAR)
										ELSE CAST(DATEPART(year, Created) AS VARCHAR) + '-' + CAST(DATEPART(month, Created) AS VARCHAR)
									END	AS period ,
									COUNT_BIG(Id) AS cnt
									FROM      dbo.Users AS u
								   WHERE    u.Created BETWEEN @from AND @to
								  GROUP BY CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(Created AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, Created) AS VARCHAR)  + '-' +  CAST(DATEPART(month, Created) AS VARCHAR)  + '-' +  CAST(DATEPART(week, Created) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, Created) AS VARCHAR) + '-' +  CAST(DATEPART(month, Created) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, Created) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, Created) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, Created) AS VARCHAR)
										ELSE CAST(DATEPART(year, Created) AS VARCHAR) + '-' + CAST(DATEPART(month, Created) AS VARCHAR)
									END
						) AS usr ON p.period = usr.period

		LEFT OUTER JOIN (
							SELECT  CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(h.OrderDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, h.OrderDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, h.OrderDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, h.OrderDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, h.OrderDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, h.OrderDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, h.OrderDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, h.OrderDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, h.OrderDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, h.OrderDate) AS VARCHAR) + '-' + CAST(DATEPART(month, h.OrderDate) AS VARCHAR)
									END	AS period ,  							
											ISNULL(SUM(p.TotalAmount), 0) AS total
								  FROM      dbo.SALE_OrderLines AS l
											INNER JOIN dbo.SALE_Orders AS h ON l.OrderId = h.OrderId
											LEFT OUTER JOIN dbo.vw_SALE_OrderLineTotalPayments
											AS p ON l.LineId = p.LineId
								  WHERE     h.OrderDate BETWEEN @from AND @to
								  GROUP BY  CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(h.OrderDate AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, h.OrderDate) AS VARCHAR)  + '-' +  CAST(DATEPART(month, h.OrderDate) AS VARCHAR)  + '-' +  CAST(DATEPART(week, h.OrderDate) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, h.OrderDate) AS VARCHAR) + '-' +  CAST(DATEPART(month, h.OrderDate) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, h.OrderDate) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, h.OrderDate) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, h.OrderDate) AS VARCHAR)
										ELSE CAST(DATEPART(year, h.OrderDate) AS VARCHAR) + '-' + CAST(DATEPART(month, h.OrderDate) AS VARCHAR)
									END
					) AS t ON t.period = p.period

		LEFT OUTER JOIN ( SELECT   CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(Created AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, Created) AS VARCHAR)  + '-' +  CAST(DATEPART(month, Created) AS VARCHAR)  + '-' +  CAST(DATEPART(week, Created) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, Created) AS VARCHAR) + '-' +  CAST(DATEPART(month, Created) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, Created) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, Created) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, Created) AS VARCHAR)
										ELSE CAST(DATEPART(year, Created) AS VARCHAR) + '-' + CAST(DATEPART(month, Created) AS VARCHAR)
									END	AS period ,
											COUNT_BIG(Id) AS cnt
								  FROM      dbo.Courses AS c
								   WHERE    c.Created BETWEEN @from AND @to
								  GROUP BY  CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(Created AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, Created) AS VARCHAR)  + '-' +  CAST(DATEPART(month, Created) AS VARCHAR)  + '-' +  CAST(DATEPART(week, Created) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, Created) AS VARCHAR) + '-' +  CAST(DATEPART(month, Created) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, Created) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, Created) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, Created) AS VARCHAR)
										ELSE CAST(DATEPART(year, Created) AS VARCHAR) + '-' + CAST(DATEPART(month, Created) AS VARCHAR)
									END	
								) AS crs ON crs.period = p.period

		LEFT OUTER JOIN (
					SELECT    CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(addon AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, addon) AS VARCHAR)  + '-' +  CAST(DATEPART(month, addon) AS VARCHAR)  + '-' +  CAST(DATEPART(week, addon) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, addon) AS VARCHAR) + '-' +  CAST(DATEPART(month, addon) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, addon) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, addon) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, addon) AS VARCHAR)
										ELSE CAST(DATEPART(year, addon) AS VARCHAR) + '-' + CAST(DATEPART(month, addon) AS VARCHAR)
									END	AS period  ,
							COUNT_BIG(id) AS cnt
					FROM      (
                                SELECT  a.id ,
                                        MIN(a.addon) AS addon
                                FROM    ( SELECT    AuthorUserId AS id ,
                                                    MIN(Created) AS addon
                                          FROM      dbo.Courses AS c
                                          WHERE     c.Created BETWEEN @from AND @to
                                          GROUP BY  AuthorUserId
                                          UNION
                                          SELECT    OwnerUserID AS id ,
                                                    MIN(AddOn) AS addon
                                          FROM      dbo.WebStores AS c
                                          WHERE     c.AddOn BETWEEN @from AND @to
                                          GROUP BY  OwnerUserID
                                        ) AS a
                                GROUP BY a.id
							) AS auth
					GROUP BY  CASE @groupBy
										WHEN 'day'     THEN CAST(CAST(addon AS DATE) AS VARCHAR) 
										WHEN 'week'    THEN CAST(DATEPART(year, addon) AS VARCHAR)  + '-' +  CAST(DATEPART(month, addon) AS VARCHAR)  + '-' +  CAST(DATEPART(week, addon) AS VARCHAR)
										WHEN 'month'   THEN CAST(DATEPART(year, addon) AS VARCHAR) + '-' +  CAST(DATEPART(month, addon) AS VARCHAR)
										WHEN 'quarter' THEN CAST(DATEPART(year, addon) AS VARCHAR) + '-' +  CAST(DATEPART(quarter, addon) AS VARCHAR)
										WHEN 'year'    THEN CAST(DATEPART(year, addon) AS VARCHAR)
										ELSE CAST(DATEPART(year, addon) AS VARCHAR) + '-' + CAST(DATEPART(month, addon) AS VARCHAR)
									END
		) AS au ON au.period = p.period
END

GO
/****** Object:  StoredProcedure [dbo].[sp_ADMIN_GetVideoStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-5-1
-- Description:	Get video stats report
-- =============================================
CREATE PROCEDURE [dbo].[sp_ADMIN_GetVideoStats]
    @from DATETIME ,
    @to DATETIME
AS
    BEGIN
	
        SET NOCOUNT ON;

        SELECT  CAST(p.period AS DATE) period,
                ISNULL(v.cnt, 0) AS total ,
                ISNULL(av.cnt, 0) AS used
        FROM    dbo.[tvf_ADMIN_PeriodTable](@from, @to, 'day') AS p
                LEFT OUTER JOIN ( SELECT    CAST(CreationDate AS DATE) AS period ,
                                            COUNT(VideoId) AS cnt
                                  FROM      dbo.USER_Videos AS u
                                  WHERE     u.CreationDate BETWEEN @from AND @to
                                  GROUP BY  CAST(CreationDate AS DATE)
                                ) AS v ON p.period = v.period
                LEFT OUTER JOIN ( SELECT    CAST(CreationDate AS DATE) AS period ,
                                            COUNT(VideoId) AS cnt
                                  FROM      dbo.USER_Videos AS u
                                  WHERE     ( u.CreationDate BETWEEN @from AND @to )
                                            AND u.Attached2Chapter = 1
                                  GROUP BY  CAST(CreationDate AS DATE)
                                ) AS av ON p.period = av.period
    END

GO
/****** Object:  StoredProcedure [dbo].[sp_ADMIN_UpdateUserVideos]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-5-1
-- Description:	Update video usage
-- =============================================
CREATE PROCEDURE [dbo].[sp_ADMIN_UpdateUserVideos]
AS
    BEGIN
	
	;
	 WITH    t AS ( SELECT   SUM(v.cnt) AS total ,
                                v.id
                       FROM     ( SELECT    COUNT(Id) AS cnt ,
                                            VideoSupplierIdentifier AS id
                                  FROM      dbo.ChapterVideos AS c
                                  GROUP BY  VideoSupplierIdentifier
                                  UNION ALL
                                  SELECT    COUNT([Id]) AS cnt ,
                                            CASE WHEN ( ISNUMERIC(OverviewVideoIdentifier) = 1 )
                                                 THEN CAST(OverviewVideoIdentifier AS BIGINT)
                                                 ELSE -1
                                            END AS id
                                  FROM      [dbo].[Courses]
                                  WHERE     OverviewVideoIdentifier IS NOT NULL
                                  GROUP BY  OverviewVideoIdentifier
                                  UNION ALL
                                  SELECT    COUNT([BundleId]) AS cnt ,
                                            OverviewVideoIdentifier AS id
                                  FROM      [dbo].[CRS_Bundles]
                                  GROUP BY  OverviewVideoIdentifier
                                ) AS v
                       WHERE    LEN(v.id) > 0
                       GROUP BY v.id
                     )
            UPDATE  [dbo].[USER_Videos]
            SET     Attached2Chapter = CASE ISNULL(t.total, 0)
                                         WHEN 0 THEN 0
                                         ELSE 1
                                       END
            FROM    t RIGHT OUTER JOIN dbo.USER_Videos AS v ON t.id = v.BcIdentifier

    END

GO
/****** Object:  StoredProcedure [dbo].[sp_FACT_DASH_UpdatePlatformStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-21
-- Description:	Update platform stats
-- =============================================
CREATE PROCEDURE [dbo].[sp_FACT_DASH_UpdatePlatformStats]
AS
BEGIN
	
	    DECLARE @CurDate DATE ,
			@CurSourceId TINYINT ,
			@FactId INT ,
			@NewAuthors INT = 0 ,
			@TotalAuthors INT = 0 ,
			@NewItems INT = 0 ,
			@TotalItems INT = 0 ,
			@NewStores INT = 0 ,
			@TotalStores INT = 0 ,
			@NewLearners INT = 0 ,
			@TotalLearners INT = 0 ,
			@NewSales INT = 0 ,
			@TotalSales INT = 0,
			@TotalPlatformNew INT = 0

    SELECT  @CurDate = ISNULL(MAX(FactDate), CAST('01/01/2014' AS DATE))
    FROM    dbo.FACT_DASH_DailyPlatformStats
		
    WHILE ( @CurDate <= CAST(GETDATE() AS DATE) )
        BEGIN
	
            DECLARE source_cursor CURSOR
            FOR
                SELECT  RegistrationTypeId
                FROM    dbo.ADMIN_RegistrationSourcesLOV
                WHERE   IncludeInStats = 1

            OPEN source_cursor   
            FETCH NEXT FROM source_cursor INTO @CurSourceId 

            WHILE @@FETCH_STATUS = 0
                BEGIN   

--------------------------------------- Total
					
					IF(@CurSourceId = 1) -- LFE
						BEGIN
							SELECT @TotalPlatformNew = COUNT(Id)
							FROM dbo.Users
							WHERE CAST(Created AS DATE) = CAST(@CurDate AS DATE)
						END
					ELSE IF(@CurSourceId = 2) -- WIX
						BEGIN
							SELECT @TotalPlatformNew = COUNT(InstallationId)
							FROM dbo.APP_PluginInstallations
							WHERE CAST(AddOn AS DATE) = CAST(@CurDate AS DATE)
							      AND (TypeId = 1)
						END
					ELSE IF(@CurSourceId = 3) -- FB
						BEGIN
							SELECT @TotalPlatformNew = COUNT(InstallationId)
							FROM dbo.APP_PluginInstallations
							WHERE CAST(AddOn AS DATE) = CAST(@CurDate AS DATE)
							      AND (TypeId = 2)
						END
					ELSE IF(@CurSourceId = 4) -- WP
						BEGIN
							SELECT @TotalPlatformNew = COUNT(InstallationId)
							FROM dbo.APP_PluginInstallations
							WHERE CAST(AddOn AS DATE) = CAST(@CurDate AS DATE)
							      AND (TypeId = 3)
						END
---------------------------------------- AUTHORS
      
					--new authors
                    SELECT  @NewAuthors = COUNT(DISTINCT t.AuthorId)
                    FROM    ( SELECT    c.Id AS AuthorId ,
                                        i.AddOn ,
                                        s.RegistrationSourceId
                              FROM      dbo.WebStoreItems AS i
                                        INNER JOIN dbo.Courses AS c ON i.CourseId = c.Id
                                        INNER JOIN dbo.WebStoreCategories AS wc ON i.WebStoreCategoryID = wc.WebStoreCategoryID
                                        INNER JOIN dbo.WebStores AS s ON s.StoreID = wc.WebStoreID
                              UNION
                              SELECT    b.AuthorId ,
                                        si.AddOn ,
                                        ws.RegistrationSourceId
                              FROM      dbo.CRS_Bundles AS b
                                        INNER JOIN dbo.WebStoreItems AS si ON b.BundleId = si.BundleId
                                        INNER JOIN dbo.WebStoreCategories AS sc ON si.WebStoreCategoryID = sc.WebStoreCategoryID
                                        INNER JOIN dbo.WebStores AS ws ON ws.StoreID = sc.WebStoreID
                            ) AS T
                    WHERE   CAST(t.AddOn AS DATE) = CAST(@CurDate AS DATE)
                            AND t.RegistrationSourceId = @CurSourceId

					--total authors
                    SELECT  @TotalAuthors = COUNT(DISTINCT t.AuthorId)
                    FROM    ( SELECT    c.Id AS AuthorId ,
                                        i.AddOn ,
                                        s.RegistrationSourceId
                              FROM      dbo.WebStoreItems AS i
                                        INNER JOIN dbo.Courses AS c ON i.CourseId = c.Id
                                        INNER JOIN dbo.WebStoreCategories AS wc ON i.WebStoreCategoryID = wc.WebStoreCategoryID
                                        INNER JOIN dbo.WebStores AS s ON s.StoreID = wc.WebStoreID
                              UNION
                              SELECT    b.AuthorId ,
                                        si.AddOn ,
                                        ws.RegistrationSourceId
                              FROM      dbo.CRS_Bundles AS b
                                        INNER JOIN dbo.WebStoreItems AS si ON b.BundleId = si.BundleId
                                        INNER JOIN dbo.WebStoreCategories AS sc ON si.WebStoreCategoryID = sc.WebStoreCategoryID
                                        INNER JOIN dbo.WebStores AS ws ON ws.StoreID = sc.WebStoreID
                            ) AS t
                    WHERE   CAST(t.AddOn AS DATE) <= CAST(@CurDate AS DATE)
                            AND t.RegistrationSourceId = @CurSourceId

---------------------------------------- ITEMS
      
					--new items
                    SELECT  @NewItems = COUNT(DISTINCT i.WebstoreItemId)
                    FROM    dbo.WebStores AS s
                            INNER JOIN dbo.WebStoreCategories AS c ON s.StoreID = c.WebStoreID
                            INNER JOIN dbo.WebStoreItems AS i ON c.WebStoreCategoryID = i.WebStoreCategoryID
                    WHERE   CAST(i.AddOn AS DATE) = CAST(@CurDate AS DATE)
                            AND s.RegistrationSourceId = @CurSourceId

					--total items
                    SELECT  @TotalItems = COUNT(DISTINCT i.WebstoreItemId)
                    FROM    dbo.WebStores AS s
                            INNER JOIN dbo.WebStoreCategories AS c ON s.StoreID = c.WebStoreID
                            INNER JOIN dbo.WebStoreItems AS i ON c.WebStoreCategoryID = i.WebStoreCategoryID
                    WHERE   CAST(i.AddOn AS DATE) <= CAST(@CurDate AS DATE)
                            AND s.RegistrationSourceId = @CurSourceId

---------------------------------------- STORES

					--new stores
                    SELECT  @NewStores = COUNT(s.StoreID)
                    FROM    dbo.WebStores AS s
                    WHERE   CAST(s.AddOn AS DATE) = CAST(@CurDate AS DATE)
                            AND s.RegistrationSourceId = @CurSourceId

					--total stores
                    SELECT  @TotalStores = COUNT(s.StoreID)
                    FROM    dbo.WebStores AS s
                    WHERE   CAST(s.AddOn AS DATE) <= CAST(@CurDate AS DATE)
                            AND s.RegistrationSourceId = @CurSourceId

----------------------------------------- LEARNERS
					-- new learners
                    SELECT  @NewLearners = COUNT(DISTINCT o.BuyerUserId)
                    FROM    dbo.SALE_Orders AS o
                            LEFT OUTER JOIN dbo.WebStores AS s ON o.WebStoreId = s.StoreID
                            CROSS JOIN dbo.ADMIN_RegistrationSourcesLOV AS r
                    WHERE   ( r.RegistrationTypeCode = 'LFE' )
                            AND CAST(o.OrderDate AS DATE) = CAST(@CurDate AS DATE)
                            AND ( ISNULL(s.RegistrationSourceId,
                                         r.RegistrationTypeId) = @CurSourceId )

					-- total learners
                    SELECT  @TotalLearners = COUNT(DISTINCT o.BuyerUserId)
                    FROM    dbo.SALE_Orders AS o
                            LEFT OUTER JOIN dbo.WebStores AS s ON o.WebStoreId = s.StoreID
                            CROSS JOIN dbo.ADMIN_RegistrationSourcesLOV AS r
                    WHERE   ( r.RegistrationTypeCode = 'LFE' )
                            AND CAST(o.OrderDate AS DATE) <= CAST(@CurDate AS DATE)
                            AND ( ISNULL(s.RegistrationSourceId,
                                         r.RegistrationTypeId) = @CurSourceId )

----------------------------------------- SALES

					-- new sales
                    SELECT  @NewSales = COUNT(o.Sid)
                    FROM    dbo.SALE_Orders AS o
                            LEFT OUTER JOIN dbo.WebStores AS s ON o.WebStoreId = s.StoreID
                            CROSS JOIN dbo.ADMIN_RegistrationSourcesLOV AS r
                    WHERE   ( r.RegistrationTypeCode = 'LFE' )
                            AND CAST(o.OrderDate AS DATE) = CAST(@CurDate AS DATE)
                            AND ( ISNULL(s.RegistrationSourceId,
                                         r.RegistrationTypeId) = @CurSourceId )

					-- total sales
                    SELECT  @TotalSales = COUNT(o.Sid)
                    FROM    dbo.SALE_Orders AS o
                            LEFT OUTER JOIN dbo.WebStores AS s ON o.WebStoreId = s.StoreID
                            CROSS JOIN dbo.ADMIN_RegistrationSourcesLOV AS r
                    WHERE   ( r.RegistrationTypeCode = 'LFE' )
                            AND CAST(o.OrderDate AS DATE) <= CAST(@CurDate AS DATE)
                            AND ( ISNULL(s.RegistrationSourceId,
                                         r.RegistrationTypeId) = @CurSourceId )


----------------------------------------- UPDATE FACT TABLE

                    SELECT  @FactId = FactId
                    FROM    dbo.FACT_DASH_DailyPlatformStats
                    WHERE   ( FactDate = @CurDate )
                            AND RegistrationTypeId = @CurSourceId

                    IF ( @@ROWCOUNT = 0 ) -- Add new row
                        BEGIN

                            INSERT  INTO dbo.FACT_DASH_DailyPlatformStats
                                    ( FactDate ,
                                      RegistrationTypeId ,
									  TotalPlatformNew,
                                      NewAuthors ,
                                      TotalAuhtors ,
                                      NewItems ,
                                      TotalItems ,
                                      NewStores ,
                                      TotalStores ,
                                      NewLearners ,
                                      TotalLearners ,
                                      NewSales ,
                                      TotalSales
                                    )
                            VALUES  ( @CurDate ,
                                      @CurSourceId ,
									  @TotalPlatformNew,
                                      @NewAuthors ,
                                      @TotalAuthors ,
                                      @NewItems ,
                                      @TotalItems ,
                                      @NewStores ,
                                      @TotalStores ,
                                      @NewLearners ,
                                      @TotalLearners ,
                                      @NewSales ,
                                      @TotalSales
									 )
                        END
                    ELSE	-- update current row
                        BEGIN
	
                            UPDATE  dbo.FACT_DASH_DailyPlatformStats
                            SET     TotalPlatformNew	= @TotalPlatformNew,
									NewAuthors			= @NewAuthors ,
									TotalAuhtors		= @TotalAuthors ,
									NewItems			= @NewItems ,
									TotalItems			= @TotalItems ,
									NewStores			= @NewStores ,
									TotalStores			= @TotalStores ,
									NewLearners			= @NewLearners ,
									TotalLearners		= @TotalLearners ,
									NewSales			= @NewSales ,
									TotalSales			= @TotalSales
                            WHERE   FactId = @FactId
                        END

                    FETCH NEXT FROM source_cursor INTO @CurSourceId   
                END   

            CLOSE source_cursor   
            DEALLOCATE source_cursor

            SET @CurDate = DATEADD(DAY, 1, @CurDate)
        END


END

GO
/****** Object:  StoredProcedure [dbo].[sp_FACT_DASH_UpdateSalesStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-21
-- Description:	Update platform stats
-- =============================================
CREATE PROCEDURE [dbo].[sp_FACT_DASH_UpdateSalesStats]
AS
BEGIN
	    DECLARE @CurDate DATE ,
			@CurrencyId TINYINT ,
			@FactId INT ,
			@TotalOneTimeSales MONEY = 0,
			@TotalSubscriptionSales MONEY = 0,
			@TotalRentalSales MONEY = 0

    SELECT  @CurDate = ISNULL(MAX(FactDate), CAST('01/01/2014' AS DATE))
    FROM    dbo.FACT_DASH_DailySalesStats
		
    WHILE ( @CurDate <= CAST(GETDATE() AS DATE) )
        BEGIN
	
            DECLARE currency_cursor CURSOR
            FOR
                SELECT  CurrencyId
                FROM    dbo.BASE_CurrencyLib
                WHERE   IsActive = 1

            OPEN currency_cursor   
            FETCH NEXT FROM currency_cursor INTO @CurrencyId 

            WHILE @@FETCH_STATUS = 0
                BEGIN   

---------------------------------------- ONE TIME
      
				SELECT @TotalOneTimeSales = ISNULL(SUM(p.Amount),0)
				FROM    dbo.SALE_OrderLines AS l
						INNER JOIN dbo.SALE_OrderLineTypesLOV AS t ON l.LineTypeId = t.TypeId
						INNER JOIN dbo.SALE_OrderLinePayments AS p ON l.LineId = p.OrderLineId
						INNER JOIN dbo.SALE_PaymentStatusesLOV AS s ON p.StatusId = s.StatusId
						INNER JOIN dbo.BASE_CurrencyLib AS c ON p.Currency = c.ISO
				WHERE   ( s.StatusCode = 'COMPLETED' )
						AND ( CAST(p.PaymentDate AS DATE) = CAST(@CurDate AS DATE))
						AND (c.CurrencyId = @CurrencyId)
						AND (t.TypeCode = 'SALE')

---------------------------------------- SUBSCRIPTION
      
				SELECT @TotalSubscriptionSales = ISNULL(SUM(p.Amount),0)
				FROM    dbo.SALE_OrderLines AS l
						INNER JOIN dbo.SALE_OrderLineTypesLOV AS t ON l.LineTypeId = t.TypeId
						INNER JOIN dbo.SALE_OrderLinePayments AS p ON l.LineId = p.OrderLineId
						INNER JOIN dbo.SALE_PaymentStatusesLOV AS s ON p.StatusId = s.StatusId
						INNER JOIN dbo.BASE_CurrencyLib AS c ON p.Currency = c.ISO
				WHERE   ( s.StatusCode = 'COMPLETED' )
						AND ( CAST(p.PaymentDate AS DATE) = CAST(@CurDate AS DATE))
						AND (c.CurrencyId = @CurrencyId)
						AND (t.TypeCode = 'SUBSCRIPTION')

---------------------------------------- RENTAL
      
				SELECT @TotalRentalSales = ISNULL(SUM(p.Amount),0)
				FROM    dbo.SALE_OrderLines AS l
						INNER JOIN dbo.SALE_OrderLineTypesLOV AS t ON l.LineTypeId = t.TypeId
						INNER JOIN dbo.SALE_OrderLinePayments AS p ON l.LineId = p.OrderLineId
						INNER JOIN dbo.SALE_PaymentStatusesLOV AS s ON p.StatusId = s.StatusId
						INNER JOIN dbo.BASE_CurrencyLib AS c ON p.Currency = c.ISO
				WHERE   ( s.StatusCode = 'COMPLETED' )
						AND ( CAST(p.PaymentDate AS DATE) = CAST(@CurDate AS DATE))
						AND (c.CurrencyId = @CurrencyId)
						AND (t.TypeCode = 'RENTAL')

----------------------------------------- UPDATE FACT TABLE

                    SELECT  @FactId = FactId
                    FROM    dbo.FACT_DASH_DailySalesStats
                    WHERE   ( FactDate = @CurDate )
                            AND CurrencyId = @CurrencyId

                    IF ( @@ROWCOUNT = 0 ) -- Add new row
                        BEGIN

						INSERT INTO dbo.FACT_DASH_DailySalesStats
							   (FactDate
							   ,CurrencyId
							   ,TotalOneTimeSales
							   ,TotalSubscriptionSales
							   ,TotalRentalSales)
						 VALUES
							   (@CurDate
							   ,@CurrencyId
							   ,@TotalOneTimeSales
							   ,@TotalSubscriptionSales
							   ,@TotalRentalSales)

                        END
                    ELSE	-- update current row
                        BEGIN

						UPDATE dbo.FACT_DASH_DailySalesStats
						   SET TotalOneTimeSales	  = @TotalOneTimeSales
							  ,TotalSubscriptionSales = @TotalSubscriptionSales
							  ,TotalRentalSales		  = @TotalRentalSales
                            WHERE   FactId = @FactId
                        END

                    FETCH NEXT FROM currency_cursor INTO @CurrencyId   
                END   

            CLOSE currency_cursor   
            DEALLOCATE currency_cursor

            SET @CurDate = DATEADD(DAY, 1, @CurDate)
        END



END

GO
/****** Object:  StoredProcedure [dbo].[sp_FACT_DASH_UpdateTotalStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-12-21
-- Description:	Update total stats
-- =============================================
CREATE PROCEDURE [dbo].[sp_FACT_DASH_UpdateTotalStats]
AS
BEGIN
	    DECLARE @CurDate DATE ,
			@FactId INT ,
			@NewAuthors INT = 0,
			@NewCourses INT = 0,
			@NewBundles INT = 0,
			@NewStores INT = 0,
			@NewLearners INT = 0,
			@NumOfOneTimeSales INT = 0,
			@NumOfSubscriptionSales INT = 0,
			@NumOfRentalSales INT = 0,
			@NumOfFreeSales INT = 0,
			@NewMailchimpLists	INT	= 0,
			@NewMBGJoined	INT	= 0,
			@MBGCancelled	INT	= 0

    SELECT  @CurDate = ISNULL(MAX(FactDate), CAST('01/01/2014' AS DATE))
    FROM    dbo.FACT_DASH_DailyTotalStats
		
    WHILE ( @CurDate <= CAST(GETDATE() AS DATE) )
        BEGIN
	
        
---------------------------------------- AUTHORS
      
					--new authors
                    SELECT  @NewAuthors = COUNT(DISTINCT t.AuthorId)
                    FROM    dbo.vw_FACT_DASH_Authors AS t
                    WHERE   CAST(t.AddOn AS DATE) = CAST(@CurDate AS DATE)

---------------------------------------- ITEMS
      
					--new courses
                    SELECT  @NewCourses = COUNT(c.Id)
                    FROM   dbo.Courses AS c 
                    WHERE   CAST(c.Created AS DATE) = CAST(@CurDate AS DATE)

					--total bundles
                    SELECT  @NewBundles = COUNT(b.BundleId)
                    FROM     dbo.CRS_Bundles AS b
                    WHERE   CAST(b.AddOn AS DATE) = CAST(@CurDate AS DATE)

---------------------------------------- STORES

					--new stores
                    SELECT  @NewStores = COUNT(s.StoreID)
                    FROM    dbo.WebStores AS s
                    WHERE   CAST(s.AddOn AS DATE) = CAST(@CurDate AS DATE)

----------------------------------------- LEARNERS

					-- new learners
                    SELECT  @NewLearners = COUNT(DISTINCT o.BuyerUserId)
                    FROM    dbo.SALE_Orders AS o
                    WHERE   CAST(o.OrderDate AS DATE) = CAST(@CurDate AS DATE)

				
----------------------------------------- SALES

					-- number of free sales
                    SELECT      @NumOfFreeSales = COUNT(l.LineId)
					FROM        dbo.SALE_OrderLines AS l INNER JOIN
								dbo.SALE_OrderLineTypesLOV AS t ON l.LineTypeId = t.TypeId INNER JOIN
								dbo.SALE_Orders AS o ON l.OrderId = o.OrderId
					WHERE    (l.TotalPrice = 0)
							 AND CAST(o.OrderDate AS DATE) = CAST(@CurDate AS DATE)

					-- number of one-time sales
					SELECT      @NumOfOneTimeSales = COUNT(l.LineId)
					FROM        dbo.SALE_OrderLines AS l INNER JOIN
								dbo.SALE_OrderLineTypesLOV AS t ON l.LineTypeId = t.TypeId INNER JOIN
								dbo.SALE_Orders AS o ON l.OrderId = o.OrderId
					WHERE    (t.TypeCode = 'SALE') 
							 AND (l.TotalPrice > 0)
							 AND CAST(o.OrderDate AS DATE) = CAST(@CurDate AS DATE)

								
					-- number of subscription sales
					SELECT      @NumOfSubscriptionSales = COUNT(l.LineId)
					FROM        dbo.SALE_OrderLines AS l INNER JOIN
								dbo.SALE_OrderLineTypesLOV AS t ON l.LineTypeId = t.TypeId INNER JOIN
								dbo.SALE_Orders AS o ON l.OrderId = o.OrderId
					WHERE    (t.TypeCode = 'SUBSCRIPTION') 
							 AND (l.TotalPrice > 0)
							 AND CAST(o.OrderDate AS DATE) = CAST(@CurDate AS DATE)

					-- number of rental sales
					SELECT      @NumOfRentalSales = COUNT(l.LineId)
					FROM        dbo.SALE_OrderLines AS l INNER JOIN
								dbo.SALE_OrderLineTypesLOV AS t ON l.LineTypeId = t.TypeId INNER JOIN
								dbo.SALE_Orders AS o ON l.OrderId = o.OrderId
					WHERE    (t.TypeCode = 'RENTAL') 
							 AND (l.TotalPrice > 0)
							 AND CAST(o.OrderDate AS DATE) = CAST(@CurDate AS DATE)


----------------------------------------- MBG

					SELECT  @NewMBGJoined = COUNT(l.EventID)
                    FROM    dbo.UserSessionsEventLogs AS l
                            INNER JOIN dbo.UserEventTypesLOV AS t ON l.EventTypeID = t.TypeId
                    WHERE   ( t.TypeCode = N'MBG_JOIN' )

					SELECT  @MBGCancelled = COUNT(l.EventID)
                    FROM    dbo.UserSessionsEventLogs AS l
                            INNER JOIN dbo.UserEventTypesLOV AS t ON l.EventTypeID = t.TypeId
                    WHERE   ( t.TypeCode = N'MBG_CANCEL' )

----------------------------------------- INTEGRATIONS

					--Mailchimp
					SELECT @NewMailchimpLists = COUNT(ListId)
					FROM	dbo.CHIMP_UserLists
					WHERE  CAST(AddOn AS DATE) = CAST(@CurDate AS DATE)

----------------------------------------- UPDATE FACT TABLE

                    SELECT  @FactId = FactId
                    FROM    dbo.FACT_DASH_DailyTotalStats
                    WHERE   ( FactDate = @CurDate )

                    IF ( @@ROWCOUNT = 0 ) -- Add new row
                        BEGIN

						INSERT INTO dbo.FACT_DASH_DailyTotalStats
								   (FactDate
								   ,NewAuthors
								   ,NewCourses
								   ,NewBundles
								   ,NewStores
								   ,NewLearners
								   ,NumOfOneTimeSales
								   ,NumOfSubscriptionSales
								   ,NumOfRentalSales
								   ,NumOfFreeSales
								   ,NewMailchimpLists
								   ,NewMBGJoined
								   ,MBGCancelled)
							 VALUES
								   (@CurDate
								   ,@NewAuthors
								   ,@NewCourses
								   ,@NewBundles
								   ,@NewStores
								   ,@NewLearners
								   ,@NumOfOneTimeSales
								   ,@NumOfSubscriptionSales
								   ,@NumOfRentalSales
								   ,@NumOfFreeSales
								   ,@NewMailchimpLists
								   ,@NewMBGJoined
								   ,@MBGCancelled)

                        END
                    ELSE	-- update current row
                        BEGIN

							UPDATE dbo.FACT_DASH_DailyTotalStats
								   SET   NewAuthors             = @NewAuthors
										,NewCourses             = @NewCourses
										,NewBundles             = @NewBundles
										,NewStores              = @NewStores
										,NewLearners            = @NewLearners
										,NumOfOneTimeSales      = @NumOfOneTimeSales
										,NumOfSubscriptionSales = @NumOfSubscriptionSales
										,NumOfRentalSales       = @NumOfRentalSales
										,NumOfFreeSales         = @NumOfFreeSales
									    ,NewMailchimpLists		= @NewMailchimpLists
										,NewMBGJoined			= @NewMBGJoined
										,MBGCancelled		    = @MBGCancelled
                            WHERE   FactId = @FactId
                        END                 

            SET @CurDate = DATEADD(DAY, 1, @CurDate)
        END



END

GO
/****** Object:  StoredProcedure [dbo].[sp_FACT_ImportDailyStats]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-4-7
-- Description:	Create facts daily statistic
-- =============================================
CREATE PROCEDURE [dbo].[sp_FACT_ImportDailyStats]	
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @CurDate DATE,
			@ZeroPrice MONEY = 0.01

		SELECT @CurDate  = ISNULL(MAX(FactDate), CAST('01/01/2014' AS DATE))
		FROM dbo.FACT_DailyStats 
		
		WHILE (@CurDate < CAST(GETDATE() AS DATE))
			BEGIN
	
				SELECT 1
				FROM	dbo.FACT_DailyStats
				WHERE (FactDate = @CurDate)

				IF(@@ROWCOUNT=0)
				BEGIN
					INSERT INTO dbo.FACT_DailyStats
							( FactDate ,
							  ItemsCreated ,
							  ItemsPublished ,
							  UsersCreated ,
							  WixUsersCreated ,
							  UserLogins ,
							  AuthorLogins ,
							  ReturnUsersLogins ,	         
							  StoresCreated ,
							  WixStoresCreated,
							  ItemsPurchased ,
							  FreeItemsPurchased 
							)
					SELECT  @CurDate,
							(cc.Created  + bc.Created) , 
							(cp.Published  + bp.Published), 
							uc.UserCreated,
							wixuc.WixUsersCreated,
							logins.TotalLogins,
							aulogins.AuthorLogins,
							r.ReturnUserLogins,
							wc.StoresCreated,
							wixs.WixStoresCreated,
							p.TotalPurchased,
							fp.FreelPurchased
							--courses created
							FROM (
							SELECT  ISNULL(COUNT(c.Id), 0) AS Created
							FROM    dbo.Courses AS c       
							WHERE   ( CAST(c.Created AS DATE) = CAST(@CurDate AS DATE) )  ) AS cc     

							CROSS JOIN
							--bundles created
							(SELECT  ISNULL(COUNT(b.BundleId), 0) AS Created
							FROM    dbo.CRS_Bundles AS b
							WHERE   ( CAST(b.AddOn AS DATE) = CAST(@CurDate AS DATE) ) ) AS bc

							--courses published
							CROSS	JOIN
							 (
							SELECT  ISNULL(COUNT(c.Id), 0) AS Published
							FROM    dbo.Courses AS c       
							WHERE    (c.PublishDate IS NOT NULL) AND ( CAST(c.PublishDate AS DATE) = CAST(@CurDate AS DATE) )  ) AS cp     

							CROSS JOIN

							--bundles pubslished
							(SELECT  ISNULL(COUNT(b.BundleId), 0) AS Published
							FROM    dbo.CRS_Bundles AS b
							WHERE   (b.PublishDate IS NOT NULL) AND ( CAST(b.PublishDate AS DATE) = CAST(@CurDate AS DATE) ) ) AS bp


							--users created
							CROSS JOIN
							(
								SELECT  ISNULL(COUNT(u.Id), 0) AS UserCreated
								FROM    dbo.Users AS u
								WHERE   ( CAST(u.Created AS DATE) = CAST(@CurDate AS DATE) ) 
							) AS uc

							--wix users created
							CROSS JOIN
							(
								SELECT  ISNULL(COUNT(u.Id), 0) AS WixUsersCreated
								FROM    dbo.Users AS u
								WHERE  (u.RegistrationTypeId=2) -- WIX
									  AND ( CAST(u.Created AS DATE) = CAST(@CurDate AS DATE) ) 
							) AS wixuc

							--total user logins
							CROSS JOIN 
							(
								SELECT ISNULL(COUNT(DISTINCT us.UserID),0) AS TotalLogins
								FROM	dbo.UserSessions AS us
								WHERE ( CAST(us.EventDate AS DATE) = CAST(@CurDate AS DATE) ) 
	
							) AS logins
	
							--total author logins
							CROSS JOIN
							(
							SELECT        ISNULL(COUNT(DISTINCT us.UserID), 0) AS AuthorLogins
							FROM            dbo.UserSessions AS us INNER JOIN
													 dbo.vw_USER_Authors ON us.UserID = dbo.vw_USER_Authors.UserId
							WHERE        (CAST(us.EventDate AS DATE) = CAST(@CurDate AS DATE))
							) AS aulogins

							-- total returned user logins
							CROSS JOIN 
							(
								SELECT  ISNULL(COUNT(DISTINCT ur.UserID), 0) AS ReturnUserLogins
								FROM    dbo.UserSessions AS ur
								WHERE   ( CAST(ur.EventDate AS DATE) = CAST(@CurDate AS DATE) )
										AND ( ur.UserID NOT IN (
											  SELECT  u.Id
											  FROM    dbo.Users AS u
											  WHERE   ( CAST(u.Created AS DATE) = CAST(@CurDate AS DATE) ) ))
	
							) AS r

							--total stores created
							CROSS JOIN
							(
								SELECT  ISNULL(COUNT(w.StoreID), 0) AS StoresCreated
								FROM    dbo.WebStores AS w
								WHERE   ( CAST(w.AddOn AS DATE) = CAST(@CurDate AS DATE) ) 
							) AS wc

							--total wix stores created
							CROSS JOIN
							(
								SELECT  ISNULL(COUNT(w.StoreID), 0) AS WixStoresCreated
								FROM    dbo.WebStores AS w
								WHERE  (w.WixInstanceId IS NOT NULL) AND ( CAST(w.AddOn AS DATE) = CAST(@CurDate AS DATE) ) 
							) AS wixs

							CROSS JOIN
							--total purchases
							(
							SELECT        ISNULL(COUNT(ol.LineId), 0) AS TotalPurchased
							FROM            dbo.SALE_Orders AS oh INNER JOIN
													 dbo.SALE_OrderLines AS ol ON oh.OrderId = ol.OrderId
							WHERE        (CAST(oh.OrderDate AS DATE) = CAST(@CurDate AS DATE))
							) AS p

							CROSS JOIN
							--total free purchases
							(
							SELECT        ISNULL(COUNT(ol.LineId), 0) AS FreelPurchased
							FROM            dbo.SALE_Orders AS oh INNER JOIN
													 dbo.SALE_OrderLines AS ol ON oh.OrderId = ol.OrderId
							WHERE   (ol.TotalPrice < @ZeroPrice) AND    (CAST(oh.OrderDate AS DATE) = CAST(@CurDate AS DATE))
							) AS fp
				END
				SET @CurDate = DATEADD(DAY,1,@CurDate)
			END
END

GO
/****** Object:  StoredProcedure [dbo].[sp_FACT_ImportDailyTotals]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-4-7
-- Description:	Create facts daily totals statistic
-- =============================================
CREATE PROCEDURE [dbo].[sp_FACT_ImportDailyTotals]	
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @CurDate DATE,
			@ZeroPrice MONEY = 0.01

		SELECT @CurDate  = ISNULL(MAX(FactDate), CAST('01/01/2014' AS DATE))
		FROM dbo.FACT_DailyTotals 
		
		WHILE (@CurDate < CAST(GETDATE() AS DATE))
			BEGIN
	
				SELECT 1
				FROM	dbo.FACT_DailyTotals
				WHERE (FactDate = @CurDate)

				IF(@@ROWCOUNT=0)
				BEGIN
					INSERT INTO dbo.FACT_DailyTotals
					        ( FactDate ,
					          TotalItems ,
					          TotalPublished ,
					          Attached2Stores ,
					          Attached2WixStores ,
					          TotalUsers ,
					          TotalAuthors ,
					          TotalLearners ,
					          ItemsPurchased ,
					          FreeItemsPurchased ,
					          StoresCreated ,
					          WixStoresCreated
					        )
					SELECT  @CurDate,
							(cc.Created  + bc.Created) AS ItemsCreated, 
							(cp.Published  + bp.Published) AS ItemsPublished, 
							(cps.Created + bps.Created) AS ItemsPublishedInStores,
							(cpsw.Created + bpsw.Created) AS ItemsPublishedInWixStores,
							--(cpsp.Created + bpsp.Created) AS ItemsPublishedInPublishedStores,
							uc.TotalUsers,
							ac.TotalAuthors,
							lc.TotalLearners,							
							p.TotalPurchased,
							fp.FreePurchased,
							wc.TotalStores,
							wixs.TotalWixStores
							FROM (
							SELECT  ISNULL(COUNT(c.Id), 0) AS Created
							FROM    dbo.Courses AS c       
							WHERE   ( CAST(c.Created AS DATE) <= CAST(@CurDate AS DATE) )  
							) AS cc     

							CROSS JOIN

							(
							SELECT  ISNULL(COUNT(b.BundleId), 0) AS Created
							FROM    dbo.CRS_Bundles AS b
							WHERE   ( CAST(b.AddOn AS DATE) <= CAST(@CurDate AS DATE) ) 
							) AS bc

							CROSS	JOIN
							 (
								SELECT  ISNULL(COUNT(c.Id), 0) AS Published
								FROM    dbo.Courses AS c       
								WHERE   (c.PublishDate IS NOT NULL AND CAST(c.PublishDate AS DATE) <= CAST(@CurDate AS DATE) )  OR ( c.StatusId = 2 AND ( CAST(c.Created AS DATE) <= CAST(@CurDate AS DATE) ) )--published 
							) AS cp     

							CROSS JOIN

							(
							SELECT  ISNULL(COUNT(b.BundleId), 0) AS Published
							FROM    dbo.CRS_Bundles AS b
							WHERE   ( b.PublishDate IS NOT NULL AND CAST(b.PublishDate AS DATE) <= CAST(@CurDate AS DATE) ) OR (b.StatusId = 2 AND  ( CAST(b.AddOn AS DATE) <= CAST(@CurDate AS DATE) ) )--published
							) AS bp

							CROSS JOIN

							(
							SELECT        ISNULL(COUNT(DISTINCT si.CourseId), 0) AS Created
							FROM            dbo.WebStores AS ws INNER JOIN
													 dbo.WebStoreCategories AS wc ON ws.StoreID = wc.WebStoreID INNER JOIN
													 dbo.WebStoreItems AS si ON wc.WebStoreCategoryID = si.WebStoreCategoryID INNER JOIN
													 dbo.Courses AS c ON si.CourseId = c.Id
							WHERE        (CAST(c.Created AS DATE) <= CAST(@CurDate AS DATE)) AND (si.CourseId IS NOT NULL) AND (c.StatusId = 2)
							) AS cps	

							CROSS JOIN

							(
							SELECT        ISNULL(COUNT(DISTINCT si.BundleId), 0) AS Created
							FROM            dbo.WebStores AS ws INNER JOIN
													 dbo.WebStoreCategories AS wc ON ws.StoreID = wc.WebStoreID INNER JOIN
													 dbo.WebStoreItems AS si ON wc.WebStoreCategoryID = si.WebStoreCategoryID INNER JOIN
													 dbo.CRS_Bundles AS b ON si.BundleId = b.BundleId
							WHERE        (b.StatusId = 2) AND (si.BundleId IS NOT NULL) AND (CAST(b.AddOn AS DATE) <= CAST(@CurDate AS DATE))
							) AS bps

							CROSS JOIN

							(
							SELECT        ISNULL(COUNT(DISTINCT si.CourseId), 0) AS Created
							FROM            dbo.WebStores AS ws INNER JOIN
													 dbo.WebStoreCategories AS wc ON ws.StoreID = wc.WebStoreID INNER JOIN
													 dbo.WebStoreItems AS si ON wc.WebStoreCategoryID = si.WebStoreCategoryID INNER JOIN
													 dbo.Courses AS c ON si.CourseId = c.Id
							WHERE        (CAST(c.Created AS DATE) <= CAST(@CurDate AS DATE)) AND (si.CourseId IS NOT NULL) AND (c.StatusId = 2) AND (ws.WixInstanceId IS NOT NULL)
							) AS cpsw	

							CROSS JOIN

							(
							SELECT        ISNULL(COUNT(DISTINCT si.BundleId), 0) AS Created
							FROM            dbo.WebStores AS ws INNER JOIN
													 dbo.WebStoreCategories AS wc ON ws.StoreID = wc.WebStoreID INNER JOIN
													 dbo.WebStoreItems AS si ON wc.WebStoreCategoryID = si.WebStoreCategoryID INNER JOIN
													 dbo.CRS_Bundles AS b ON si.BundleId = b.BundleId
							WHERE        (b.StatusId = 2) AND (si.BundleId IS NOT NULL) AND (CAST(b.AddOn AS DATE) <= CAST(@CurDate AS DATE)) AND (ws.WixInstanceId IS NOT NULL)
							) AS bpsw

							--CROSS JOIN

							--(
							--SELECT        ISNULL(COUNT(DISTINCT si.CourseId), 0) AS Created
							--FROM            dbo.WebStores AS ws INNER JOIN
							--						 dbo.WebStoreCategories AS wc ON ws.StoreID = wc.WebStoreID INNER JOIN
							--						 dbo.WebStoreItems AS si ON wc.WebStoreCategoryID = si.WebStoreCategoryID INNER JOIN
							--						 dbo.Courses AS c ON si.CourseId = c.Id
							--WHERE        (CAST(c.Created AS DATE) <= CAST(@CurDate AS DATE)) AND (si.CourseId IS NOT NULL) AND (c.StatusId = 2) AND (ws.StatusId = 2)
							--) AS cpsp	 

							--CROSS JOIN

							--(
							--SELECT        ISNULL(COUNT(DISTINCT si.BundleId), 0) AS Created
							--FROM            dbo.WebStores AS ws INNER JOIN
							--						 dbo.WebStoreCategories AS wc ON ws.StoreID = wc.WebStoreID INNER JOIN
							--						 dbo.WebStoreItems AS si ON wc.WebStoreCategoryID = si.WebStoreCategoryID INNER JOIN
							--						 dbo.CRS_Bundles AS b ON si.BundleId = b.BundleId
							--WHERE        (b.StatusId = 2) AND (si.BundleId IS NOT NULL) AND (CAST(b.AddOn AS DATE) <= CAST(@CurDate AS DATE)) AND (ws.StatusId = 2)
							--) AS bpsp

							CROSS JOIN
							(
								SELECT  ISNULL(COUNT(u.Id), 0) AS TotalUsers
								FROM    dbo.Users AS u
								WHERE   ( CAST(u.Created AS DATE) <= CAST(@CurDate AS DATE) ) 
							) AS uc

							CROSS JOIN
							(
								SELECT  ISNULL(COUNT(u.Id), 0) AS TotalAuthors
								FROM    dbo.vw_USER_Authors AS u
								WHERE   ( CAST(u.Created AS DATE) <= CAST(@CurDate AS DATE) ) 
							) AS ac

							CROSS JOIN
							(
								SELECT  ISNULL(COUNT(so.BuyerUserId), 0) AS TotalLearners
								FROM    dbo.SALE_Orders AS so
								WHERE   ( CAST(so.OrderDate AS DATE) <= CAST(@CurDate AS DATE) )  AND (so.SellerUserId <> so.BuyerUserId)
							) AS lc

							CROSS JOIN
							(
								SELECT  ISNULL(COUNT(w.StoreID), 0) AS TotalStores
								FROM    dbo.WebStores AS w
								WHERE   ( CAST(w.AddOn AS DATE) <= CAST(@CurDate AS DATE) ) 
							) AS wc

							CROSS JOIN
							(
								SELECT  ISNULL(COUNT(w.StoreID), 0) AS TotalWixStores
								FROM    dbo.WebStores AS w
								WHERE  (w.WixInstanceId IS NOT NULL) AND ( CAST(w.AddOn AS DATE) <= CAST(@CurDate AS DATE) ) 
							) AS wixs

							CROSS JOIN

							(
							SELECT        ISNULL(COUNT(ol.LineId), 0) AS TotalPurchased
							FROM            dbo.SALE_Orders AS oh INNER JOIN
													 dbo.SALE_OrderLines AS ol ON oh.OrderId = ol.OrderId
							WHERE        (CAST(oh.OrderDate AS DATE) <= CAST(@CurDate AS DATE))
							) AS p

							CROSS JOIN

							(
							SELECT        ISNULL(COUNT(ol.LineId), 0) AS FreePurchased
							FROM            dbo.SALE_Orders AS oh INNER JOIN
													 dbo.SALE_OrderLines AS ol ON oh.OrderId = ol.OrderId
							WHERE   (ol.TotalPrice < @ZeroPrice) AND    (CAST(oh.OrderDate AS DATE) <= CAST(@CurDate AS DATE))
							) AS fp
				END
				SET @CurDate = DATEADD(DAY,1,@CurDate)
			END
END

GO
/****** Object:  StoredProcedure [dbo].[sp_FACT_ImportEventAggregates]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-4-7
-- Description:	daily job for event facts aggregates
-- =============================================
CREATE PROCEDURE [dbo].[sp_FACT_ImportEventAggregates]	
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @CurDate DATE

	DECLARE event_cursor CURSOR FOR
		SELECT  CAST(EventDate AS DATE) AS EventDate
		FROM    UserSessionsEventLogs
		WHERE   ( ExportToFact = 0 )
				AND ( WebStoreId IS NOT NULL OR CourseId IS NOT NULL OR BundleId IS NOT NULL)
				AND ( EventDate >= '03/30/2014' )
		GROUP BY CAST(EventDate AS DATE)
		ORDER BY CAST(EventDate AS DATE)

	OPEN event_cursor   
	FETCH NEXT FROM event_cursor INTO @CurDate   

	WHILE @@FETCH_STATUS = 0
		BEGIN   
      
			INSERT  INTO dbo.FACT_EventAgg
					( EventCount ,
					  EventTypeID ,
					  EventDate ,
					  WebStoreId ,
					  ItemId ,
					  ItemType ,
					  ItemName ,
					  AuthorId
					)
					SELECT  COUNT(DISTINCT SessionId) AS EventCount ,
							EventTypeID ,
							CAST(EventDate AS DATE) AS EventDate ,
							WebStoreId ,
							ISNULL(CourseId, BundleId) AS ItemId ,
							ItemType ,
							ISNULL(CourseName, BundleName) AS ItemName ,
							ISNULL(ISNULL(CourseAuthorId, BundleAuthorId),StoreOwnerUserID) AS AuthorId
					FROM    vw_EVENT_Logs
					WHERE   ( WebStoreId IS NOT NULL OR CourseId IS NOT NULL OR BundleId IS NOT NULL)
							AND ( CAST(EventDate AS DATE) = @CurDate )
							AND ( ExportToFact = 0 )
					GROUP BY EventTypeID ,
							CAST(EventDate AS DATE) ,
							WebStoreId ,
							ISNULL(CourseId, BundleId) ,
							ItemType ,
							ISNULL(ISNULL(CourseAuthorId, BundleAuthorId),StoreOwnerUserID) ,
							ISNULL(CourseName, BundleName)
						
			UPDATE  UserSessionsEventLogs
			SET     ExportToFact = 1
			WHERE   (WebStoreId IS NOT NULL OR CourseId IS NOT NULL OR BundleId IS NOT NULL)
					AND ( CAST(EventDate AS DATE) = @CurDate )
					AND ( ExportToFact = 0 )

				

			FETCH NEXT FROM event_cursor INTO @CurDate   
		END   

	CLOSE event_cursor   
	DEALLOCATE event_cursor

END


GO
/****** Object:  StoredProcedure [dbo].[sp_PO_GetMonthlyPayoutReport]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-10-28
-- Description:	Get Summary report data
-- =============================================
CREATE PROCEDURE [dbo].[sp_PO_GetMonthlyPayoutReport]
    (
      @Year INT ,
      @Month INT ,
	  @LfeCommission INT,
      @UserId INT			= NULL,
	  @CurrencyId SMALLINT = NULL
    )
AS
    BEGIN
        
		SET NOCOUNT ON;
			
			DECLARE @PrevYear INT ,
					@PrevMonth INT ,
					@PrevMontDate DATE	 

			SELECT  @PrevMontDate = DATEADD(MONTH, -1, DATEFROMPARTS(@YEAR, @MONTH, 1))

			SELECT  @PrevYear = DATEPART(YEAR, @PrevMontDate)

			SELECT  @PrevMonth = DATEPART(MONTH, @PrevMontDate) 
     
			SELECT  u.UserId ,
					usr.Nickname ,
					usr.FirstName ,
					usr.LastName ,
					usr.Email ,
					usr.PayoutTypeId ,
					usr.PaypalEmail ,
					usr.PayoutAddressID ,
					adr.CountryId ,
					cntr.CountryName ,
					adr.StateId ,
					st.StateName ,
					adr.FirstName AS PayoutFirstName ,
					adr.LastName AS PayoutLastName ,
					adr.CityName ,
					adr.Street1 ,
					adr.Street2 ,
					adr.PostalCode ,
					adr.Region ,
					c.CurrencyId ,
					c.CurrencyName ,
					c.Symbol ,
					c.ISO ,					
					u.TotalSales ,
					u.AuthorSales,
					u.AffiliateTotalSales ,
					u.AffiliateFees,
					u.AffiliateCommission ,
					u.TotalFees ,
					u.RefundProgramHold ,
					u.RefundProgramReleased ,					
					u.TotalRefunded ,
					u.TotalRefundedFees ,
					u.Balance ,
					u.LfeCommissions ,
					u.Payout ,
					u.Author_total_sales ,
					u.Author_total_rgp_sales ,
					u.Author_total_non_rgp_sales ,
					u.Author_total_fees ,
					u.Author_total_rgp_fee ,
					u.Author_total_non_rgp_fee ,
					u.By_Affiliate_total_sales ,
					u.By_Affiliate_total_rgp_sales ,
					u.By_Affiliate_total_non_rgp_sales ,
					u.By_Affiliate_total_fees ,
					u.By_Affiliate_total_rgp_fee ,
					u.By_Affiliate_total_non_rgp_fee ,
					u.By_Affiliate_total_net_rgp_sales ,
					u.By_Affiliate_total_net_non_rgp_sales ,
					u.By_Affiliate_total_net_fees ,
					u.By_Affiliate_total_net_rgp_fee ,
					u.By_Affiliate_total_net_non_rgp_fee ,
					u.Affiliate_total_sales ,
					u.Affiliate_total_rgp_sales ,
					u.Affiliate_total_non_rgp_sales ,
					u.Affiliate_total_commission ,
					u.Affiliate_total_rgp_commission ,
					u.Affiliate_total_non_rgp_commission ,
					u.Affiliate_total_fees ,
					u.Affiliate_total_rgp_fee ,
					u.Affiliate_total_non_rgp_fee ,
					u.Affiliate_total_net_fees ,
					u.Affiliate_total_net_rgp_fee ,
					u.Affiliate_total_net_non_rgp_fee ,
					u.Author_Released_total_rgp_sales ,
					u.Author_Released_total_rgp_fee ,
					u.Affiliate_Released_total_net_rgp_sales ,
					u.Affiliate_Released_total_net_rgp_fee ,
					u.By_Affiliate_Released_total_rgp_commission ,
					u.By_Affiliate_Released_total_net_rgp_fee ,
					u.Author_total_refunded ,
					u.Author_fee_refunded ,
					u.Affiliate_total_refunded ,
					u.Affiliate_fee_refunded ,
					u.Affiliate_total_net_refunded ,
					u.Affiliate_fee_net_refunded ,
					u.By_Affiliate_total_refunded ,
					u.By_Affiliate_fee_refunded ,
					u.By_Affiliate_total_net_refunded ,
					u.By_Affiliate_fee_net_refunded
			FROM    dbo.BASE_CurrencyLib AS c
					INNER JOIN dbo.tvf_PO_GetMonthlyPayoutReport(@Year, @Month,@PrevYear,@PrevMonth, @LfeCommission,@UserId, @CurrencyId) AS u
					INNER JOIN dbo.Users AS usr ON u.UserId = usr.Id ON c.CurrencyId = u.CurrencyId
					LEFT OUTER JOIN dbo.GEO_CountriesLib AS cntr
					INNER JOIN dbo.USER_Addresses AS adr ON cntr.CountryId = adr.CountryId ON usr.PayoutAddressID = adr.AddressId
					LEFT OUTER JOIN dbo.GEO_States AS st ON adr.StateId = st.StateId
			--WHERE   ( dbo.fn_USER_IsAdmin(u.UserId) = 0 )
		

    END

GO
/****** Object:  StoredProcedure [dbo].[sp_PO_SaveMonthlyPayoutStatment]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-10-30
-- Description:	Save user monthly payout statment
-- =============================================
CREATE PROCEDURE [dbo].[sp_PO_SaveMonthlyPayoutStatment]
(
	@Year INT,
	@Month INT,
	@LfeCommission INT,
	@CreatorId INT = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @PrevYear INT ,
			@PrevMonth INT ,
			@PrevMontDate DATE,
			@WaitingStatusId TINYINT 

	SELECT  @PrevMontDate = DATEADD(MONTH, -1, DATEFROMPARTS(@YEAR, @MONTH, 1))

	SELECT  @PrevYear = DATEPART(YEAR, @PrevMontDate)

	SELECT  @PrevMonth = DATEPART(MONTH, @PrevMontDate) 

	SELECT  @WaitingStatusId = StatusId
	FROM    dbo.PO_PayoutStatusesLOV
	WHERE   StatusCode = 'WAIT'

IF NOT EXISTS ( SELECT  1
                FROM    dbo.PO_PayoutExecutions AS pe
                WHERE   ( pe.PayoutYear = @Year )
                        AND ( pe.PayoutMonth = @Month ) )
    BEGIN
			
        INSERT  INTO dbo.PO_PayoutExecutions
                ( PayoutYear ,
                  PayoutMonth ,
                  StatusId ,
                  AddOn ,
                  CreatedBy
				 )
        VALUES  ( @Year ,
                  @Month ,
                  @WaitingStatusId ,
                  GETDATE() ,
                  @CreatorId
				 )

    END

	INSERT  INTO dbo.PO_UserPayoutStatments
				( ExecutionId ,
				  UserId ,
				  TotalSales,
				  AuthorSales ,
				  AffiliateSales ,
				  TotalFees ,
				  RefundProgramHold ,
				  RefundProgramReleased ,
				  AffiliateCommission ,
				  AffiliateFees,
				  TotalRefunded ,
				  TotalRefundedFees ,
				  TotalBalance ,
				  LfeCommissions ,
				  Payout ,
				  Author_total_sales ,
				  Author_total_rgp_sales ,
				  Author_total_non_rgp_sales ,
				  Author_total_fees ,
				  Author_total_rgp_fee ,
				  Author_total_non_rgp_fee ,
				  By_Affiliate_total_sales ,
				  By_Affiliate_total_rgp_sales ,
				  By_Affiliate_total_non_rgp_sales ,
				  By_Affiliate_total_fees ,
				  By_Affiliate_total_rgp_fee ,
				  By_Affiliate_total_non_rgp_fee ,
				  By_Affiliate_total_net_rgp_sales ,
				  By_Affiliate_total_net_non_rgp_sales ,
				  By_Affiliate_total_net_fees ,
				  By_Affiliate_total_net_rgp_fee ,
				  By_Affiliate_total_net_non_rgp_fee ,
				  Affiliate_total_sales ,
				  Affiliate_total_rgp_sales ,
				  Affiliate_total_non_rgp_sales ,
				  Affiliate_total_commission ,
				  Affiliate_total_rgp_commission ,
				  Affiliate_total_non_rgp_commission ,
				  Affiliate_total_fees ,
				  Affiliate_total_rgp_fee ,
				  Affiliate_total_non_rgp_fee ,
				  Affiliate_total_net_fees ,
				  Affiliate_total_net_rgp_fee ,
				  Affiliate_total_net_non_rgp_fee ,
				  Author_Released_total_rgp_sales ,
				  Author_Released_total_rgp_fee ,
				  Affiliate_Released_total_net_rgp_sales ,
				  Affiliate_Released_total_net_rgp_fee ,
				  By_Affiliate_Released_total_rgp_commission ,
				  By_Affiliate_Released_total_net_rgp_fee ,
				  Author_total_refunded ,
				  Author_fee_refunded ,
				  Affiliate_total_refunded ,
				  Affiliate_fee_refunded ,
				  Affiliate_total_net_refunded ,
				  Affiliate_fee_net_refunded ,
				  By_Affiliate_total_refunded ,
				  By_Affiliate_fee_refunded ,
				  By_Affiliate_total_net_refunded ,
				  By_Affiliate_fee_net_refunded ,
				  PayoutTypeId ,
				  PaypalEmail ,
				  PayoutAddressID ,
				  CurrencyId ,
				  StatusId ,
				  AddOn ,
				  CreatedBy
				)
				SELECT  pe.ExecutionId ,
						po.UserId ,	
						TotalSales,
						AuthorSales ,
						AffiliateTotalSales ,
						TotalFees ,
						RefundProgramHold ,
						RefundProgramReleased ,
						po.AffiliateCommission ,
						AffiliateFees,
						TotalRefunded ,
						TotalRefundedFees ,
						Balance ,
						LfeCommissions ,
						Payout ,						
						po.Author_total_sales ,
						po.Author_total_rgp_sales ,
						po.Author_total_non_rgp_sales ,
						po.Author_total_fees ,
						po.Author_total_rgp_fee ,
						po.Author_total_non_rgp_fee ,
						po.By_Affiliate_total_sales ,
						po.By_Affiliate_total_rgp_sales ,
						po.By_Affiliate_total_non_rgp_sales ,
						po.By_Affiliate_total_fees ,
						po.By_Affiliate_total_rgp_fee ,
						po.By_Affiliate_total_non_rgp_fee ,
						po.By_Affiliate_total_net_rgp_sales ,
						po.By_Affiliate_total_net_non_rgp_sales ,
						po.By_Affiliate_total_net_fees ,
						po.By_Affiliate_total_net_rgp_fee ,
						po.By_Affiliate_total_net_non_rgp_fee ,
						po.Affiliate_total_sales ,
						po.Affiliate_total_rgp_sales ,
						po.Affiliate_total_non_rgp_sales ,
						po.Affiliate_total_commission ,
						po.Affiliate_total_rgp_commission ,
						po.Affiliate_total_non_rgp_commission ,
						po.Affiliate_total_fees ,
						po.Affiliate_total_rgp_fee ,
						po.Affiliate_total_non_rgp_fee ,
						po.Affiliate_total_net_fees ,
						po.Affiliate_total_net_rgp_fee ,
						po.Affiliate_total_net_non_rgp_fee ,
						po.Author_Released_total_rgp_sales ,
						po.Author_Released_total_rgp_fee ,
						po.Affiliate_Released_total_net_rgp_sales ,
						po.Affiliate_Released_total_net_rgp_fee ,
						po.By_Affiliate_Released_total_rgp_commission ,
						po.By_Affiliate_Released_total_net_rgp_fee ,
						po.Author_total_refunded ,
						po.Author_fee_refunded ,
						po.Affiliate_total_refunded ,
						po.Affiliate_fee_refunded ,
						po.Affiliate_total_net_refunded ,
						po.Affiliate_fee_net_refunded ,
						po.By_Affiliate_total_refunded ,
						po.By_Affiliate_fee_refunded ,
						po.By_Affiliate_total_net_refunded ,
						po.By_Affiliate_fee_net_refunded ,						
						u.PayoutTypeId ,
						u.PaypalEmail,
						u.PayoutAddressID ,						
						po.CurrencyId,
						@WaitingStatusId ,
						GETDATE() ,
						@CreatorId

				FROM    dbo.tvf_PO_GetMonthlyPayoutReport(@Year, @Month, @PrevYear,
														  @PrevMonth, @LfeCommission,
														  NULL, NULL) AS po
						INNER JOIN dbo.Users AS u ON po.UserId = u.Id
						CROSS JOIN dbo.PO_PayoutExecutions AS pe
				WHERE   ( pe.PayoutYear = @Year )
						AND (pe.PayoutMonth = @Month )
						AND (po.Payout > 0)
						AND ( NOT EXISTS ( SELECT   1 
										   FROM     dbo.PO_UserPayoutStatments AS ps
										   WHERE    ( UserId = po.UserId )
													AND ( ExecutionId = pe.ExecutionId ) )
							)


			UPDATE dbo.PO_UserPayoutStatments
			SET StatusId = @WaitingStatusId
			WHERE ExecutionId = (SELECT ExecutionId
								 FROM dbo.PO_PayoutExecutions AS pe
								 	WHERE   ( pe.PayoutYear = @Year )
								  AND (pe.PayoutMonth = @Month ))
			AND StatusId NOT IN (	SELECT  StatusId
									FROM    dbo.PO_PayoutStatusesLOV
									WHERE   StatusCode IN( 'COMPLETED','PARTIALLY'))

END

GO
/****** Object:  StoredProcedure [dbo].[sp_USER_GetVideosState]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2015-5-30
-- Description:	Get unused videos report
-- =============================================
CREATE PROCEDURE [dbo].[sp_USER_GetVideosState]
	-- Add the parameters for the stored procedure here
    @OldMont INT ,
    @ExcludeSales BIT = 0
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

        DECLARE @CheckDate DATE

        SELECT  @CheckDate = DATEADD(MONTH, -@OldMont, GETDATE())

    -- Insert statements for procedure here
        SELECT  CAST(v.BcIdentifier AS VARCHAR(30)) AS BcIdentifier ,
                v.UserId ,
                u.FirstName ,
                u.LastName ,
                u.Email ,
                v.Attached2Chapter AS Attached ,
                s.OrderDate,
				u.LastActivityDate
        FROM    dbo.USER_Videos AS v
                INNER JOIN dbo.vw_USER_LastActivityDates AS u ON v.UserId = u.UserID
                LEFT OUTER JOIN dbo.vw_USER_LastSaleDates AS s ON v.UserId = s.SellerUserId
        WHERE   ( u.LastActivityDate < @CheckDate )
                AND ( @ExcludeSales = 0 OR s.OrderDate IS NULL)
				AND (v.UserId NOT IN (2225, -- Monicas Jones
									  1655, -- Jeff Minder
									  1594, -- Nathan Schoemer
									  1585, -- Esther Coronel
									  306 -- Lyle
									  ))
        ORDER BY u.LastActivityDate DESC,v.UserId DESC
    END

GO
/****** Object:  StoredProcedure [dbo].[sp_USER_UpdateNotificationStatus]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2013-8-11
-- Description:	Update user notifications status
-- =============================================
CREATE PROCEDURE [dbo].[sp_USER_UpdateNotificationStatus]
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON;


		UPDATE [dbo].[UserNotifications]
		   SET [IsRead] = 1
			  ,[ReadOn] = GETDATE()
		 WHERE (UserId=@UserId)
				AND (IsRead=0)
    
END

GO
/****** Object:  StoredProcedure [dbo].[sp_webpages_AddUserRole]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-10-6
-- Description:	Add role to user
-- =============================================
CREATE PROCEDURE [dbo].[sp_webpages_AddUserRole]
(
	@UserId INT,
	@RoleId INT
)		
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(SELECT 1
					FROM dbo.webpages_UsersInRoles
					WHERE (RoleId = @RoleId) 
							AND (UserId = @UserId))
		BEGIN
			INSERT INTO [dbo].[webpages_UsersInRoles]
						([UserId]
						,[RoleId])
					VALUES
						(@UserId
						,@RoleId)
		END
END

GO
/****** Object:  StoredProcedure [dbo].[sp_webpages_RemoveUserRole]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-10-18
-- Description:	Remove role to user
-- =============================================
CREATE PROCEDURE [dbo].[sp_webpages_RemoveUserRole]
(
	@UserId INT,
	@RoleId INT
)		
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1
					FROM dbo.webpages_UsersInRoles
					WHERE (RoleId = @RoleId) 
							AND (UserId = @UserId))
		BEGIN
			DELETE FROM [dbo].[webpages_UsersInRoles]
			WHERE (RoleId = @RoleId) AND (UserId = @UserId)
		END
END


GO
/****** Object:  StoredProcedure [dbo].[sp_webpages_UpdateUserRoles]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Serge Bruno
-- Create date: 2014-10-6
-- Description:	Update User roles
-- =============================================
CREATE PROCEDURE [dbo].[sp_webpages_UpdateUserRoles]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @LearnerRoleId INT,
			@AuthorRoleId INT,
			@AffiliateRoleId INT,
			@StoreOwnerRoleId INT,
			@GuestRoleId INT,
			@CurrentUserId INT,
			@CurrentRefUserId INT,
			@Total INT,
			@ItemsTotal INT

			-- Declare static Role Id's
			SELECT  @LearnerRoleId = RoleId
			FROM    dbo.webpages_Roles
			WHERE  RoleName = 'Learner'

			SELECT  @AuthorRoleId = RoleId
			FROM    dbo.webpages_Roles
			WHERE  RoleName = 'Author'

			SELECT  @AffiliateRoleId = RoleId
			FROM    dbo.webpages_Roles
			WHERE  RoleName = 'Affiliate'

			SELECT  @StoreOwnerRoleId = RoleId
			FROM    dbo.webpages_Roles
			WHERE  RoleName = 'StoreOwner'

			SELECT  @GuestRoleId = RoleId
			FROM    dbo.webpages_Roles
			WHERE  RoleName = 'Guest'

	--delete role records
	  DELETE FROM [dbo].[webpages_UsersInRoles]
      WHERE RoleId IN (@AuthorRoleId,@LearnerRoleId,@GuestRoleId,@AffiliateRoleId,@StoreOwnerRoleId)

	--Declare cursor for all users
	DECLARE user_cursor CURSOR FOR
			SELECT  UserId,RefUserId
			FROM    dbo.UserProfile
				
    -- Open user cursor
	OPEN user_cursor   
	FETCH NEXT FROM user_cursor INTO @CurrentUserId,@CurrentRefUserId  

	WHILE @@FETCH_STATUS = 0
		BEGIN
			
			DECLARE @RoleFound BIT = 0

			-- check learner start
			SELECT   @Total = COUNT(1) 
			FROM    dbo.USER_Courses AS uc 
						INNER JOIN dbo.Courses AS c ON uc.CourseId = c.Id
			WHERE   (uc.UserId = @CurrentRefUserId)
					AND (c.AuthorUserId <> @CurrentRefUserId)

			IF(@Total > 0)
				BEGIN
					EXEC dbo.sp_webpages_AddUserRole @CurrentUserId,@LearnerRoleId
					EXEC dbo.sp_webpages_RemoveUserRole @CurrentUserId,@GuestRoleId
					SET @RoleFound = 1
				END
			-- check learner end

			------------------------------------------------------------------------

			-- check author start
		   SELECT    @ItemsTotal = ISNULL(b.bundles, 0) + ISNULL(c.courses,0)
           FROM      dbo.Users AS u
                    LEFT OUTER JOIN ( SELECT    COUNT(BundleId) AS bundles ,
                                                AuthorId
                                      FROM      dbo.CRS_Bundles
                                      GROUP BY  AuthorId
                                    ) AS b ON b.AuthorId = u.Id
                    LEFT OUTER JOIN ( SELECT    COUNT(Id) AS courses ,
                                                AuthorUserId
                                      FROM      dbo.Courses
                                      GROUP BY  AuthorUserId
                                    ) AS c ON c.AuthorUserId = u.Id
			WHERE (u.Id = @CurrentRefUserId)

			IF(@ItemsTotal > 0)
				BEGIN
					EXEC dbo.sp_webpages_AddUserRole @CurrentUserId,@AuthorRoleId
					EXEC dbo.sp_webpages_RemoveUserRole @CurrentUserId,@GuestRoleId
					SET @RoleFound = 1
				END
			-- check author end

			--------------------------------------------------------------------------

			--check affiliate start
		    SELECT    @Total = ISNULL(s.items, 0)
            FROM      dbo.Users AS u                    
                    LEFT OUTER JOIN ( SELECT COUNT(wi.ItemId) AS items,
												wi.OwnerUserID
										FROM  dbo.vw_WS_Items AS wi
										WHERE (wi.AuthorID <> wi.OwnerUserID)
										GROUP BY wi.OwnerUserID
                                    ) AS s ON s.OwnerUserID = u.Id
			WHERE (u.Id = @CurrentRefUserId)

			-- user has store with other user items => affiliate
			IF(@Total > 0)
				BEGIN
					EXEC dbo.sp_webpages_AddUserRole @CurrentUserId,@AffiliateRoleId
					EXEC dbo.sp_webpages_RemoveUserRole @CurrentUserId,@GuestRoleId
					SET @RoleFound = 1
				END

			--check affiliate end

			--------------------------------------------------------------------------	
			
			--check store owner start
			DECLARE  @StoreItemsTotal INT,@StoresTotal INT
			SELECT  @StoresTotal = SUM(CASE WHEN s.StoreID IS NULL THEN 0 ELSE 1 END) , 
					@StoreItemsTotal =SUM(CASE WHEN i.ItemId IS NULL THEN 0 ELSE 1 END) 
			FROM    dbo.Users AS u
					LEFT OUTER JOIN dbo.WebStores AS s ON u.Id = s.OwnerUserID
					LEFT OUTER JOIN dbo.vw_WS_Items AS i ON  u.Id = i.OwnerUserID
			WHERE (u.Id = @CurrentRefUserId)

			--if user have only store without items and he is not author => set as store owner
			IF(@StoresTotal > 0 AND @StoreItemsTotal = 0 AND @ItemsTotal = 0)
				BEGIN
					EXEC dbo.sp_webpages_AddUserRole @CurrentUserId,@StoreOwnerRoleId
					EXEC dbo.sp_webpages_RemoveUserRole @CurrentUserId,@GuestRoleId
					SET @RoleFound = 1
				END

			--check store owner end

			--------------------------------------------------------------------------			

			-- If no items found => remove Author role
			IF(@ItemsTotal = 0) 
				BEGIN
					EXEC dbo.sp_webpages_AddUserRole @CurrentUserId,@AuthorRoleId
				END

			-- If no "active" role found => set as Guest
			IF(@RoleFound = 0) 
				BEGIN
					EXEC dbo.sp_webpages_AddUserRole @CurrentUserId,@GuestRoleId
				END

			FETCH NEXT FROM user_cursor INTO @CurrentUserId,@CurrentRefUserId
		END

	CLOSE user_cursor   
	DEALLOCATE user_cursor
END

GO
/****** Object:  StoredProcedure [dbo].[spWidget_GetAllCourses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Idan Tam
-- Create date: 13/10/2013
-- Description:	Get All LFE courses
--string trackingID, 
--	int categoryID, int pageID, string sort
-- =============================================

--exec spWidget_GetCourses null,1,'id123','ordinal','',30
CREATE PROCEDURE [dbo].[spWidget_GetAllCourses]
	@currencyId SMALLINT = 2, --USD
	@pageID int = null ,
    @Sort varchar(50) = 'ordinal',
    @SortDirection varchar(50) = 'desc', 
	@pagesize int = 12,
	@userID int = null
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @TotalRows INT
DECLARE @TotalPages INT

IF (@pageID is null or @pageID < 1 )
      SET @pageID= 1;

 IF (@SortDirection is null or @SortDirection = '' ) 
 begin
	SELECT 
   @SortDirection = CASE @Sort
                         WHEN 'ordinal' THEN 'asc'
                         WHEN 'date' THEN 'desc'
						 WHEN 'date' THEN 'desc'
						 WHEN 'rating' THEN 'desc'
						 WHEN 'popularity' THEN 'desc'
						 WHEN 'cost' THEN 'asc'
                     END
	end 

	select  ItemName ,
			ItemTypeId ,		
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
			dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created ,
			CoursesCnt,
			1 AS Ordinal,
		   ROW_NUMBER() OVER (order by 
				 case when @Sort = 'ordinal' and @SortDirection = 'asc' 
 						then ItemName end asc,
				 case when @Sort = 'ordinal' and @SortDirection = 'desc' 
 						then ItemName end desc,
				 case when @Sort = 'date' and @SortDirection = 'asc' 
 						then Created end asc,
				 case when @Sort = 'date' and @SortDirection = 'desc' 
 						then Created end desc,
				 case when @Sort = 'rating' and @SortDirection = 'asc' 
 						then rating end asc,
				 case when @Sort = 'rating' and @SortDirection = 'desc' 
 						then rating end desc,
				 case when @Sort = 'popularity' and @SortDirection = 'asc' 
 						then NumSubscribers end asc,
				 case when @Sort = 'popularity' and @SortDirection = 'desc' 
 						then NumSubscribers end desc,
				 case when @Sort = 'cost' and @SortDirection = 'asc' 
 						then dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,1,NULL) end asc,
				 case when @Sort = 'cost' and @SortDirection = 'desc' 
 						then dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,1,NULL) end desc
			  ) as ROW
			
	INTO #CoursesResults 
    FROM vw_WS_Items AS c		
	WHERE  (c.ItemStatusId = 2)
		GROUP BY  ItemName ,
			ItemTypeId ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,	
			--Price ,
			--MonthlySubscriptionPrice ,		
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created ,
			CoursesCnt
		 

SELECT @TotalRows=COUNT(*) FROM #CoursesResults
SET @TotalPages = (@TotalRows/@PageSize)+(@TotalRows%@PageSize);

 		
IF(@pageID>@TotalPages)
	  SET @pageID=@TotalPages;



     SELECT ItemName ,
			ItemTypeId ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			Price ,
			MonthlySubscriptionPrice ,
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created,
			CoursesCnt, 
			Ordinal,
		    T.ROW,
		   @TotalRows as SumCourses
FROM  #CoursesResults T
WHERE Row BETWEEN (@pageID - 1) * (@PageSize)  + 1 AND @pageID*@PageSize



END

GO
/****** Object:  StoredProcedure [dbo].[spWidget_GetCourses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Idan Tam
-- Create date: 4/8/2013
-- Description:	Get widget courses for index with sort option
--string trackingID, 
--	int categoryID, int pageID, string sort
-- =============================================

--exec spWidget_GetCourses 811,1,'id12345',null,'',30
CREATE PROCEDURE [dbo].[spWidget_GetCourses]
	@currencyId SMALLINT = 2, --USD
	@categoryID int = null,
    @pageID int = null ,
	@trackingID varchar(50),
    @Sort varchar(50) = 'ordinal',
    @SortDirection varchar(50) = 'asc', 
	@pagesize int = 12,
	@WixViewMode varchar(50) = 'site' ,
	@userID int = null
AS
BEGIN
	SET NOCOUNT ON;

	-- SELECT  ItemName ,
	--		ItemTypeId ,
	--		1 AS Ordinal ,
	--		AuthorName ,
	--		AuthorID ,
	--		ItemId ,
	--		UrlName ,
	--		ImageURL ,
	--		Price ,
	--		MonthlySubscriptionPrice ,
	--		NumSubscribers ,
	--		Rating ,
	--		CAST(1 AS BIT) AS IsFreeCourse ,
	--		Created,
	--		CAST(1 AS BIT) AS IsItemOwner,
	--		1 AS SumCourses,
	--		CoursesCnt
	--FROM    dbo.vw_WS_Items
	
DECLARE @TotalRows INT
DECLARE @TotalPages INT

--IF (SELECT object_id('TempDB..#CoursesResults')) IS NOT NULL
--BEGIN
--    DROP TABLE #CoursesResults
--END

IF (@pageID is null or @pageID < 1 )
      SET @pageID= 1;

IF (@Sort is null OR @Sort='' )
      SET @Sort= 'ordinal';


 IF (@SortDirection is null or @SortDirection = '' ) 
 begin
	SELECT 
   @SortDirection = CASE @Sort
						 WHEN 'ordinal' THEN 'asc'
                         WHEN 'date' THEN 'desc'
						 WHEN 'date' THEN 'desc'
						 WHEN 'rating' THEN 'desc'
						 WHEN 'popularity' THEN 'desc'
						 WHEN 'cost' THEN 'asc'
                     END
	end 



;WITH cte AS
(
    SELECT  ItemName ,
			ItemTypeId ,
			Ordinal ,
			CategoryOrdinal,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
			dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
			NumSubscribers ,
			Rating ,
			IsFreeCourse,
			Created,
			CoursesCnt,
			ROW_NUMBER() OVER (PARTITION BY ItemId ORDER BY ItemId DESC) AS rn
	FROM    dbo.vw_WS_Items
	WHERE   ( 
			 (@categoryID IS NOT NULL AND WebstoreCategoryID = @categoryID)
			  OR 
			  ( @categoryID IS NULL AND trackingID = @trackingID)
			)
			AND ( ItemStatusId = 2 OR @WixViewMode = 'editor')
			and (itemtypeid = 1 or 
					(itemtypeid = 2 and itemid in (select BundleId
										 from CRS_BundleCourses b1
										 left join [Courses] c1 on b1.courseID = c1.id
										 where BundleId = itemID and c1.statusid = 2   )				
				)
			) 

	GROUP BY  ItemName ,
			ItemTypeId ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created ,
			CoursesCnt,
			Ordinal,
			CategoryOrdinal

)

SELECT	    ItemName ,
			ItemTypeId ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			Price ,
			MonthlySubscriptionPrice ,
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created, 
			CoursesCnt,
			Ordinal, 
		   ROW_NUMBER() OVER (order by 
				 case when @Sort = 'ordinal' and @SortDirection = 'asc' 
 						then ItemName end asc,
				 case when @Sort = 'ordinal' and @SortDirection = 'desc' 
 						then ItemName end desc,
				 case when @Sort = 'date' and @SortDirection = 'asc' 
 						then Created end asc,
				 case when @Sort = 'date' and @SortDirection = 'desc' 
 						then Created end desc,
				 case when @Sort = 'rating' and @SortDirection = 'asc' 
 						then rating end asc,
				 case when @Sort = 'rating' and @SortDirection = 'desc' 
 						then rating end desc,
				 case when @Sort = 'popularity' and @SortDirection = 'asc' 
 						then NumSubscribers end asc,
				 case when @Sort = 'popularity' and @SortDirection = 'desc' 
 						then NumSubscribers end desc,
				 case when @Sort = 'cost' and @SortDirection = 'asc' 
 						then Price end asc,
				 case when @Sort = 'cost' and @SortDirection = 'desc' 
 						then Price end desc
						) as ROW						
INTO #CoursesResults 
FROM cte
WHERE rn = 1

		 

SELECT @TotalRows=COUNT(*) FROM #CoursesResults
SET @TotalPages = (@TotalRows/@PageSize)+(@TotalRows%@PageSize);

 		
IF(@pageID>@TotalPages)
	  SET @pageID=@TotalPages;



SELECT    ItemName ,
			ItemTypeId ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			Price ,
			MonthlySubscriptionPrice ,
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created,
			CoursesCnt,
			Ordinal,
		    ROW,
		   @TotalRows as SumCourses
FROM  #CoursesResults t
WHERE Row BETWEEN (@pageID - 1) * (@PageSize)  + 1 AND @pageID*@PageSize



END

GO
/****** Object:  StoredProcedure [dbo].[spWidget_GetStoreCourses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Idan Tam
-- Create date: 4/8/2013
-- Description:	Get widget courses for index with sort option
--string trackingID, 
--	int categoryID, int pageID, string sort
-- =============================================

--exec spWidget_GetCourses 811,1,'id12345',null,'',30
CREATE PROCEDURE [dbo].[spWidget_GetStoreCourses]
	@currencyId SMALLINT = 2, --USD
	@categoryID int = null,
    @pageID int = null ,
	@trackingID varchar(50),    
	@pagesize int = 12,
	@WixViewMode varchar(50) = 'site' ,
	@userID int = null
AS
BEGIN
	SET NOCOUNT ON;


DECLARE @TotalRows INT
DECLARE @TotalPages INT


IF (@pageID is null or @pageID < 1 )
      SET @pageID= 1;


;WITH cte AS
(
    SELECT  ItemName ,
			ItemTypeId ,
			Ordinal ,
			CategoryOrdinal,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
			dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
			NumSubscribers ,
			Rating ,
			IsFreeCourse,
			Created,
			CoursesCnt,
			ROW_NUMBER() OVER (PARTITION BY ItemId ORDER BY ItemId DESC) AS rn
	FROM    dbo.vw_WS_Items
	WHERE   ( 
			 (@categoryID IS NOT NULL AND WebstoreCategoryID = @categoryID)
			  OR 
			  ( @categoryID IS NULL AND trackingID = @trackingID)
			)
			AND ( ItemStatusId = 2 OR @WixViewMode = 'editor')
			and (itemtypeid = 1 or 
					(itemtypeid = 2 and itemid in (select BundleId
										 from CRS_BundleCourses b1
										 left join [Courses] c1 on b1.courseID = c1.id
										 where BundleId = itemID and c1.statusid = 2   )				
				)
			) 

	GROUP BY  ItemName ,
			ItemTypeId ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created ,
			CoursesCnt,
			Ordinal,
			CategoryOrdinal

)

SELECT	    ItemName ,
			ItemTypeId ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			Price ,
			MonthlySubscriptionPrice ,
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created, 
			CoursesCnt,
			Ordinal, 
		   ROW_NUMBER() OVER (order by (CategoryOrdinal),(Ordinal) ) as ROW
INTO #CoursesResults 
FROM cte
WHERE rn = 1

		 

SELECT @TotalRows=COUNT(*) FROM #CoursesResults
SET @TotalPages = (@TotalRows/@PageSize)+(@TotalRows%@PageSize);

 		
IF(@pageID>@TotalPages)
	  SET @pageID=@TotalPages;



SELECT    ItemName ,
			ItemTypeId ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			Price ,
			MonthlySubscriptionPrice ,
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created,
			CoursesCnt,
			Ordinal,
		    ROW,
		   @TotalRows as SumCourses
FROM  #CoursesResults t
WHERE Row BETWEEN (@pageID - 1) * (@PageSize)  + 1 AND @pageID*@PageSize



END

GO
/****** Object:  StoredProcedure [dbo].[spWidget_GetUserCourses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Idan Tam
-- Create date: 26/8/2013
-- Description:	Get user's course index with sort option
--
-- =============================================

--exec spWidget_GetuserCourses 306 --,1,'id123','ordinal','',30
CREATE PROCEDURE [dbo].[spWidget_GetUserCourses]
	@currencyId SMALLINT = 2, --USD
	@userID int = null,
    @pageID int = null ,	
    @Sort varchar(50) = 'ordinal',
    @SortDirection varchar(50) = 'desc', 
	@pagesize int = 12
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @TotalRows INT
DECLARE @TotalPages INT

--IF EXISTS(
--	SELECT [name] FROM tempdb.sys.tables WHERE [name] like '#CoursesResults%') 
--	BEGIN
--	 DROP TABLE #CoursesResults;
--	END;

IF (@pageID is null or @pageID < 1 )
      SET @pageID= 1;

 IF (@SortDirection is null or @SortDirection = '' ) 
 begin
	SELECT 
   @SortDirection = CASE @Sort
                         WHEN 'ordinal' THEN 'asc'
                         WHEN 'date' THEN 'desc'
						 WHEN 'date' THEN 'desc'
						 WHEN 'rating' THEN 'desc'
						 WHEN 'popularity' THEN 'desc'
						 WHEN 'cost' THEN 'asc'
                     END
	end 

	select  ItemName ,
			ItemTypeId ,
			1 AS Ordinal ,
			(c.AuthorFirstName + ' ' + c.AuthorLastName) AS AuthorName ,
			AuthorID ,
			ItemId ,
		    ItemUrlName AS UrlName ,
			ImageURL ,
			dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
			dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created ,
			CoursesCnt,
		   ROW_NUMBER() OVER (order by 
				 case when @Sort = 'ordinal' and @SortDirection = 'asc' 
 						then ItemId end asc,
				 case when @Sort = 'ordinal' and @SortDirection = 'desc' 
 						then ItemId end desc,
				 case when @Sort = 'date' and @SortDirection = 'asc' 
 						then Created end asc,
				 case when @Sort = 'date' and @SortDirection = 'desc' 
 						then Created end desc,
				 case when @Sort = 'rating' and @SortDirection = 'asc' 
 						then Rating end asc,
				 case when @Sort = 'rating' and @SortDirection = 'desc' 
 						then Rating end desc,
				 case when @Sort = 'popularity' and @SortDirection = 'asc' 
 						then NumSubscribers end asc,
				 case when @Sort = 'popularity' and @SortDirection = 'desc' 
 						then NumSubscribers end desc,
				 case when @Sort = 'cost' and @SortDirection = 'asc' 
 						then dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,1,NULL) end asc,
				 case when @Sort = 'cost' and @SortDirection = 'desc' 
 						then dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,1,NULL) end desc
				 ) as ROW
	INTO #CoursesResults 
    FROM vw_USER_Items AS c		
	WHERE ( (c.AccessStatusId = 1) OR (c.AccessStatusId IN(3,4) AND c.ValidUntil IS NOT NULL AND GETDATE() < c.ValidUntil))
		  AND (c.ItemStatusId = 2) -- published
		  AND (c.userId = @userID)
	GROUP BY ItemName ,
			ItemTypeId ,
			c.AuthorFirstName ,
			c.AuthorLastName,
			AuthorID ,
			ItemId ,
			ItemUrlName ,
			ImageURL ,			
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created,
			CoursesCnt

SELECT @TotalRows=COUNT(*) FROM #CoursesResults
SET @TotalPages = (@TotalRows/@PageSize)+(@TotalRows%@PageSize);

 		
IF(@pageID>@TotalPages)
	  SET @pageID=@TotalPages;



SELECT     ItemName ,
			ItemTypeId ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			Price ,
			MonthlySubscriptionPrice ,
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created, 
			CoursesCnt,
			Ordinal,
		   T.ROW,
		   @TotalRows as SumCourses
FROM  #CoursesResults T
WHERE Row BETWEEN (@pageID - 1) * (@PageSize)  + 1 AND @pageID*@PageSize



END

GO
/****** Object:  StoredProcedure [dbo].[spWidget_SearchCourses]    Script Date: 15/08/2017 14:29:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Idan Tam
-- Create date: 12/8/2013
-- Description:	search courses by keyword
-- =============================================

--exec spWidget_SearchCourses null,'id123',12,null,null,volume
CREATE PROCEDURE [dbo].[spWidget_SearchCourses]
	@currencyId SMALLINT = 2, --USD
    @pageID int = null ,
	@trackingID varchar(50),
   	@pagesize int = 12,
	@WixViewMode varchar(50) = 'site' ,
	@userID int = null,
	@keyword varchar(500)
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @TotalRows INT
DECLARE @TotalPages INT

IF (@pageID is null or @pageID < 1 )
      SET @pageID= 1;
	  

;WITH cte AS
(
   SELECT  ItemName ,
			ItemTypeId ,
			1 AS Ordinal ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,1,NULL) AS Price, -- 1 -> ONE_TIME
			dbo.fn_BILL_GetItemPrice(ItemId,ItemTypeId,@currencyId,2,8) AS MonthlySubscriptionPrice , -- 2 -> SUBSCRIPTION, 8 -> MONTH
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created ,
			CoursesCnt,
           ROW_NUMBER() OVER (PARTITION BY ItemId ORDER BY ItemId DESC) AS rn,
		   KEY_TBL.RANK

    FROM vw_WS_Items AS c
		INNER JOIN
		FREETEXTTABLE(WebStoreItems, ItemName, @keyword ) AS KEY_TBL
			   ON c.WebstoreItemId = KEY_TBL.[KEY]
	WHERE (c.ItemStatusId = 2 or @WixViewMode = 'editor' ) 
		   and ( c.ItemName like '%' + @keyword + '%' )
	GROUP BY  ItemName ,
			ItemTypeId ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,		
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created,
			CoursesCnt,
			RANK 	
)


SELECT	  ItemName ,
			ItemTypeId ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			Price ,
			MonthlySubscriptionPrice ,
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created, 
			CoursesCnt,
			Ordinal,  
		   ROW_NUMBER() OVER (order by RANK ) as ROW
INTO #CoursesResults 
FROM cte
WHERE rn = 1

		 

SELECT @TotalRows=COUNT(*) FROM #CoursesResults
SET @TotalPages = (@TotalRows/@PageSize)+(@TotalRows%@PageSize);

 		
IF(@pageID>@TotalPages)
	  SET @pageID=@TotalPages;



SELECT    ItemName ,
			ItemTypeId ,
			AuthorName ,
			AuthorID ,
			ItemId ,
			UrlName ,
			ImageURL ,
			Price ,
			MonthlySubscriptionPrice ,
			NumSubscribers ,
			Rating ,
			IsFreeCourse ,
			Created,
			CoursesCnt, 
			Ordinal,
		   T.ROW,
		   @TotalRows as SumCourses
FROM  #CoursesResults T
WHERE Row BETWEEN (@pageID - 1) * (@PageSize)  + 1 AND @pageID*@PageSize



END

GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[30] 2[11] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "sc"
            Begin Extent = 
               Top = 96
               Left = 845
               Bottom = 431
               Right = 1039
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "cert"
            Begin Extent = 
               Top = 118
               Left = 638
               Bottom = 421
               Right = 808
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "su"
            Begin Extent = 
               Top = 121
               Left = 1254
               Bottom = 379
               Right = 1535
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "crs"
            Begin Extent = 
               Top = 106
               Left = 316
               Bottom = 445
               Right = 531
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 288
               Left = 1076
               Bottom = 417
               Right = 1246
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "au"
            Begin Extent = 
               Top = 200
               Left = 0
               Bottom = 329
               Right = 281
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 20
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
 ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_CERT_StudentCertificates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'        Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 2430
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_CERT_StudentCertificates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_CERT_StudentCertificates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "CRS_BundleCourses"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 211
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 2175
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_CRS_BundleCoursesCnt'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_CRS_BundleCoursesCnt'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "USER_Bundles"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 219
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_CRS_BundleSubscriberCnt'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_CRS_BundleSubscriberCnt'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "UserCourseReviews"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 224
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_CRS_ReviewCnt'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_CRS_ReviewCnt'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[12] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "USER_Courses"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 300
               Right = 224
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "SALE_UserAccessStatusesLOV"
            Begin Extent = 
               Top = 197
               Left = 367
               Bottom = 309
               Right = 553
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_CRS_SubscriberCnt'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_CRS_SubscriberCnt'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "m"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 134
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 6
               Left = 246
               Bottom = 135
               Right = 416
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_DSC_MessageHashtags'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_DSC_MessageHashtags'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[50] 4[17] 2[18] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "t"
            Begin Extent = 
               Top = 29
               Left = 1011
               Bottom = 141
               Right = 1181
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ev"
            Begin Extent = 
               Top = 162
               Left = 685
               Bottom = 490
               Right = 885
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "u"
            Begin Extent = 
               Top = 35
               Left = 37
               Bottom = 216
               Right = 318
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 0
               Left = 403
               Bottom = 129
               Right = 603
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "b"
            Begin Extent = 
               Top = 298
               Left = 138
               Bottom = 427
               Right = 364
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ws"
            Begin Extent = 
               Top = 150
               Left = 1238
               Bottom = 594
               Right = 1436
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 358
               Left = 929
               Bottom = 607
               Right = 1177
            End
            DisplayFlags = 280
            TopColumn = 0
     ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_EVENT_Logs'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'    End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 18
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 1710
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_EVENT_Logs'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_EVENT_Logs'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1665
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_FACT_DASH_Authors'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_FACT_DASH_Authors'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[11] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "u"
            Begin Extent = 
               Top = 29
               Left = 226
               Bottom = 373
               Right = 435
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 28
               Left = 654
               Bottom = 303
               Right = 824
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 2130
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1965
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_FACT_DASH_UserLogins'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_FACT_DASH_UserLogins'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[33] 2[10] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ws"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 231
               Right = 236
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "u"
            Begin Extent = 
               Top = 235
               Left = 779
               Bottom = 434
               Right = 964
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "f"
            Begin Extent = 
               Top = 154
               Left = 383
               Bottom = 362
               Right = 553
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 73
               Left = 665
               Bottom = 185
               Right = 835
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 15
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
    ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_FACT_EventAggregates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'     GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_FACT_EventAggregates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_FACT_EventAggregates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "e"
            Begin Extent = 
               Top = 125
               Left = 261
               Bottom = 439
               Right = 461
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "et"
            Begin Extent = 
               Top = 141
               Left = 38
               Bottom = 270
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 112
               Left = 526
               Bottom = 241
               Right = 726
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 4155
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 10395
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_FACT_WidgetHostEvents'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_FACT_WidgetHostEvents'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[16] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 391
               Right = 260
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 2088
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 3744
         Alias = 2292
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_PO_MonthlyAffiliateRefunds'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_PO_MonthlyAffiliateRefunds'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[27] 4[40] 2[15] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 310
               Right = 260
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 17
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 7590
         Alias = 2370
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_PO_MonthlyAffiliateSales'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_PO_MonthlyAffiliateSales'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[14] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 596
               Right = 260
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 3372
         Alias = 1368
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_PO_MonthlyAuthorRefunds'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_PO_MonthlyAuthorRefunds'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[22] 4[33] 2[14] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 260
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 11
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 4875
         Alias = 1770
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_PO_MonthlyAuthorSales'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_PO_MonthlyAuthorSales'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 260
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 3900
         Alias = 1572
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_PO_MonthlyRefundsByAffiliates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_PO_MonthlyRefundsByAffiliates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[29] 4[32] 2[16] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 260
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 18
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 7590
         Alias = 2100
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_PO_MonthlySalesByAffiliates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_PO_MonthlySalesByAffiliates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[54] 4[17] 2[12] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "q"
            Begin Extent = 
               Top = 35
               Left = 362
               Bottom = 470
               Right = 565
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "crs"
            Begin Extent = 
               Top = 347
               Left = 1138
               Bottom = 608
               Right = 1353
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "u"
            Begin Extent = 
               Top = 417
               Left = 1538
               Bottom = 729
               Right = 1745
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 36
               Left = 46
               Bottom = 131
               Right = 216
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 195
               Left = 61
               Bottom = 290
               Right = 231
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 369
               Left = 76
               Bottom = 464
               Right = 246
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "qs"
            Begin Extent = 
               Top = 343
               Left = 691
               Bottom = 438
               Right = 861
            End
            DisplayFlags = 280
            TopColumn = 0
     ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_QZ_CourseQuizzes'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'    End
         Begin Table = "r"
            Begin Extent = 
               Top = 497
               Left = 640
               Bottom = 592
               Right = 810
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 17
               Left = 930
               Bottom = 112
               Right = 1100
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "f"
            Begin Extent = 
               Top = 150
               Left = 913
               Bottom = 245
               Right = 1083
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 29
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 2760
         Alias = 1515
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_QZ_CourseQuizzes'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_QZ_CourseQuizzes'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "q"
            Begin Extent = 
               Top = 44
               Left = 398
               Bottom = 350
               Right = 584
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ans"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 118
               Right = 224
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "qz"
            Begin Extent = 
               Top = 122
               Left = 713
               Bottom = 251
               Right = 916
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 14
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 3540
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_QZ_QuizQuestionsLib'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_QZ_QuizQuestionsLib'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "qz"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 241
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "qq"
            Begin Extent = 
               Top = 6
               Left = 279
               Bottom = 101
               Right = 449
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_QZ_QuizValidationStatus'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_QZ_QuizValidationStatus'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[61] 4[9] 2[10] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1[50] 4[36] 3) )"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 1
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "c"
            Begin Extent = 
               Top = 645
               Left = 377
               Bottom = 841
               Right = 547
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pl"
            Begin Extent = 
               Top = 625
               Left = 697
               Bottom = 830
               Right = 887
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "r"
            Begin Extent = 
               Top = 350
               Left = 429
               Bottom = 566
               Right = 599
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 41
               Left = 217
               Bottom = 321
               Right = 399
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 179
               Left = 1
               Bottom = 309
               Right = 171
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "l"
            Begin Extent = 
               Top = 205
               Left = 957
               Bottom = 684
               Right = 1143
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 259
               Left = 1223
               Bottom = 371
               Right = 1393
            End
            DisplayFlags = 280
            TopColumn = 0
        ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLinePaymentRefunds'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N' End
         Begin Table = "pt"
            Begin Extent = 
               Top = 26
               Left = 0
               Bottom = 138
               Right = 170
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "so"
            Begin Extent = 
               Top = 13
               Left = 1225
               Bottom = 244
               Right = 1431
            End
            DisplayFlags = 280
            TopColumn = 18
         End
         Begin Table = "rt"
            Begin Extent = 
               Top = 384
               Left = 72
               Bottom = 496
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "trx"
            Begin Extent = 
               Top = 288
               Left = 643
               Bottom = 574
               Right = 846
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "cp"
            Begin Extent = 
               Top = 406
               Left = 1544
               Bottom = 738
               Right = 1746
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ci"
            Begin Extent = 
               Top = 421
               Left = 1232
               Bottom = 672
               Right = 1432
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sown"
            Begin Extent = 
               Top = 66
               Left = 1548
               Bottom = 256
               Right = 1829
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
      PaneHidden = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 19
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1980
         Alias = 1845
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLinePaymentRefunds'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLinePaymentRefunds'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[54] 4[17] 2[10] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1[64] 4[28] 3) )"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = -96
         Left = 0
      End
      Begin Tables = 
         Begin Table = "p"
            Begin Extent = 
               Top = 40
               Left = 258
               Bottom = 320
               Right = 440
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 193
               Left = 25
               Bottom = 323
               Right = 195
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "l"
            Begin Extent = 
               Top = 193
               Left = 900
               Bottom = 655
               Right = 1086
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 291
               Left = 1232
               Bottom = 403
               Right = 1430
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pt"
            Begin Extent = 
               Top = 74
               Left = 27
               Bottom = 186
               Right = 197
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "so"
            Begin Extent = 
               Top = 5
               Left = 1232
               Bottom = 272
               Right = 1438
            End
            DisplayFlags = 280
            TopColumn = 16
         End
         Begin Table = "sou"
            Begin Extent = 
               Top = 10
               Left = 1542
               Bottom = 286
               Right = 1722
            End
            DisplayFlags = 280
            TopColumn = 0
 ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLinePayments'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'        End
         Begin Table = "cp"
            Begin Extent = 
               Top = 406
               Left = 1544
               Bottom = 738
               Right = 1746
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ci"
            Begin Extent = 
               Top = 421
               Left = 1232
               Bottom = 672
               Right = 1432
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pl"
            Begin Extent = 
               Top = 554
               Left = 534
               Bottom = 741
               Right = 724
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 496
               Left = 109
               Bottom = 726
               Right = 279
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "r"
            Begin Extent = 
               Top = 40
               Left = 658
               Bottom = 135
               Right = 840
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "trx"
            Begin Extent = 
               Top = 236
               Left = 521
               Bottom = 522
               Right = 724
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 59
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 3240
         Alias = 1950
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLinePayments'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLinePayments'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r"
            Begin Extent = 
               Top = 98
               Left = 214
               Bottom = 275
               Right = 400
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 1605
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLinePaymentsTotalRefunds'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLinePaymentsTotalRefunds'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[55] 4[16] 2[15] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1[64] 4[12] 3) )"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "pl"
            Begin Extent = 
               Top = 522
               Left = 270
               Bottom = 666
               Right = 460
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "cur"
            Begin Extent = 
               Top = 530
               Left = 547
               Bottom = 659
               Right = 717
            End
            DisplayFlags = 280
            TopColumn = 2
         End
         Begin Table = "oh"
            Begin Extent = 
               Top = 39
               Left = 1007
               Bottom = 318
               Right = 1195
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sol"
            Begin Extent = 
               Top = 107
               Left = 515
               Bottom = 512
               Right = 711
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "lt"
            Begin Extent = 
               Top = 83
               Left = 49
               Bottom = 195
               Right = 219
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "os"
            Begin Extent = 
               Top = 276
               Left = 1399
               Bottom = 388
               Right = 1569
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "su"
            Begin Extent = 
               Top = 363
               Left = 38
               Bottom = 595
               Right = 229
            End
            DisplayFlags = 280
            TopColumn = 0' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLines'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'
         End
         Begin Table = "pt"
            Begin Extent = 
               Top = 226
               Left = 47
               Bottom = 338
               Right = 243
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "usrbuy"
            Begin Extent = 
               Top = 6
               Left = 1369
               Bottom = 201
               Right = 1650
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pm"
            Begin Extent = 
               Top = 443
               Left = 1396
               Bottom = 571
               Right = 1606
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ws"
            Begin Extent = 
               Top = 208
               Left = 1613
               Bottom = 471
               Right = 1811
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 5
               Left = 765
               Bottom = 117
               Right = 935
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pi"
            Begin Extent = 
               Top = 178
               Left = 720
               Bottom = 300
               Right = 936
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "r"
            Begin Extent = 
               Top = 0
               Left = 216
               Bottom = 95
               Right = 386
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 379
               Left = 1125
               Bottom = 650
               Right = 1327
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ci"
            Begin Extent = 
               Top = 329
               Left = 809
               Bottom = 536
               Right = 981
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ct"
            Begin Extent = 
               Top = 541
               Left = 811
               Bottom = 671
               Right = 1001
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "usown"
            Begin Extent = 
               Top = 497
               Left = 1682
               Bottom = 646
               Right = 1861
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 59
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLines'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane3', @value=N'   Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 3120
         Alias = 2340
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLines'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=3 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLines'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "l"
            Begin Extent = 
               Top = 30
               Left = 480
               Bottom = 441
               Right = 666
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "SALE_OrderLinePayments"
            Begin Extent = 
               Top = 17
               Left = 785
               Bottom = 146
               Right = 981
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "r"
            Begin Extent = 
               Top = 30
               Left = 1127
               Bottom = 202
               Right = 1313
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 1560
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1140
         Or = 1905
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLinesTotalRefunds'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLinesTotalRefunds'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[10] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "p"
            Begin Extent = 
               Top = 28
               Left = 483
               Bottom = 310
               Right = 663
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 163
               Left = 962
               Bottom = 275
               Right = 1132
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "o"
            Begin Extent = 
               Top = 127
               Left = 108
               Bottom = 422
               Right = 294
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 1410
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLineTotalPayments'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderLineTotalPayments'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[53] 4[19] 2[13] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "oh"
            Begin Extent = 
               Top = 77
               Left = 862
               Bottom = 401
               Right = 1050
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ub"
            Begin Extent = 
               Top = 23
               Left = 42
               Bottom = 279
               Right = 194
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "us"
            Begin Extent = 
               Top = 92
               Left = 1249
               Bottom = 284
               Right = 1530
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "st"
            Begin Extent = 
               Top = 412
               Left = 1127
               Bottom = 524
               Right = 1297
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pm"
            Begin Extent = 
               Top = 167
               Left = 446
               Bottom = 279
               Right = 656
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "tp"
            Begin Extent = 
               Top = 7
               Left = 586
               Bottom = 138
               Right = 756
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pi"
            Begin Extent = 
               Top = 326
               Left = 319
               Bottom = 568
               Right = 535
            End
            DisplayFlags = 280
            TopColumn = 0
 ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_Orders'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'        End
         Begin Table = "ws"
            Begin Extent = 
               Top = 346
               Left = 1321
               Bottom = 673
               Right = 1519
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 2850
         Alias = 1515
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_Orders'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_Orders'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "p"
            Begin Extent = 
               Top = 155
               Left = 467
               Bottom = 453
               Right = 647
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 178
               Left = 962
               Bottom = 290
               Right = 1132
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "o"
            Begin Extent = 
               Top = 168
               Left = 125
               Bottom = 297
               Right = 311
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderTotalPayments'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_OrderTotalPayments'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[73] 4[6] 2[8] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1[62] 4[23] 3) )"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "cur"
            Begin Extent = 
               Top = 713
               Left = 227
               Bottom = 842
               Right = 397
            End
            DisplayFlags = 280
            TopColumn = 2
         End
         Begin Table = "pl"
            Begin Extent = 
               Top = 699
               Left = 467
               Bottom = 890
               Right = 657
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "trxt"
            Begin Extent = 
               Top = 27
               Left = 142
               Bottom = 139
               Right = 329
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "trx"
            Begin Extent = 
               Top = 11
               Left = 452
               Bottom = 314
               Right = 655
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sol"
            Begin Extent = 
               Top = 270
               Left = 759
               Bottom = 685
               Right = 945
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "so"
            Begin Extent = 
               Top = 300
               Left = 1060
               Bottom = 599
               Right = 1248
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "solt"
            Begin Extent = 
               Top = 399
               Left = 460
               Bottom = 509
               Right = 630
            End
            DisplayFlags = 280
            TopColumn =' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_Transactions'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N' 0
         End
         Begin Table = "bu"
            Begin Extent = 
               Top = 158
               Left = 1563
               Bottom = 323
               Right = 1759
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pm"
            Begin Extent = 
               Top = 467
               Left = 1632
               Bottom = 598
               Right = 1842
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pt"
            Begin Extent = 
               Top = 529
               Left = 460
               Bottom = 641
               Right = 626
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "su"
            Begin Extent = 
               Top = 20
               Left = 1141
               Bottom = 273
               Right = 1331
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ws"
            Begin Extent = 
               Top = 357
               Left = 1319
               Bottom = 486
               Right = 1517
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "cb"
            Begin Extent = 
               Top = 781
               Left = 1053
               Bottom = 910
               Right = 1279
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 617
               Left = 1051
               Bottom = 746
               Right = 1278
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pi"
            Begin Extent = 
               Top = 563
               Left = 1306
               Bottom = 794
               Right = 1522
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pst"
            Begin Extent = 
               Top = 451
               Left = 0
               Bottom = 563
               Right = 170
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 336
               Left = 230
               Bottom = 569
               Right = 410
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 50
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 2145
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
     ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_Transactions'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane3', @value=N'    Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 2940
         Alias = 3555
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_Transactions'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=3 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_SALE_Transactions'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[23] 4[37] 2[24] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "a"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 238
               Right = 319
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 42
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 7530
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_Authors'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_Authors'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[36] 2[12] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1[60] 4[24] 3) )"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "b"
            Begin Extent = 
               Top = 424
               Left = 1151
               Bottom = 553
               Right = 1377
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "bu"
            Begin Extent = 
               Top = 522
               Left = 1468
               Bottom = 688
               Right = 1749
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "e"
            Begin Extent = 
               Top = 42
               Left = 556
               Bottom = 393
               Right = 756
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 1
               Left = 827
               Bottom = 113
               Right = 997
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 58
               Left = 275
               Bottom = 337
               Right = 475
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "w"
            Begin Extent = 
               Top = 22
               Left = 1149
               Bottom = 150
               Right = 1370
            End
            DisplayFlags = 280
            TopColumn = 5
         End
         Begin Table = "su"
            Begin Extent = 
               Top = 15
               Left = 1481
               Bottom = 210
               Right = 1762
            End
            DisplayFlags = 280
            TopColumn = 0
    ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_EventsLog'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'     End
         Begin Table = "c"
            Begin Extent = 
               Top = 165
               Left = 1146
               Bottom = 404
               Right = 1371
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "cu"
            Begin Extent = 
               Top = 251
               Left = 1487
               Bottom = 489
               Right = 1768
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "vu"
            Begin Extent = 
               Top = 571
               Left = 1096
               Bottom = 832
               Right = 1321
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "uv"
            Begin Extent = 
               Top = 439
               Left = 838
               Bottom = 692
               Right = 1023
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "u"
            Begin Extent = 
               Top = 91
               Left = 10
               Bottom = 406
               Right = 210
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 44
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1890
         Alias = 4305
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_EventsLog'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_EventsLog'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "i"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 220
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 25
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_Items'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_Items'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[47] 4[15] 2[15] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "l"
            Begin Extent = 
               Top = 80
               Left = 34
               Bottom = 264
               Right = 220
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "u"
            Begin Extent = 
               Top = 28
               Left = 379
               Bottom = 252
               Right = 607
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 0
               Left = 974
               Bottom = 244
               Right = 1160
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "e"
            Begin Extent = 
               Top = 237
               Left = 738
               Bottom = 332
               Right = 924
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 4200
         Alias = 2775
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_LastActivityDates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_LastActivityDates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[18] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "t"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 101
               Right = 224
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 2235
         Width = 2550
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_LastEventDates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_LastEventDates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[7] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "SALE_Orders"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 372
               Right = 226
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_LastSaleDates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_LastSaleDates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "s"
            Begin Extent = 
               Top = 110
               Left = 107
               Bottom = 205
               Right = 293
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "oh"
            Begin Extent = 
               Top = 129
               Left = 876
               Bottom = 224
               Right = 1062
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "u"
            Begin Extent = 
               Top = 6
               Left = 486
               Bottom = 352
               Right = 783
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "w"
            Begin Extent = 
               Top = 5
               Left = 110
               Bottom = 100
               Right = 296
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v"
            Begin Extent = 
               Top = 229
               Left = 111
               Bottom = 324
               Right = 297
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ch"
            Begin Extent = 
               Top = 375
               Left = 846
               Bottom = 470
               Right = 1032
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "b"
            Begin Extent = 
               Top = 242
               Left = 862
               Bottom = 337
               Right = 1048
            End
            DisplayFlags = 280
            TopColumn = 0
      ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_Statistics'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'   End
         Begin Table = "c"
            Begin Extent = 
               Top = 22
               Left = 885
               Bottom = 117
               Right = 1071
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 5790
         Alias = 1245
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_Statistics'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_Statistics'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[65] 4[11] 2[9] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "u"
            Begin Extent = 
               Top = 35
               Left = 715
               Bottom = 977
               Right = 976
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "rt"
            Begin Extent = 
               Top = 450
               Left = 371
               Bottom = 578
               Right = 581
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "stat"
            Begin Extent = 
               Top = 201
               Left = 1198
               Bottom = 473
               Right = 1368
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pt"
            Begin Extent = 
               Top = 655
               Left = 401
               Bottom = 767
               Right = 571
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ws"
            Begin Extent = 
               Top = 570
               Left = 1120
               Bottom = 802
               Right = 1318
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "us"
            Begin Extent = 
               Top = 18
               Left = 1178
               Bottom = 113
               Right = 1348
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 188
               Left = 466
               Bottom = 332
               Right = 626
            End
            DisplayFlags = 280
            TopColumn = ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_UserLogins'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'0
         End
         Begin Table = "m"
            Begin Extent = 
               Top = 27
               Left = 19
               Bottom = 418
               Right = 259
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "o"
            Begin Extent = 
               Top = 490
               Left = 35
               Bottom = 615
               Right = 196
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 34
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 5640
         Alias = 1248
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_UserLogins'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_UserLogins'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[55] 4[20] 2[9] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1[50] 4[25] 3) )"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 1
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = -96
         Left = 0
      End
      Begin Tables = 
         Begin Table = "u"
            Begin Extent = 
               Top = 58
               Left = 28
               Bottom = 1003
               Right = 289
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "rt"
            Begin Extent = 
               Top = 226
               Left = 392
               Bottom = 338
               Right = 602
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 24
               Left = 391
               Bottom = 212
               Right = 551
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pt"
            Begin Extent = 
               Top = 677
               Left = 398
               Bottom = 789
               Right = 568
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ws"
            Begin Extent = 
               Top = 397
               Left = 519
               Bottom = 654
               Right = 732
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "m"
            Begin Extent = 
               Top = 25
               Left = 818
               Bottom = 416
               Right = 1058
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "o"
            Begin Extent = 
               Top = 443
               Left = 843
               Bottom = 605
               Right = 1004
            End
            DisplayFlags = 280
            TopColumn = 0
     ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_UsersLib'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'    End
      End
   End
   Begin SQLPane = 
      PaneHidden = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 43
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 5640
         Alias = 2520
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_UsersLib'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_USER_UsersLib'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "i"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 168
               Right = 284
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 23
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_WS_Items'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_WS_Items'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[15] 2[18] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "owi"
            Begin Extent = 
               Top = 16
               Left = 866
               Bottom = 111
               Right = 1036
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "afi"
            Begin Extent = 
               Top = 149
               Left = 864
               Bottom = 244
               Right = 1034
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "rs"
            Begin Extent = 
               Top = 334
               Left = 853
               Bottom = 446
               Right = 1063
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ws"
            Begin Extent = 
               Top = 32
               Left = 479
               Bottom = 464
               Right = 677
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "u"
            Begin Extent = 
               Top = 10
               Left = 102
               Bottom = 421
               Right = 306
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 20
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_WS_StoresLib'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 1560
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_WS_StoresLib'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_WS_StoresLib'
GO
