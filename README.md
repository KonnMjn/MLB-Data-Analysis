# ⚾ MLB SQL Analysis (Course Project)

A compact, end-to-end SQL project analyzing decades of Major League Baseball (MLB) player data.  
This is a **course/guided project** demonstrating advanced SQL querying for real analytical questions.

## 📂 Repository Structure
mlb-sql-analysis/
├─ README.md
├─ LICENSE
├─ .gitignore
├─ sql/
│ ├─ create_statements_final_project_mysql.sql # create DB 
│ └─ final_project.sql # all analytical queries
└─ overview.png # course overview 

- `sql/create_statements_final_project_mysql.sql`: defines database `maven_advanced_sql`, creates tables `players`, `salaries`, `schools`, `school_details`, and inserts sample data.  
- `sql/final_project.sql`: the full analysis queries grouped into four parts (CTEs, window functions, ranking, percentiles, cumulative sums, etc.).

## 🧰 Requirements
- MySQL **8.0+** (recommended for window functions & CTEs).
- Command-line access to `mysql` client or a GUI (MySQL Workbench, DBeaver…).

## 🚀 How to Run
1. **Create schema & load data**
   ```bash
   mysql -u <user> -p < sql/create_statements_final_project_mysql.sql
   ```
  This will create the DB `maven_advanced_sql` and load tables + sample data.
2. Run the full analysis
  Open `final_project.sql in your SQL client and execute block by block.
  
## 🧠 What’s Inside (Key Analyses)

I. School Analysis

Count schools producing MLB players by decade.

Top player-producing schools overall & top-3 by decade (uses ROW_NUMBER/DENSE_RANK).

II. Salary Analysis

Rank teams by average annual spending (top 20% / top quintile with NTILE(5)).

Compute cumulative team spending over years; find the first year each team’s cumulated spend surpassed $1B.

III. Player Career Analysis

Compute starting age, ending age, career length (years) using TIMESTAMPDIFF.

Identify starting/ending teams and count players who start & end at the same team and play > 10 years.

IV. Player Comparison Analysis

Players sharing the same birthday (grouping).

For each team, percentage of bats Right/Left/Both.

Decade-over-decade changes in average height/weight at debut (uses LAG).

## 📌 Notes

This repository is intentionally lightweight—only SQL + an optional overview image.

The dataset in create_statements_final_project_mysql.sql is sample/educational; adjust or import full datasets as needed.

Queries are written to be readable; some blocks include an initial attempt and a more optimized variant.

## 📄 License

Code: MIT (see LICENSE)

Educational use only; data belongs to original providers.

## 🙌 Credit

- Phan Cong Minh
  
- Instructor: Maven Analytics - Alice Zhao.

