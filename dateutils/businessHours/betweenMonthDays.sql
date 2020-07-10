
/****** Object:  UserDefinedFunction [attendance].[betweenMonthDays]    Script Date: 7/10/2020 12:56:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE function [attendance].[betweenMonthDays](@sMon int, @sDay int, @eMon int, @eDay int, @dMon int, @dDay int) returns bit as 
begin
	if ( @sMon > @eMon OR ( @sMon = @eMon AND @sDay > @eDay ) )
	begin
		-- inverted scenario where start month is greater than end month, e.g. 11/15 through 3/15 annually
		if ( (@dMon > @sMon OR ( @dMon = @sMon AND @dDay >= @sDay )) OR (@dMon < @eMon OR ( @dMon = @eMon AND @dDay <= @eDay ) ) )
			return 1
	end
	else begin
		-- "normal" case where we don't span a calendar year
		if ( (@dMon > @sMon OR ( @dMon = @sMon AND @dDay >= @sDay )) AND (@dMon < @eMon OR ( @dMon = @eMon AND @dDay <= @eDay ) ) )
			return 1;
	end

	return 0
end
GO


