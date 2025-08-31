IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'ifram')
BEGIN
	EXEC('CREATE SCHEMA [ifram]');
END;

GO

IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = N'IntervalSet' AND is_table_type = 0 AND schema_id = schema_id('ifram'))
BEGIN
	EXEC('CREATE TYPE [ifram].[IntervalSet] FROM [varbinary](max) NOT NULL');
END;

GO

-- =============================================
-- Adds a time interval to an interval set.
-- =============================================
CREATE OR ALTER FUNCTION [ifram].[Add](@set AS IntervalSet, @start AS DATETIME, @finish AS DATETIME) RETURNS IntervalSet AS
BEGIN
	-- Union the existing set with a new set of the interval.
	RETURN [ifram].[Union](@set, [ifram].[Interval](@start, @finish));
END

GO

-- =============================================
-- Gets the total duration (days) of non-
-- overlapping intervals in the set.
-- =============================================
CREATE OR ALTER FUNCTION [ifram].[Duration](@set IntervalSet) RETURNS FLOAT AS
BEGIN
	-- Return NULL if the input is NULL.
	IF @set IS NULL
		RETURN NULL;

	DECLARE @result FLOAT;
	DECLARE @i INT;
	DECLARE @start DATETIME;
	DECLARE @finish DATETIME;
	SET @i = 1;
	SET @result = 0;	
	
	-- Normalize the set to make sure that any overlapping intervals are eliminated.
	SET @set = ifram.Normalize(@set);
	
	-- Iterate through the binary representation and accumulate the length of individual intervals.
	WHILE @i < LEN(@set)
	BEGIN
		SET @start = CAST(CAST(SUBSTRING(@set, @i, 10) AS BINARY(9)) AS DATETIME);
		SET @i = @i + 8;

		SET @finish = CAST(CAST(SUBSTRING(@set, @i, 10) AS BINARY(9)) AS DATETIME);
		SET @i = @i + 8;

		SET @result += CAST((@finish - @start) AS FLOAT);
	END
	
	RETURN @result;
END

GO

-- =============================================
-- Initializes an empty interval set.
-- =============================================
CREATE OR ALTER FUNCTION [ifram].[Empty]() RETURNS IntervalSet AS
BEGIN
	-- Each interval set starts with the '0' character. The zero value itself
	-- does not have any meaning, it only distinguishes an empty set from NULL.
	RETURN CAST(0 AS BINARY(1));
END

GO

-- =============================================
-- Returns the intersection of two interval
-- sets, i.e. the result is a set of intervals 
-- that exist in the both input sets.
-- =============================================
CREATE OR ALTER FUNCTION [ifram].[Intersect](@set1 IntervalSet, @set2 IntervalSet) RETURNS IntervalSet AS
BEGIN
	-- Return NULL if any of the inputs is NULL.
	IF @set1 IS NULL OR @set2 IS NULL
		RETURN NULL;

	DECLARE @result IntervalSet;
	DECLARE @i INT;
	DECLARE @timeStamp DATETIME;
	DECLARE @level INT;

	DECLARE @table TABLE
	(
		[timeStamp] DATETIME,
		[start] BIT
	);
	
	-- Iterate through the both sets and insert the time stamps into a temporary table.
	-- Each set is inserted as two records, where the starting time stamp is distinguished
	-- by the start BIT attribute set to 1.
	SET @i = 1;
	WHILE @i < LEN(@set1)
	BEGIN
		SET @timeStamp = CAST(CAST(SUBSTRING(@set1, @i, 10) AS BINARY(9)) AS DATETIME);
		INSERT INTO @table ([timeStamp], [start]) VALUES (@timeStamp, 1);
		SET @i = @i + 8;

		SET @timeStamp = CAST(CAST(SUBSTRING(@set1, @i, 10) AS BINARY(9)) AS DATETIME);
		INSERT INTO @table ([timeStamp], [start]) VALUES (@timeStamp, 0);
		SET @i = @i + 8;
	END;

	SET @i = 1;
	WHILE @i < LEN(@set2)
	BEGIN
		SET @timeStamp = CAST(CAST(SUBSTRING(@set2, @i, 10) AS BINARY(9)) AS DATETIME);
		INSERT INTO @table ([timeStamp], [start]) VALUES (@timeStamp, 1);
		SET @i = @i + 8;

		SET @timeStamp = CAST(CAST(SUBSTRING(@set2, @i, 10) AS BINARY(9)) AS DATETIME);
		INSERT INTO @table ([timeStamp], [start]) VALUES (@timeStamp, 0);
		SET @i = @i + 8;
	END;				

	-- This is the core logic of the detection of the intersection. We iterate through
	-- the table which is sorted by the time stamps and update the @level variable.
	-- overlapped intervals are detected when @level = 2. The principle is very
	-- similar to the normalization.

	SET @result = ifram.[Empty]();
	SET @level = 0;

	SELECT
		@result = CASE
			WHEN
				(@level = 1 AND [start] = 1) OR -- If the current level is 1 and an interval starts, we find a start of an overlapping interval.
				(@level = 2 AND [start] = 0)    -- If the current level is 2 and an interval finishes, we find a finish of an overlapping interval.
			THEN @result + CAST([timeStamp] AS BINARY(8))
			ELSE @result
		END,
		@level = CASE
			WHEN [start] = 1 THEN @level + 1
			ELSE @level - 1
		END
	FROM @table
	ORDER BY [timeStamp], [start];
	
	RETURN @result;
