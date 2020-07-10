
/****** Object:  Table [attendance].[businessHourRules]    Script Date: 7/10/2020 12:57:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [attendance].[businessHourRules](
	[building] [nvarchar](256) NOT NULL,
	[startDate] [date] NULL,
	[startDateEachYear] [nvarchar](16) NULL,
	[startHoliday] [nvarchar](32) NULL,
	[endDate] [date] NULL,
	[endDateEachYear] [nvarchar](16) NULL,
	[onlyOnDay] [nvarchar](9) NULL,
	[startHour] [nvarchar](5) NULL,
	[durationHours] [float] NULL,
	[isOpen] [bit] NOT NULL,
	[notes] [text] NULL,
	[precedence] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


