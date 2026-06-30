# Data Dictionary — Sales Performance Analytics

## `sales_raw.csv` / `sales_cleaned.csv`

| Column | Type | Description |
|---|---|---|
| `order_id` | string | Unique order identifier, format `ORD-#####` |
| `order_date` | date | Date the order was placed |
| `ship_date` | date | Date the order shipped |
| `year` | int | Year extracted from `order_date` |
| `quarter` | string | Fiscal quarter (`Q1`–`Q4`) |
| `month` | int | Month number (1–12) |
| `month_name` | string | Full month name |
| `customer_name` | string | Customer / company name |
| `customer_segment` | string | One of: Enterprise, Mid-Market, SMB, Startup |
| `region` | string | Sales region: North, South, East, West, Central |
| `city` | string | City within the region |
| `sales_rep` | string | Assigned sales representative |
| `product_name` | string | Product sold |
| `product_category` | string | One of: Electronics, Software, Office Supplies, Accessories |
| `quantity` | int | Units sold in the order |
| `unit_price` | float | List price per unit (before discount), in ₹ |
| `discount_pct` | float | Discount applied, as a percentage |
| `unit_revenue` | float | Net price per unit after discount, in ₹ |
| `unit_cost` | float | Cost of goods per unit, in ₹ |
| `revenue` | float | Total order revenue (`unit_revenue × quantity`), in ₹ |
| `cogs` | float | Total cost of goods sold, in ₹ |
| `gross_profit` | float | `revenue − cogs`, in ₹ |
| `margin_pct` | float | Gross margin percentage (`gross_profit / revenue × 100`) |
| `shipping_days` | int | Days between order and shipment |
| `order_status` | string | Completed, Returned, or Cancelled |
| `sales_channel` | string | Direct, Online, Partner, Referral, or Email Campaign |
| `payment_method` | string | Credit Card, Bank Transfer, UPI, Cheque, or Net Banking |
| `customer_rating` | float | Post-purchase rating (1.0–5.0), null for non-completed orders |

## Derived Summary Files (`data/processed/`)

- **`regional_summary.csv`** — orders, revenue, profit, avg margin, and avg rating grouped by region
- **`product_summary.csv`** — units sold, revenue, profit, margin grouped by category and product
- **`monthly_trend.csv`** — monthly orders, revenue, and profit time series
- **`rep_leaderboard.csv`** — orders, revenue, profit, margin, and rating grouped by sales rep and region

## Business Logic Notes

- Only orders with `order_status = 'Completed'` are used in profit/margin analysis; Returned and Cancelled orders are excluded from `sales_cleaned.csv` but retained in `sales_raw.csv` for operational analysis (e.g. return rate by product).
- `margin_pct` is calculated per-order, not as a blended company-wide figure, so averaging it across groups gives the *average order margin*, not the *aggregate margin* (which would be `SUM(gross_profit) / SUM(revenue)`). Both are used appropriately throughout the analysis.
- Seasonal pricing variation (Q4 uplift, Q1 softness) is built into the synthetic data generator to simulate realistic festive/seasonal demand patterns.
