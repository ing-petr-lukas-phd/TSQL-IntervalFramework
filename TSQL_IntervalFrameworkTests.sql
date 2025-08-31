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
        11.0 AS Expected;  -- Remaining: (1–3=2) + (5–10=5) + (12–15=4)
END;
GO

------------------------------------------------------------
-- Test 11: Complex scenario with multiple operations
------------------------------------------------------------
PRINT 'Test 11: Complex scenario with multiple operations';
DECLARE @c1 ifram.IntervalSet = [ifram].[Empty]();
DECLARE @c2 ifram.IntervalSet = [ifram].[Empty]();
DECLARE @c3 ifram.IntervalSet = [ifram].[Empty]();

-- Step 1: Create two disjoint sets
SET @c1 = [ifram].[Add](@c1, '2025-01-01', '2025-01-10'); -- duration 9
SET @c1 = [ifram].[Add](@c1, '2025-01-20', '2025-01-25'); -- duration +5 = 14

SET @c2 = [ifram].[Add](@c2, '2025-01-05', '2025-01-15'); -- duration 10
SET @c2 = [ifram].[Add](@c2, '2025-01-22', '2025-01-30'); -- duration +8 = 18

-- Step 2: Union them
SET @c3 = [ifram].[Union](@c1, @c2);
SELECT 'Union duration' AS TestName, [ifram].[Duration](@c3) AS Actual, 24.0 AS Expected;
-- Resulting intervals: (1–15 = 14) and (20–30 = 10) → total 24

-- Step 3: Intersect original sets
DECLARE @cIntersect ifram.IntervalSet = [ifram].[Intersect](@c1, @c2);
SELECT 'Intersection duration' AS TestName, [ifram].[Duration](@cIntersect) AS Actual, 8.0 AS Expected;
-- Overlaps: (5–10 = 5) and (22–25 = 3) → total 8

-- Step 4: Subtract c2 from c1
DECLARE @cSubtract ifram.IntervalSet = [ifram].[Subtract](@c1, @c2);
SELECT 'Subtract duration (c1 - c2)' AS TestName, [ifram].[Duration](@cSubtract) AS Actual, 6.0 AS Expected;
-- Remaining from c1: (1–5 = 4) and (20–22 = 2) → total 6
