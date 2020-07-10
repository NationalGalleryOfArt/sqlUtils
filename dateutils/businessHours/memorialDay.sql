

/****** Object:  UserDefinedFunction [attendance].[memorialDay]    Script Date: 7/10/2020 12:55:52 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE function [attendance].[memorialDay]( @ofThisDate datetime ) returns DateTime as 
begin
	--DECLARE @ofThisDate DATE = '2020-09-01'
	DECLARE @juneFirst DATE = cast(cast(datepart(year, @ofThisDate) as varchar) +'-06-01' as Date)

	DECLARE @memorialDay DATETIME
	SELECT @memorialDay = DATEADD(dd, - (DATEDIFF(dd, 0, EOlastmonth)%7), EOlastmonth) FROM
	(SELECT DATEADD(mm, -1, EOMONTH(@juneFirst)) as EOlastmonth) A;

	return @memorialDay
end

GO