END;

GO

-- =============================================
-- Initializes a new interval set with a single
-- time interval.
-- =============================================
CREATE OR ALTER FUNCTION [ifram].[Interval](@start DATETIME, @finish DATETIME) RETURNS IntervalSet
AS
BEGIN
	-- Return NULL if any of the inputs is NULL.
	IF @start IS NULL OR @finish IS NULL
		RETURN NULL;
	
	-- Swap @start and @finish, if @finish precedes @start.
	DECLARE @temp DATETIME;
	IF @finish < @start
	BEGIN
		SET @temp = @start;
		SET @start = @finish;
		SET @finish = @temp;
	END;
	
	-- Convert @start and @finish to the binary representation and concatenate it with an empty set.
	RETURN ifram.Empty() + CAST(@start AS BINARY(8)) + CAST(@finish AS BINARY(8));
END

GO

-- =============================================
-- Returns the normalized time set which
-- contains only the minimal set of non-
-- overlapping intervals. The function is
-- not supposed to be invoked by user, it is
-- called by individual operations
-- automatically, if it is necessary.
-- =============================================
CREATE OR ALTER FUNCTION [ifram].[Normalize](@set IntervalSet) RETURNS IntervalSet AS
BEGIN
	-- Return NULL if the input is NULL.
	IF @set IS NULL
		RETURN NULL;

	DECLARE @result IntervalSet;
	DECLARE @i INT;
	DECLARE @timeStamp DATETIME;
	DECLARE @level INT;

	DECLARE @table TABLE
	(
		[timeStamp] DATETIME,
		[start] BIT
	);
	
	-- Insert the time stamps into a temporary table. Each set is inserted as two records, 
	-- where the starting time stamp is distinguished by the start BIT attribute set to 1.
	SET @i = 1;
	WHILE @i < LEN(@set)
	BEGIN
		SET @timeStamp = CAST(CAST(SUBSTRING(@set, @i, 10) AS BINARY(9)) AS DATETIME);
		INSERT INTO @table ([timeStamp], [start]) VALUES (@timeStamp, 1);
		SET @i = @i + 8;

		SET @timeStamp = CAST(CAST(SUBSTRING(@set, @i, 10) AS BINARY(9)) AS DATETIME);
		INSERT INTO @table ([timeStamp], [start]) VALUES (@timeStamp, 0);
		SET @i = @i + 8;
	END;
	
	SET @result = ifram.[Empty]();
	SET @level = 0;

	-- This is the core logic of the detection of the normalization. We iterate through
	-- the table which is sorted by the time stamps and update the @level variable.
	-- overlapped intervals are detected when @level > 0, i.e. these intervals are
	-- not recorded to the result. The principle is very similar to the intersection.

	SELECT
		@result = CASE
			WHEN
				(@level = 0 AND [start] = 1) OR -- We record a start of an interval only when level is zero. For a non-zero level, we process an overlapping interval which is ignored.
				(@level = 1 AND [start] = 0)    -- We record a finish of an interval only when level is one.
			THEN @result + CAST([timeStamp] AS BINARY(8))
			ELSE @result
		END,
		@level = CASE
			WHEN [start] = 1 THEN @level + 1
			ELSE @level - 1
		END
	FROM @table
	ORDER BY [timeStamp], [start];

	RETURN @result;
END

GO

