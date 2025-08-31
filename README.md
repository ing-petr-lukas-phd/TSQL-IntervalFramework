# T-SQL Interval Framework

A reusable **T-SQL framework** for working with time intervals in Microsoft SQL Server.  
It provides a set of user-defined functions to perform operations such as **union, intersection, and subtraction** on intervals.

Typical use cases include:
- Planning and scheduling
- Calendar operations
- Availability/reservation systems
- Detecting and handling overlapping intervals

---

## 🚀 Features

- Store intervals in a normalized way - intervals are stored in the minimal non-overlapping form.
- Perform set operations:
  - `Union`
  - `Intersect`
  - `Subtract`
- `Duration` function returns the total duration of non-overlapping intervals in days
- Fully written in T-SQL – no external dependencies
- Unit test suite included

---

## 📂 Repository Structure

