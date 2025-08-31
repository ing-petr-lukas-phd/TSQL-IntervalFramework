# T-SQL Interval Framework

A reusable **T-SQL framework** for working with time intervals in Microsoft SQL Server.  
It provides a set of user-defined functions to perform operations such as **union**, **intersection**, and **subtraction** on intervals.

Typical use cases include:
- Planning and scheduling
- Calendar operations
- Availability/reservation systems
- Detecting and handling overlapping intervals

---

## 🚀 Features

- Store intervals in a normalized way - intervals are stored in the minimal non-overlapping form
- Perform set operations:
  - `Union`
  - `Intersect`
  - `Subtract`
- `Duration` function returns the total duration of non-overlapping intervals in days
- Fully written in T-SQL – no external dependencies
- Unit test suite included

---

## 📂 Repository Structure
- `/src` -> T-SQL script to create types and functions
- `/tests` -> T-SQL unit tests
- `README.md`
- `LICENSE`

## 🧩 Usage Example

```tsql
DECLARE @s ifram.IntervalSet = ifram.[Empty]();

-- Add the employee's attendance interval.
SET @s = ifram.[Add](@s, '2025-02-01 05:55', '2025-02-01 14:10');

-- Intersect the interval with the work shift.
SET @s = ifram.[Intersect](@s, ifram.Interval('2025-02-01 06:00', '2025-02-01 14:00'));

-- Subtract the lunch break.
SET @s = ifram.[Subtract](@s, ifram.Interval('2025-02-01 11:30', '2025-02-01 12:00'));

PRINT 'Total duration: ' + CAST(ifram.[Duration](@s) * 24 AS VARCHAR) + ' hours';
```

## 📜 License

This project is licensed under the MIT License – free for commercial and private use.

## 🌍 Links

- GitHub Topics: tsql, sql-server, intervals, calendar, time-management
