# Hotel Booking Analytics — Python, SQL \& Power BI

End-to-end analysis of \~119K hotel bookings (2015–2017, two Portuguese hotels) — from raw-data cleaning through SQL business analysis to an interactive Power BI dashboard on a proper star schema.

## 📌 Project Overview

This project analyzes the Antonio, Almeida \& Nunes hotel bookings dataset (Kaggle), covering a City Hotel and a Resort Hotel over three years. Unlike a dataset with only cosmetic data-quality issues, this one arrived with real problems worth solving: \~27% duplicate rows, negative and extreme-outlier daily rates, missing guest/agent/country values, and zero-guest bookings — all handled in a documented Python cleaning pipeline before the data ever reached SQL.

The project covers the full analytics workflow:

* **Python (pandas):** data cleaning, validation, and outlier handling
* **SQL (MySQL):** 18 business questions across 8 categories — aggregations, CTEs, manually-computed Pearson correlations, sample-size-aware filtering
* **Power BI:** a proper star schema (fact table + 7 dimension tables), DAX measures, and a 4-page interactive dashboard

**Headline finding:** this dataset has real, strong, explainable signal — a sharp contrast to a "flat" dataset with no drivers. Cancellation behavior is predictable from deposit type, lead time, and booking channel; pricing is strongly seasonal and has grown steadily year over year; and guest engagement signals (special requests, repeat-guest status) correlate meaningfully with outcomes. Full findings below.

## Table of Contents

