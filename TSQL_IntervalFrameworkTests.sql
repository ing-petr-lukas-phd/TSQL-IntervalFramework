------------------------------------------------------------
-- Test 1: Interval constructor
------------------------------------------------------------
BEGIN
    PRINT 'Test 1: Interval constructor';
    DECLARE @s ifram.IntervalSet = [ifram].[Interval]('2025-01-01', '2025-01-10');
    SELECT 
        'Duration of interval' AS TestName,
        [ifram].[Duration](@s) AS Actual,
        9.0 AS Expected;
END;
GO

------------------------------------------------------------
-- Test 2: Add
------------------------------------------------------------
BEGIN
    PRINT 'Test 2: Add';
    DECLARE @s ifram.IntervalSet = [ifram].[Empty]();
    SET @s = [ifram].[Add](@s, '2025-01-01', '2025-01-05');
    SET @s = [ifram].[Add](@s, '2025-01-10', '2025-01-15');
    SELECT 
        'Duration after adding two disjoint intervals' AS TestName,
        [ifram].[Duration](@s) AS Actual,
        9.0 AS Expected;
END;
GO

------------------------------------------------------------
-- Test 3: Union
------------------------------------------------------------
BEGIN
    PRINT 'Test 3: Union';
    DECLARE @s1 ifram.IntervalSet = [ifram].[Interval]('2025-01-01', '2025-01-05');
    DECLARE @s2 ifram.IntervalSet = [ifram].[Interval]('2025-01-10', '2025-01-15');
    SELECT 
        'Union of two disjoint intervals' AS TestName,
        [ifram].[Duration]([ifram].[Union](@s1, @s2)) AS Actual,
        9.0 AS Expected;
END;
GO

------------------------------------------------------------
-- Test 4: Intersect
------------------------------------------------------------
BEGIN
    PRINT 'Test 4: Intersect';
    DECLARE @s1 ifram.IntervalSet = [ifram].[Interval]('2025-01-01', '2025-01-10');
    DECLARE @s2 ifram.IntervalSet = [ifram].[Interval]('2025-01-05', '2025-01-15');
    SELECT 
        'Intersection of overlapping intervals' AS TestName,
        [ifram].[Duration]([ifram].[Intersect](@s1, @s2)) AS Actual,
        5.0 AS Expected;
END;
GO

------------------------------------------------------------
-- Test 6: Subtract
------------------------------------------------------------
BEGIN
    PRINT 'Test 6: Subtract';
    DECLARE @s1 ifram.IntervalSet = [ifram].[Interval]('2025-01-01', '2025-01-10');
    DECLARE @s2 ifram.IntervalSet = [ifram].[Interval]('2025-01-05', '2025-01-15');
    SELECT 
        'Subtraction of overlapping intervals' AS TestName,
        [ifram].[Duration]([ifram].[Subtract](@s1, @s2)) AS Actual,
        4.0 AS Expected;
END;
GO

------------------------------------------------------------
-- Test 7: Edge cases
------------------------------------------------------------
BEGIN
    PRINT 'Test 7a: Zero-length interval';
    DECLARE @s1 ifram.IntervalSet = [ifram].[Interval]('2025-01-01', '2025-01-01');
    SELECT 
        'Duration of zero-length interval' AS TestName,
        [ifram].[Duration](@s1) AS Actual,
        0.0 AS Expected;

    PRINT 'Test 7b: Touching intervals';
    DECLARE @s2 ifram.IntervalSet = [ifram].[Empty]();
    SET @s2 = [ifram].[Add](@s2, '2025-01-01', '2025-01-05');
    SET @s2 = [ifram].[Add](@s2, '2025-01-05', '2025-01-10');
    SELECT 
        'Touching intervals' AS TestName,
        [ifram].[Duration](@s2) AS Actual,
        9.0 AS ExpectedNote;
END;
GO

------------------------------------------------------------
-- Test 8: Multiple subtraction pieces
------------------------------------------------------------
BEGIN
    PRINT 'Test 8: Multiple subtraction pieces';
    DECLARE @s1 ifram.IntervalSet = [ifram].[Interval]('2025-01-01', '2025-01-15');
    DECLARE @s2 ifram.IntervalSet = [ifram].[Empty]();
    SET @s2 = [ifram].[Add](@s2, '2025-01-03', '2025-01-05');
    SET @s2 = [ifram].[Add](@s2, '2025-01-10', '2025-01-12');
    SELECT 
        'Subtract 3–5 and 10–12 from 1–15' AS TestName,
        [ifram].[Duration]([ifram].[Subtract](@s1, @s2)) AS Actual,
        11.0 AS Expected;
END;
GO

------------------------------------------------------------
-- Test 9: Complex scenario with multiple operations
------------------------------------------------------------
BEGIN
    PRINT 'Test 9: Complex scenario with multiple operations';
    DECLARE @s1 ifram.IntervalSet = [ifram].[Empty]();
    DECLARE @s2 ifram.IntervalSet = [ifram].[Empty]();
    DECLARE @s3 ifram.IntervalSet = [ifram].[Empty]();

    SET @s1 = [ifram].[Add](@s1, '2025-01-01', '2025-01-10');
    SET @s1 = [ifram].[Add](@s1, '2025-01-20', '2025-01-25');

    SET @s2 = [ifram].[Add](@s2, '2025-01-05', '2025-01-15');
    SET @s2 = [ifram].[Add](@s2, '2025-01-22', '2025-01-30');

    SET @s3 = [ifram].[Union](@s1, @s2);
    SELECT 'Union duration' AS TestName, [ifram].[Duration](@s3) AS Actual, 24.0 AS Expected;

    DECLARE @sIntersect ifram.IntervalSet = [ifram].[Intersect](@s1, @s2);
    SELECT 'Intersection duration' AS TestName, [ifram].[Duration](@sIntersect) AS Actual, 8.0 AS Expected;

    DECLARE @sSubtract ifram.IntervalSet = [ifram].[Subtract](@s1, @s2);
    SELECT 'Subtract duration' AS TestName, [ifram].[Duration](@sSubtract) AS Actual, 6.0 AS Expected;
END;
GO