-- =============================================
-- Returns the subtraction of the second set
-- from the first set.
-- =============================================
CREATE OR ALTER FUNCTION [ifram].[Subtract](@set1 IntervalSet, @set2 IntervalSet) RETURNS IntervalSet AS
BEGIN
	-- Subtraction equals to the intersection of the first set with the supplement of the second set.
	RETURN ifram.[Intersect](@set1, ifram.[Supplement](@set2));
END;

GO

-- =============================================
-- Returns the supplement of the input interval
-- set to the universe.
-- =============================================
CREATE OR ALTER FUNCTION [ifram].[Supplement](@set IntervalSet) RETURNS IntervalSet AS
BEGIN
	-- Return NULL if the input is NULL.
	IF @set IS NULL
		RETURN NULL;

	-- Prepare constants for the minimal and maximal values.
	DECLARE @minDate DATETIME = CAST('1753-01-01T00:00:00.000' AS DATETIME);
	DECLARE @maxDate DATETIME = CAST('9999-12-31T23:59:59.997' AS DATETIME);
	
	-- This is a very simple trick, we insert the minimal and maxmal time stamps to the start and end of the set, respectively.
	-- In such a way, the meaning of all existing time stamps in the set is inverted, i.e. time stamps which originally
	-- represented a start of an interval now represent a finish of an interval and vice versa.
	RETURN ifram.[Normalize](ifram.[Empty]() + CAST(@minDate AS BINARY(8)) + SUBSTRING(@set, 2, LEN(@set)-1) + CAST(@maxDate AS BINARY(8)));
END;

GO

-- =============================================
-- Converts the interval set to a table of
-- intervals.
-- =============================================
CREATE OR ALTER FUNCTION [ifram].[ToTable](@set IntervalSet)
RETURNS @result TABLE (
	[from] DATETIME,
	[till] DATETIME
)
AS
BEGIN
	-- Return NULL if the input is NULL.
	IF @set IS NULL
		RETURN;

	DECLARE @i INT;
	DECLARE @from DATETIME;
	DECLARE @till DATETIME;
	SET @i = 1;
	
	WHILE @i < LEN(@set)
	BEGIN
		SET @from = CAST(CAST(SUBSTRING(@set, @i, 10) AS BINARY(9)) AS DATETIME);
		SET @i = @i + 8;

		SET @till = CAST(CAST(SUBSTRING(@set, @i, 10) AS BINARY(9)) AS DATETIME);
		SET @i = @i + 8;
		
		INSERT INTO @result VALUES (@from, @till);
	END;
	
	RETURN;
END;

GO

-- =============================================
-- Returns the textual representation of the
-- interval set. The function can be utilized
-- for debug purposes.
-- =============================================
CREATE OR ALTER FUNCTION [ifram].[ToVarchar](@set AS IntervalSet) RETURNS VARCHAR(MAX) AS
BEGIN
	-- Return NULL if the input is NULL.
	IF @set IS NULL
		RETURN NULL;

	DECLARE @result NVARCHAR(MAX);
	DECLARE @i INT;
	DECLARE @timeStamp DATETIME;
	SET @i = 1;
	SET @result = '';	
	
	WHILE @i < LEN(@set)
	BEGIN
		IF @result != ''
			SET @result = @result + '; ';
	
		SET @timeStamp = CAST(CAST(SUBSTRING(@set, @i, 10) AS BINARY(9)) AS DATETIME);
		SET @i = @i + 8;
		SET @result = @result + '(' + CAST(@timeStamp AS VARCHAR) + ' - ';

		SET @timeStamp = CAST(CAST(SUBSTRING(@set, @i, 10) AS BINARY(9)) AS DATETIME);
		SET @i = @i + 8;
		SET @result = @result + CAST(@timeStamp AS VARCHAR) + ')';
	END
	
	RETURN @result;
END

GO

-- =============================================
-- Returns the union of two interval sets.
-- =============================================
CREATE OR ALTER FUNCTION [ifram].[Union](@set1 IntervalSet, @set2 IntervalSet) RETURNS IntervalSet AS
BEGIN
	-- Return NULL if any of the inputs is NULL.
	IF @set1 IS NULL OR @set2 IS NULL
		RETURN NULL;

	-- We just concatenate the both interval sets and do the normalization to eliminate overlapping intervals.
	RETURN ifram.[Normalize](ifram.[Empty]() + SUBSTRING(@set1, 2, LEN(@set1)-1) + SUBSTRING(@set2, 2, LEN(@set2)-1));
END
