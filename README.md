# Predictive Customer Lifetime Value (CLV) & Churn Analytics Dashboard

## 📌 Project Overview
This project is an end-to-end Machine Learning pipeline and Interactive Business Intelligence (BI) Dashboard built in R. It leverages the **Pareto/NBD "Buy-Till-You-Die" (BTYD)** probabilistic model to forecast Customer Lifetime Value (CLV) and predict silent churn in a non-subscription e-commerce environment.

By translating complex predictive arrays into an interactive Shiny dashboard, this tool empowers marketing teams to shift from backward-looking historical metrics to proactive, forward-looking retention strategies.

## 🏢 Business Problem & Case Study
A UK-based online retail company faces a severe **"One-and-Done" purchasing trend**, where the majority of acquired customers never return. Additionally, the business suffers from **"silent churn"**—high-value customers drop off without explicitly canceling an account, making it difficult to know when to intervene. 

**Objectives:**
1. Predict the exact number of future purchases a customer will make in the next 12 weeks.
2. Calculate the exact probability ($P_{Alive}$) that a customer is still active.
3. Visually segment the customer base to identify high-value retention targets ("Whales").

## 📊 Dataset Information
* **Source:** [UCI Machine Learning Repository - Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii)
* **Description:** Transactional data for a UK-based non-store online retail company between Dec 2009 and Dec 2011.
* **Size:** Over 1 million transactional records across two years.

## 🛠️ Technology Stack
* **Language:** R
* **Machine Learning:** `CLVTools` (Pareto/NBD BTYD Model)
* **Data Processing:** `dplyr`, `lubridate`, `readxl`
* **Visualization:** `ggplot2`
* **Web UI Framework:** `shiny`, `shinydashboard`

## 🚀 Key Dashboard Features
The dashboard contains three primary tabs:
1. **Basic Metrics:** 
   * Histograms of expected future transactions.
   * Scatter plots comparing past frequency with predicted future purchases.
   * Churn Probability Density ($P_{Alive}$) distributions.
2. **Advanced Segments:**
   * **Customer Value Matrix (Log Scale):** A bubble chart plotting past spend vs. future predictions, sized by frequency and colored by $P_{Alive}$, to isolate high-value "Whale" customers on the verge of churning.
   * **Projected Future Revenue Density:** Log-scaled density plot proving the 80/20 Pareto principle in revenue reliance on active loyalists.
3. **Business Insights:** Actionable takeaways derived directly from the model's visual outputs.

## 🧠 Methodology
1. **Data Cleaning:** Removed missing Customer IDs, canceled orders (Invoices starting with 'C'), returned items (Quantity <= 0), and zero-price items.
2. **Feature Engineering:** Calculated `TotalSales`, `Past_Frequency`, `Past_Spend`, and `Avg_Order_Value`.
3. **Modeling:** Transformed data into weekly time units and trained a Pareto/NBD model.
4. **Prediction:** Generated Conditional Expected Transactions (`CET`) and Probability of Being Active (`PAlive`) for a 12-week future horizon.
5. **Dashboarding:** Merged predictions with historical metrics to drive the interactive Shiny UI.

## 💻 How to Run Locally
1. Download the dataset (`online_retail_II.xlsx`) from the UCI repository.
2. Install the required R packages:
   ```R
   install.packages(c("readxl", "dplyr", "lubridate", "CLVTools", "ggplot2", "shiny", "shinydashboard"))
   ```
3. Open the `app.R` (or `clv_churn_dashboard.R`) file in RStudio.
4. Run the data preprocessing and modeling blocks.
5. Highlight and run the `ui` and `server` blocks, or click the **"Run App"** button in RStudio to launch the dashboard.

## 💡 Key Business Insights Discovered
* **The "Whale" Identification:** High-spend, high-frequency customers with a dropping $P_{Alive}$ score require immediate VIP retention interventions.
* **The Acquisition Trap:** The model reveals that a massive portion of the customer base will make 0 future purchases, indicating a failure in post-purchase nurturing.
* **Revenue Concentration:** Projected future cash flow relies heavily on a small fraction of returning loyalists, validating the need to shift marketing budgets from acquisition to retention.