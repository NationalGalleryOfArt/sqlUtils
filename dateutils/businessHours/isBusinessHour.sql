
/****** Object:  UserDefinedFunction [attendance].[isGalleryOpen]    Script Date: 7/9/2020 2:10:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER function [attendance].[isBusinessHour]( @building nvarchar(16), @dataDateTime datetime ) returns 
	BIT AS
	-- nvarchar(max) as 
BEGIN

	DECLARE @dataHour int = DATEPART(HOUR,@dataDateTime);
	DECLARE @dataDateForRules Date = CAST(@dataDateTime as Date);
	-- if we're looking at a time of midnight, then we use the rules for the prior day rather than the current day
	--if ( @dataHour = 0 )
	--	set @dataDateForRules = DATEADD(DAY,-1,@dataDateForRules);
	DECLARE @dataYear nvarchar(4) = CAST(DATEPART(YEAR,@dataDateTime) as nvarchar);
	DECLARE @dMon INT = DATEPART(MONTH, @dataDateForRules);
	DECLARE @dDay INT = DATEPART(DAY, @dataDateForRules);

	DECLARE rules_cursor CURSOR FOR 
	SELECT 
		building, 
		startDate, 
		startHoliday, 
		startDateEachYear, 
		endDate, 
		endDateEachYear, 
		onlyOnDay, 
		startHour, 
		durationHours, 
		isOpen 
	FROM [attendance].[businessHourRules] order by coalesce(precedence,999999), startdate desc, startholiday desc, startdateeachyear desc, onlyOnDay desc, building desc

	DECLARE @bldg				VARCHAR(256);
	DECLARE @startDate			DATE;
	DECLARE @startHoliday		NVARCHAR(32);
	DECLARE @startDateEachYear	NVARCHAR(16);
	DECLARE @endDate			DATE;
	DECLARE @endDateEachYear	NVARCHAR(16);
	DECLARE @onlyOnDay			NVARCHAR(9);
	DECLARE @startHour			NVARCHAR(5);
	DECLARE @durationHours		FLOAT;
	DECLARE @isOpen				BIT;
	DECLARE @log				NVARCHAR(max) = '';
	DECLARE @logging			BIT = 0;

	OPEN rules_cursor;
	FETCH NEXT FROM rules_cursor INTO @bldg, @startDate, @startHoliday, @startDateEachYear, @endDate, @endDateEachYear, @onlyOnDay, @startHour, @durationHours, @isOpen;
	WHILE @@FETCH_STATUS = 0 
	BEGIN

	if (@logging = 1)
		set @log = @log + 
		'bldg:'					+ coalesce(CAST(@bldg as nvarchar),					'null')	+ CHAR(9) +
		'startDate:'			+ coalesce(CAST(@startDate as nvarchar),			'null')	+ CHAR(9) +
		'startHoliday:'			+ coalesce(CAST(@startHoliday as nvarchar),			'null')	+ CHAR(9) +
		'startDateEachYear:'	+ coalesce(CAST(@startDateEachYear as nvarchar),	'null')	+ CHAR(9) +
		'endDate:'				+ coalesce(CAST(@endDate as nvarchar),				'null')	+ CHAR(9) +
		'endDateEachYear:'		+ coalesce(CAST(@endDateEachYear as nvarchar),		'null')	+ CHAR(9) +
		'onlyOnDay:'			+ coalesce(CAST(@onlyOnDay as nvarchar),			'null')	+ CHAR(9) +
		'durationHours:'		+ coalesce(CAST(@durationHours as nvarchar),		'null')	+ CHAR(9) +
		'isOpen:'				+ coalesce(CAST(@isOpen as nvarchar),				'null')	+ '||';
		
		-- determine whether this rule is applicable to our case by checking each parameter in turn for compliance
		-- we rely on the sort order to pre-determine the applicable rule so all we have to do is check for applicability and return the first
		-- rule that matches our situation
		if ( @bldg = 'ALL' or @bldg = @building ) 
		begin
			-- if st
			if ( @startDate is null or @startDate <= @dataDateForRules )
			begin
				-- compute starting and ending dates for dates that apply each year which means we only look at month and day for comparison
				DECLARE @sDate DATE = null;
				DECLARE @eDate DATE = null;
				DECLARE @sMon	INT = null;
				DECLARE @sDAY	INT = null;
				DECLARE @eMon	INT = null;
				DECLARE @eDAY	INT = null;

				-- interpret HOLIDAY AS A START DATE EACH YEAR if set
				if ( @startHoliday is not null )
				begin
					if ( @startHoliday = 'MEMORIALDAY' ) 
						set @sDate = attendance.memorialDay(@dataDatetime);
					else if ( @startHoliday = 'NEWYEARS' ) 
						set @sDate = CAST(@dataYear + '-01-01' AS DATE)
					else if ( @startHoliday = 'XMAS' ) 
						set @sDate = CAST(@dataYear + '-12-25' AS DATE)
				end 

				-- or set START DATE EACH YEAR IF SET
				if ( @startDateEachYear is not null ) 
					set @sDate = CAST(@dataYear + '-' + @startDateEachYear AS DATE);
				if ( @sDate is not null )
				begin
					set @sMon = DATEPART(MONTH	,@sDate);
					set @sDay = DATEPART(DAY	,@sDate);
				end

				-- set END DATE EACH YEAR if set
				if ( @endDateEachYear is not null ) 
					set @eDate = CAST(@dataYear + '-' + @endDateEachYear AS DATE)
				if ( @eDate is not null)
				begin
					set @eMon = DATEPART(MONTH	,@eDate);
					set @eDay = DATEPART(DAY	,@eDate);
				end

				if (@logging = 1)
					set @log += 'sMon:'			+ coalesce(CAST(@sMon as nvarchar),			'null')	+ CHAR(9) +
								'sDay:'			+ coalesce(CAST(@sDay as nvarchar),			'null')	+ CHAR(9) + 
								'eMon:'			+ coalesce(CAST(@eMon as nvarchar),			'null')	+ CHAR(9) +
								'eDay:'			+ coalesce(CAST(@eDay as nvarchar),			'null')	+ CHAR(9) + 
								'dMon:'			+ coalesce(CAST(@dMon as nvarchar),			'null')	+ CHAR(9) +
								'dDay:'			+ coalesce(CAST(@dDay as nvarchar),			'null')	+ CHAR(9) + '||';

				-- in order for rules that apply every year to be valid, we need both a start and an end date, otherwise ignore the rule
				if ( @sDate is null OR @eDate is null OR attendance.betweenMonthDays(@sMon,@sDay,@eMon,@eDay,@dMon,@dDay) = 1 )
				begin
					if ( @onlyOnDay is null or @onlyOnDay = DATENAME(DW,@dataDateForRules) ) 
					begin
					    -- if we get to this block, then we definitely return a value since we have 
						-- a day that matches the filter - it's just a question of whether we return
						-- the isOpen value or the opposite of the isOpen value
						DECLARE @startDT DateTime = CAST(CAST(@dataDateForRules as nvarchar) + ' ' + @startHour as DateTime);
						DECLARE @endDT DateTime = DATEADD(MINUTE,@durationHours*60,@startDT);
						DECLARE @res BIT;
						if ( @startDT <= @dataDateTime and @endDT > @dataDateTime )
							set @res = @isOpen;
					    else
							set @res = ~@isOpen;

						if (@logging = 1)
							set @log += 
								'dataYear:'				+ coalesce(CAST(@dataYear as nvarchar),		'null')	+ CHAR(9) +
								'dataHour:'				+ coalesce(CAST(@dataHour as nvarchar),		'null')	+ CHAR(9) +
								'dataDateForRules:'		+ coalesce(CAST(@dataDateForRules as nvarchar),		'null')	+ CHAR(9) +
								'dataDateTime:'			+ coalesce(CAST(@dataDateTime as nvarchar),	'null')	+ CHAR(9) +
								'dMon:'					+ coalesce(CAST(@dMon as nvarchar),			'null')	+ CHAR(9) +
								'dDay:'					+ coalesce(CAST(@dDay as nvarchar),			'null')	+ CHAR(9) +
								'res:' + CAST(@res as nvarchar) + '||';

						if (@logging = 1)
							return replace(@log,'||',CHAR(13)+CHAR(10));

						return @res;

					end
				end
			end
	end
	FETCH NEXT FROM rules_cursor INTO @bldg, @startDate, @startHoliday, @startDateEachYear, @endDate, @endDateEachYear, @onlyOnDay, @startHour, @durationHours, @isOpen;
	END;
	CLOSE rules_cursor;
	DEALLOCATE rules_cursor;
	return 0
end
GO