* [Dashboard Preview](https://claude.ai/chat/0421b580-15f7-4e61-ba77-83f630974237#-dashboard-preview)
* [Key Findings](https://claude.ai/chat/0421b580-15f7-4e61-ba77-83f630974237#-key-findings)
* [Technologies Used](https://claude.ai/chat/0421b580-15f7-4e61-ba77-83f630974237#️-technologies-used)
* [Repository Structure](https://claude.ai/chat/0421b580-15f7-4e61-ba77-83f630974237#-repository-structure)
* [Data Cleaning (Python)](https://claude.ai/chat/0421b580-15f7-4e61-ba77-83f630974237#-data-cleaning-python)
* [Database Schema](https://claude.ai/chat/0421b580-15f7-4e61-ba77-83f630974237#-database-schema-mysql)
* [SQL Business Questions \& Findings](https://claude.ai/chat/0421b580-15f7-4e61-ba77-83f630974237#-sql-business-questions--findings)
* [Power BI Star Schema \& Measures](https://claude.ai/chat/0421b580-15f7-4e61-ba77-83f630974237#-power-bi-star-schema--measures)
* [Author](https://claude.ai/chat/0421b580-15f7-4e61-ba77-83f630974237#-author)

\---

## 📊 Dashboard Preview

**🧱 Power BI Data Model**

**![Power BI Data Model](Screenshots/Model.png)**

**Page 1 — Executive Overview** KPI strip (bookings, cancellation rate, revenue, avg. ADR), monthly seasonality trend by hotel, hotel-type comparison, top 10 countries by confirmed revenue.

![Executive Overview](Screenshots/Executive\_Overview.png)

**Page 2 — Cancellation Drivers** Deposit-type cancellation rate (the dataset's standout finding), lead-time-band cancellation gradient, market segment × channel heatmap, cancellation history, customer type.

![Cancellation Drivers](Screenshots/Cancellation\_trend.png)

**Page 3 — Revenue \& Pricing** ADR trend over time by hotel, ADR by room type \& hotel, revenue at risk from cancellations, lead-time/ADR correlation.

![Revenue \& Pricing](Screenshots/Revenue\_\&\_Pricing.png)

**Page 4 — Guest Behavior \& Loyalty** Repeat vs. new guest cancellation and ADR comparison, special-requests vs. cancellation trend, room-mismatch analysis, party size by segment, parking requests by customer type.

![Guest Behaviour \& Loyalty](Screenshots/Guest\_Behaviour.png)

\---

## 🔑 Key Findings

**Cancellations are highly predictable — and the drivers compound.**

* **Deposit type is the single strongest predictor in the dataset**: Non-Refund bookings cancel **94.70%** of the time, vs. 26.72% (No Deposit) and 24.30% (Refundable). Investigation traced this to a narrow population — Groups booked via the TA/TO channel, disproportionately through a single travel agent — consistent with block bookings being released rather than random guest behavior.
* **Lead time predicts cancellation cleanly and monotonically**: from 7.14% for bookings made 0–3 days out, up to \~40% for bookings made 6+ months in advance.
* **Booking channel carries real risk concentration**: Online TA/TA-TO is both the single largest source of bookings (51,251 — over half the dataset) and a high-cancellation channel (35.51%).
* **Previous cancellation history shows a sharp, non-obvious spike**: guests with exactly 1 prior cancellation cancel at 76.16% — over 2.5× the rate of guests with 0 prior cancellations (26.73%) — again linked back to the same Non-Refund/Groups population.

**Pricing is strongly seasonal and has genuinely grown year over year.**

* Resort Hotel's ADR swings nearly 4× across the year ($48.60 in January to $182.10 in August); City Hotel is far flatter (\~$83–125), consistent with a summer-leisure property vs. a business/year-round property.
* Comparing the same month across years, ADR climbed every year: July $116.59 → $129.86 → $143.92 (2015→2016→2017); August $121.77 → $147.37 → $164.66 — a 24–35% increase in peak-season rate over two years.
* Lead time has **no relationship with price** (r ≈ 0.03) — booking early doesn't get a guest a better or worse rate in this dataset, a useful negative finding that rules out a common assumption.

**Guest engagement signals are real, moderate predictors — correctly scaled.**

* Row-level Pearson correlation (not aggregated group averages, which would overstate the effect): number of special requests vs. cancellation, **r ≈ -0.12**; room-type mismatch vs. cancellation, **r ≈ -0.21**. Both real, both moderate — not the inflated \~-0.97 / -0.60 an aggregated calculation would suggest.
* Repeat guests cancel far less often than new guests (\~7% vs. \~28%) but also pay noticeably less on average (\~$65 vs. \~$103 ADR) — loyalty correlates with lower risk and lower rate simultaneously.

**Revenue at risk from cancellations is substantial**: 35.23% of City Hotel's total potential revenue and 31.04% of Resort Hotel's is tied up in bookings that ultimately cancel — framed as revenue *at risk*, not revenue definitively lost, since cancelled rooms may be resold.

\---

## ⚙️ Technologies Used

* **Python** (pandas) — data cleaning and validation
* **MySQL / MySQL Workbench** — business-question SQL analysis
* **Power BI** — star-schema data model, DAX measures, interactive dashboard
* **Git \& GitHub**

\---

## 📁 Repository Structure

```
hotel\_booking\_analytics/
├── Data/          → raw hotel\_bookings.csv and cleaned dataset
├── Python/        → Jupyter notebook: data cleaning \& validation pipeline
├── SQL/           → database setup + all business-question queries
├── Power BI/      → .pbix report file (star schema + dashboard)
└── Screenshots/   → dashboard page exports

```

\---

## 🧹 Data Cleaning (Python)

Cleaning was done in pandas before loading into SQL. Key steps:

* Renamed `adults` / `children` / `babies` to `num\_adults` / `num\_children` / `num\_babies` for clarity
* Dropped `company` (94%+ missing)
* Filled missing `agent` (sentinel -1), `num\_children` (0), and `country` (`'Unknown'`)
* **Removed 32,001 duplicate rows** — roughly 27% of the raw dataset, a genuinely large and unusual amount for this specific Kaggle dataset, confirmed and cross-checked directly against the raw file rather than assumed
* Filtered out negative and extreme-outlier `adr` values (raw data had a minimum of -6.38 and a maximum of 5,400 against a median of \~$95)
* Removed zero-guest bookings (`num\_adults = 0 AND num\_children = 0`)

**Result: 119,390 raw rows → 87,221 cleaned rows.**

Full cleaning notebook: [`/Python`](https://claude.ai/chat/Python)

\---

## 🧱 Database Schema (MySQL)

Cleaned data was loaded into a single `hotel\_bookings` table in MySQL, with derived columns added afterward:

|Derived column Formula Purpose|||
|-|-|-|
|`arrival\_date`|Combined from year/month/day columns|Enables date-based trend and seasonality queries|
|`total\_guests`|`num\_adults + num\_children + num\_babies`|Party size analysis|
|`total\_nights`|`stays\_in\_weekend\_nights + stays\_in\_week\_nights`|Length-of-stay, revenue calculations|
|`total\_revenue`|`adr \* total\_nights`|Revenue analysis|
|`room\_type\_mismatch`|`1` if `reserved\_room\_type ≠ assigned\_room\_type` else `0`|Room assignment analysis|
|`lead\_time\_band`|Custom bins (0-3, 4-7, 8-14, 15-30, 31-60, 61-90, 91-180, 181-365, 366+)|Reused across multiple cancellation-driver queries|

Full setup script: [`/SQL`](https://claude.ai/chat/SQL)

\---

## 📊 SQL Business Questions \& Findings

18 business questions across 8 categories, run against the 87,221-row cleaned dataset.

### Overview

**Total bookings, cancellation rate, and revenue by hotel type**

```sql
WITH summary\_cte AS(
	SELECT 
		hotel,
		COUNT(\*) AS total\_bookings\_received,
		COUNT(CASE WHEN is\_canceled = 0 THEN booking\_id END) AS confirmed\_bookings,
		COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) AS cancelations,
		SUM(CASE WHEN is\_canceled = 0 THEN total\_revenue END) AS revenue
	FROM hotel\_bookings
	GROUP BY hotel
)
SELECT 
	hotel, total\_bookings\_received, confirmed\_bookings, cancelations,
    ROUND(100 \* cancelations / total\_bookings\_received, 2) AS cancelation\_rate,
    revenue
FROM summary\_cte;

```

📌 City Hotel: 53,271 bookings, 30.10% cancellation rate, $12.15M confirmed revenue. Resort Hotel: 33,950 bookings, 23.49% cancellation rate, $10.82M confirmed revenue.

**Booking and revenue trend, 2015–2017**

```sql
SELECT 
    DATE\_FORMAT(arrival\_date, '%Y-%m') AS year\_month,
    COUNT(booking\_id) AS confirmed\_bookings,
    SUM(total\_revenue) AS total\_revenue
FROM hotel\_bookings
WHERE is\_canceled = 0
GROUP BY year\_month
ORDER BY year\_month;

```

📌 August is the peak month every year (7,620 confirmed bookings, $4.6M revenue at its highest). Revenue grew faster than booking volume year over year — e.g. July 2016→2017 bookings +6.5%, revenue +18% — pointing to rate growth rather than volume growth as the main driver.

### Cancellation Analysis

**Cancellation rate by deposit type**

```sql
SELECT 
    deposit\_type,
    COUNT(\*) AS total\_bookings\_received,
    COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) AS cancelations,
    SUM(CASE WHEN is\_canceled = 1 THEN total\_revenue END) AS opportunity\_cost,
    ROUND(100 \* COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) / COUNT(\*), 2) AS cancelation\_rate
FROM hotel\_bookings
GROUP BY deposit\_type;

```

📌 Non-Refund: **94.70%** cancellation (982 of 1,037 bookings). No Deposit: 26.72%. Refundable: 24.30%.

**Investigating the Non-Refund anomaly — market segment, channel, and agent**

```sql
SELECT 
    market\_segment, distribution\_channel, agent,
    COUNT(booking\_id) AS cancellations
FROM hotel\_bookings
WHERE deposit\_type = 'Non Refund' AND is\_canceled = 1
GROUP BY market\_segment, distribution\_channel, agent
ORDER BY cancellations DESC;

```

📌 64.4% of Non-Refund cancellations come from the "Groups" market segment, 89% flow through the TA/TO channel, and a single agent accounts for nearly a third of the anomaly on its own — consistent with tour-operator block bookings being released rather than individual guest cancellations.

**Cancellation rate by lead time band**

```sql
SELECT 
    lead\_time\_band,
    COUNT(\*) AS total\_bookings\_received,
    COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) AS cancelations,
    ROUND(100 \* COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) / COUNT(\*), 2) AS cancelation\_rate
FROM hotel\_bookings
GROUP BY lead\_time\_band
ORDER BY cancelation\_rate DESC;

```

📌 Clean, monotonic gradient: 7.14% (0-3 days) → 11.39% → 20.63% → 28.29% → 31.66% → 32.58% → 35.01% → 39.69% → 40.78% (366+ days).

**Cancellation rate by market segment and distribution channel** (filtered to n ≥ 10 to avoid small-sample noise)

```sql
SELECT 
    market\_segment, distribution\_channel,
    COUNT(\*) AS total\_bookings\_received,
    COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) AS cancelations,
    ROUND(100 \* COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) / COUNT(\*), 2) AS cancelation\_rate
FROM hotel\_bookings
GROUP BY market\_segment, distribution\_channel
HAVING total\_bookings\_received >= 10
ORDER BY cancelation\_rate DESC;

```

📌 Online TA/TA-TO: 35.51% cancellation on 51,251 bookings — the largest volume and one of the highest risk segments simultaneously. Direct bookings are consistently the safest across every channel pairing.

**Cancellation rate by previous cancellation history**

```sql
SELECT 
    CASE
        WHEN previous\_cancellations = 0 THEN '0'
        WHEN previous\_cancellations = 1 THEN '1'
        WHEN previous\_cancellations = 2 THEN '2'
        WHEN previous\_cancellations = 3 THEN '3'
        WHEN previous\_cancellations = 4 THEN '4'
        WHEN previous\_cancellations = 5 THEN '5'
        ELSE '6+'
    END AS previous\_cancellations\_binned,
    COUNT(\*) AS total\_bookings\_received,
    COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) AS cancelations,
    ROUND(100 \* COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) / COUNT(\*), 2) AS cancelation\_rate
FROM hotel\_bookings
GROUP BY previous\_cancellations\_binned
ORDER BY previous\_cancellations\_binned;

```

📌 Sharp, non-monotonic spike at exactly 1 prior cancellation (76.16%) — over 2.5× the 0-prior rate (26.73%) — driven partly by the same Non-Refund/Groups population found above.

**Cancellation rate by customer type**

```sql
SELECT 
    customer\_type,
    COUNT(\*) AS total\_bookings\_received,
    COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) AS cancellations,
    ROUND(100 \* COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) / COUNT(\*), 2) AS cancellation\_rate
FROM hotel\_bookings
GROUP BY customer\_type
ORDER BY customer\_type;

```

📌 Transient (individual) bookings — 82% of the dataset — cancel at 30.14%, by far the highest of the four customer types. Notably, this contradicts the *market segment* "Groups" finding above: `customer\_type = Group` actually has the *lowest* cancellation rate (9.80%) of any customer type — these are two distinct classifications in the source data, not a contradiction in the analysis.

### Revenue Analysis

**Average ADR by hotel, room type, and month**

```sql
SELECT 
    hotel, assigned\_room\_type, MONTH(arrival\_date) AS arrival\_month,
    AVG(CASE WHEN is\_canceled = 0 THEN adr END) AS avg\_adr
FROM hotel\_bookings
GROUP BY hotel, assigned\_room\_type, arrival\_month
ORDER BY avg\_adr DESC;

```

📌 Room types G and F command the highest rates at both hotels; the most-booked room type (A) sits near the bottom of the pricing scale. Resort Hotel's pricing swings nearly 4× seasonally ($48.60 January → $182.10 August); City Hotel is far flatter (\~$83–125 year-round).

**Revenue at risk from cancellations**

```sql
SELECT 
    hotel,
    SUM(total\_revenue) AS total\_potential\_revenue,
    SUM(CASE WHEN is\_canceled = 1 THEN total\_revenue END) AS revenue\_at\_risk\_from\_cancellations,
    ROUND(100 \* SUM(CASE WHEN is\_canceled = 1 THEN total\_revenue END) / SUM(total\_revenue), 2) AS cancelled\_percent
FROM hotel\_bookings
GROUP BY hotel;

```

📌 City Hotel: 35.23% of potential revenue at risk ($6.61M). Resort Hotel: 31.04% ($4.87M). Framed as revenue *at risk*, not revenue definitively lost, since cancelled rooms may be resold to another guest.

**Does lead time correlate with ADR?**

```sql
SELECT 
    (AVG(lead\_time \* adr) - AVG(lead\_time) \* AVG(adr)) /
    (STDDEV\_POP(lead\_time) \* STDDEV\_POP(adr)) AS correlation\_coefficient
FROM hotel\_bookings
WHERE is\_canceled = 0;

```

📌 r ≈ 0.028 — no meaningful relationship. Booking further in advance doesn't predict a higher or lower rate in this dataset.

**ADR trend over time**

```sql
SELECT 
    DATE\_FORMAT(arrival\_date, '%Y-%m') AS year\_month,
    ROUND(AVG(CASE WHEN is\_canceled = 0 THEN adr END), 2) AS avg\_adr
FROM hotel\_bookings
GROUP BY year\_month
ORDER BY year\_month;

```

📌 Comparing the same month year over year, ADR rose consistently: July $116.59 → $129.86 → $143.92; August $121.77 → $147.37 → $164.66 — roughly 24–35% growth in peak-season rate over two years.

### Guest Geography

**Top 10 countries by booking volume and cancellation rate**

```sql
SELECT 
    country,
    COUNT(\*) AS total\_bookings\_received,
    COUNT(CASE WHEN is\_canceled = 0 THEN booking\_id END) AS confirmed\_bookings,
    COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) AS cancellations,
    ROUND(100 \* COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) / COUNT(\*), 2) AS cancellation\_rate
FROM hotel\_bookings
GROUP BY country
ORDER BY total\_bookings\_received DESC, cancellation\_rate DESC
LIMIT 10;

```

**Party size by market segment** (filtered to n ≥ 10)

```sql
SELECT 
    market\_segment,
    CASE
        WHEN total\_guests BETWEEN 1 AND 5 THEN '1-5'
        WHEN total\_guests BETWEEN 6 AND 15 THEN '6-15'
        WHEN total\_guests BETWEEN 16 AND 30 THEN '16-30'
        ELSE '31+'
    END AS party\_size,
    COUNT(\*) AS total\_bookings\_received,
    COUNT(CASE WHEN is\_canceled = 0 THEN booking\_id END) AS confirmed\_bookings,
    ROUND(100 \* COUNT(CASE WHEN is\_canceled = 0 THEN booking\_id END) / COUNT(\*), 2) AS confirmation\_rate
FROM hotel\_bookings
GROUP BY market\_segment, party\_size
HAVING total\_bookings\_received >= 10
ORDER BY confirmation\_rate DESC;

```

**Top countries by confirmed revenue**

```sql
SELECT 
    country,
    SUM(CASE WHEN is\_canceled = 0 THEN total\_revenue END) AS total\_confirmed\_revenue
FROM hotel\_bookings
GROUP BY country
ORDER BY total\_confirmed\_revenue DESC
LIMIT 10;

```

### Stay Patterns \& Room Assignment

**Average length of stay by hotel and market segment**

```sql
SELECT 
    hotel, market\_segment,
    ROUND(IFNULL(AVG(CASE WHEN is\_canceled = 0 THEN total\_nights END), 0), 2) AS avg\_length\_of\_stay
FROM hotel\_bookings
GROUP BY hotel, market\_segment;

```

**Room type mismatch rate and its relationship to cancellation**

```sql
SELECT 
    COUNT(\*) AS total\_bookings\_received,
    COUNT(CASE WHEN room\_type\_mismatch = 1 THEN booking\_id END) AS bookings\_with\_room\_mismatch,
    ROUND(100 \* COUNT(CASE WHEN room\_type\_mismatch = 1 THEN booking\_id END) / COUNT(\*), 2) AS room\_mismatch\_rate,
    COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) AS cancellations,
    ROUND(100 \* COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) / COUNT(\*), 2) AS cancellation\_rate
FROM hotel\_bookings;

-- Row-level Pearson correlation
SELECT 
    (AVG(room\_type\_mismatch \* is\_canceled) - AVG(room\_type\_mismatch) \* AVG(is\_canceled)) /
    (STDDEV\_POP(room\_type\_mismatch) \* STDDEV\_POP(is\_canceled)) AS correlation\_coefficient
FROM hotel\_bookings;

```

📌 r ≈ -0.21 (moderate negative, computed at the row level — an earlier version aggregated by date first, which inflated the coefficient to -0.60). Mismatches associate with lower cancellation; one plausible explanation is hotels resolving mismatches via complimentary upgrades for guests who show up, rather than downgrades.

### Repeat Guests \& Loyalty

**Cancellation rate: repeat vs. new guests**

```sql
SELECT 
    CASE WHEN is\_repeated\_guest = 1 THEN 'repeat\_guests' ELSE 'new\_guests' END AS guest\_type,
    COUNT(\*) AS total\_bookings\_received,
    COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) AS cancellations,
    ROUND(100 \* COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) / COUNT(\*), 2) AS cancellation\_rate
FROM hotel\_bookings
GROUP BY guest\_type;

```

📌 Repeat guests cancel significantly less often than new guests.

**ADR and booking changes: repeat vs. new guests**

```sql
SELECT 
    CASE WHEN is\_repeated\_guest = 1 THEN 'repeat\_guests' ELSE 'new\_guests' END AS guest\_type,
    ROUND(IFNULL(AVG(CASE WHEN is\_canceled = 0 THEN adr END), 0), 2) AS avg\_adr
FROM hotel\_bookings
GROUP BY guest\_type;

```

📌 New guests pay nearly 50% more on average than repeat guests. Interestingly, average booking changes remain roughly equal between the two groups.

**Do special requests correlate with lower cancellation?**

```sql
SELECT 
    total\_of\_special\_requests,
    COUNT(\*) AS total\_bookings\_received,
    COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) AS cancellations,
    ROUND(100 \* COUNT(CASE WHEN is\_canceled = 1 THEN booking\_id END) / COUNT(\*), 2) AS cancellation\_rate
FROM hotel\_bookings
GROUP BY total\_of\_special\_requests
ORDER BY cancellation\_rate;

-- Row-level Pearson correlation
SELECT 
    (AVG(total\_of\_special\_requests \* is\_canceled) - AVG(total\_of\_special\_requests) \* AVG(is\_canceled)) /
    (STDDEV\_POP(total\_of\_special\_requests) \* STDDEV\_POP(is\_canceled)) AS correlation\_coefficient
FROM hotel\_bookings;

```

📌 r ≈ -0.12 (weak-to-moderate negative, row-level — an earlier version aggregated across only 6 grouped values, which inflated the coefficient to -0.97). Direction holds: more special requests associates with lower cancellation, consistent with an "engaged guest" theory, though the true effect is moderate, not near-perfect.

**Car parking requests by customer type**

```sql
SELECT 
    customer\_type,
    ROUND(AVG(required\_car\_parking\_spaces), 2) AS avg\_parking\_space\_required
FROM hotel\_bookings
GROUP BY customer\_type;

```

Full query set: [`/SQL`](https://claude.ai/chat/SQL)

\---

## 📈 Power BI Star Schema \& Measures

The cleaned data was modeled as a proper star schema in Power BI rather than reported directly off the flat table:

**Fact table:** `fact\_bookings` — booking-level measures (lead time, ADR, revenue, guest counts, cancellation flag, etc.) plus foreign keys to each dimension.

**Dimension tables:** `dim\_date` (a full continuous calendar, marked as the model's official date table for time-intelligence support), `dim\_hotel`, `dim\_market\_segment`, `dim\_deposit\_type`, `dim\_customer\_type`, `dim\_room\_type` (a role-playing dimension, linked to both `reserved\_room\_type` and `assigned\_room\_type`, with the assigned-room relationship active by default), `dim\_country`.

**Core DAX measures:**

```dax
Total Bookings = COUNTROWS(fact\_bookings)
Confirmed Bookings = CALCULATE(\[Total Bookings], fact\_bookings\[is\_canceled] = 0)
Cancellations = CALCULATE(\[Total Bookings], fact\_bookings\[is\_canceled] = 1)
Cancellation Rate = DIVIDE(\[Cancellations], \[Total Bookings])
Total Potential Revenue = SUM(fact\_bookings\[total\_revenue])
Confirmed Revenue = CALCULATE(\[Total Potential Revenue], fact\_bookings\[is\_canceled] = 0)
Revenue at Risk = CALCULATE(\[Total Potential Revenue], fact\_bookings\[is\_canceled] = 1)
Avg ADR (Confirmed) = CALCULATE(AVERAGE(fact\_bookings\[adr]), fact\_bookings\[is\_canceled] = 0)

```

Correlation measures (special requests, room mismatch, lead time vs. ADR) were rebuilt in DAX using the same manual Pearson formula as the SQL layer (`STDEVX.P` in place of MySQL's `STDDEV\_POP`), so the dashboard's correlation callouts match the corrected, row-level SQL results exactly.

Full report file: [`/Power BI`](https://claude.ai/chat/Power%20BI)

\---

## 👤 Author

**Abiskar Shiwakoti**

Data Analyst (entry-level) | Python | SQL | Power BI

\---

## ⭐ Project Purpose

Built as a flagship portfolio project to demonstrate the full analytics workflow end to end: real-world data cleaning (not a pre-cleaned dataset), business-question-driven SQL analysis with genuine investigative follow-ups (tracing the Non-Refund anomaly back to its source), statistically careful correlation work (catching and correcting an aggregation-bias error before it reached the dashboard), and a properly normalized Power BI star schema rather than a flat single-table report.

