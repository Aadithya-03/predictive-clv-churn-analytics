# ==============================================================================
# PROFESSIONAL CLV & CHURN ANALYTICS PIPELINE & DASHBOARD (app.R)
# ==============================================================================

# ------------------------------------------------------------------------------
# STEP 1: LOAD LIBRARIES
# ------------------------------------------------------------------------------
library(readxl)
library(dplyr)
library(lubridate)
library(CLVTools)
library(ggplot2)
library(shiny)
library(shinydashboard)
library(scales)

# ------------------------------------------------------------------------------
# STEP 2: DATA INGESTION & CLEANING
# ------------------------------------------------------------------------------
print("Please select the 'online_retail_II.xlsx' file...")
file_path <- file.choose()

print("Reading local Excel sheets into R (This may take a minute)...")
sheet1 <- read_excel(file_path, sheet = "Year 2009-2010")
sheet2 <- read_excel(file_path, sheet = "Year 2010-2011")

# Combine the two years of data into one dataframe
raw_data <- bind_rows(sheet1, sheet2)

print("Cleaning data...")
clean_df <- raw_data %>%
  rename(CustomerID = `Customer ID`) %>% 
  filter(
    !is.na(CustomerID),               # Drop rows with no customer ID
    Quantity > 0,                     # Drop returned items
    Price > 0,                        # Drop zero-price items
    !grepl("^C", Invoice)             # Drop cancelled invoices
  ) %>%
  mutate(
    InvoiceDate = as.Date(InvoiceDate),
    TotalSales = Quantity * Price     # Calculate total spend per item
  )

print(paste("Data ready. Total valid transactions:", nrow(clean_df)))

# ------------------------------------------------------------------------------
# STEP 3: MACHINE LEARNING MODEL (Pareto/NBD)
# ------------------------------------------------------------------------------
print("Formatting data for CLV algorithm...")
clv_data <- clvdata(data.transactions = clean_df,
                    date.format = "ymd",
                    time.unit = "weeks",
                    name.id = "CustomerID",
                    name.date = "InvoiceDate",
                    name.price = "TotalSales")

print("Training the model (this may take a few seconds)...")
pnbd_model <- pnbd(clv.data = clv_data)

print("Generating predictions for the next 12 weeks...")
predictions <- predict(pnbd_model, prediction.end = 12)

# ------------------------------------------------------------------------------
# STEP 4: ADVANCED METRICS & DATA MERGING
# ------------------------------------------------------------------------------
print("Calculating advanced metrics for the dashboard...")
model_results <- clean_df %>%
  group_by(CustomerID) %>%
  summarise(Past_Frequency = n() - 1,
            Past_Spend = sum(TotalSales)) %>%
  mutate(CustomerID = as.character(CustomerID)) %>% 
  inner_join(predictions, by = c("CustomerID" = "Id")) %>%
  mutate(
    Customer_Status = ifelse(PAlive > 0.5, "Active Loyalist", "Likely Churned"),
    Avg_Order_Value = ifelse(Past_Frequency > 0, Past_Spend / Past_Frequency, Past_Spend),
    Projected_Revenue = CET * Avg_Order_Value
  ) %>%
  filter(Past_Spend > 0, Projected_Revenue > 0) # Clean out anomalies for log-scale plotting

print("Pipeline complete! Launching the interactive dashboard...")

# ------------------------------------------------------------------------------
# STEP 5: DASHBOARD UI (Frontend)
# ------------------------------------------------------------------------------
ui <- dashboardPage(
  skin = "blue", 
  
  dashboardHeader(title = "CLV & Retention AI"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Executive Dashboard", tabName = "dashboard", icon = icon("chart-line")),
      menuItem("Strategic Insights", tabName = "insights", icon = icon("lightbulb"))
    ),
    
    hr(), 
    
    # UI FILTER PANEL
    div(style = "padding: 10px 15px;", 
        h4("Control Panel", style = "color: #b8c7ce; font-weight: bold;"),
        p("Use filters to segment the audience.", style = "color: #8aa4af; font-size: 12px;")
    ),
    
    checkboxGroupInput("status_filter", "1. Customer Segment:",
                       choices = c("Active Loyalist", "Likely Churned"),
                       selected = c("Active Loyalist", "Likely Churned")),
    
    sliderInput("palive_filter", "2. Minimum P(Alive) Score:",
                min = 0, max = 1, value = 0, step = 0.05),
    
    sliderInput("spend_filter", "3. Minimum Past Spend (£):",
                min = 0, max = 5000, value = 0, step = 100, pre = "£")
  ),
  
  dashboardBody(
    # Custom CSS for a Premium SaaS Look
    tags$head(tags$style(HTML("
      @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');
      
      body, h1, h2, h3, h4, h5, h6 { font-family: 'Inter', sans-serif !important; }
      .content-wrapper, .right-side { background-color: #f8fafc; }
      
      .skin-blue .main-header .logo { background-color: #0f172a; font-weight: 700; letter-spacing: 0.5px; }
      .skin-blue .main-header .logo:hover { background-color: #1e293b; }
      .skin-blue .main-header .navbar { background-color: #1e293b; }
      
      .skin-blue .main-sidebar { background-color: #0f172a; }
      .skin-blue .sidebar-menu > li.active > a, 
      .skin-blue .sidebar-menu > li:hover > a { 
        border-left-color: #3b82f6; 
        background-color: #1e293b; 
        color: #ffffff;
      }
      
      .small-box { border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); transition: transform 0.2s; }
      .small-box:hover { transform: translateY(-5px); box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1); }
      .small-box h3 { font-weight: 700; }
      
      .box { border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); border-top: none !important; }
      .box-header { border-bottom: 1px solid #f1f5f9; padding: 15px; }
      .box-title { font-weight: 600; color: #334155; }
      
      .irs-bar, .irs-bar-edge { background: #3b82f6 !important; border: #3b82f6 !important; }
      .irs-single, .irs-from, .irs-to { background: #0f172a !important; }
    "))),
    
    tabItems(
      # DASHBOARD TAB
      tabItem(tabName = "dashboard",
              fluidRow(
                valueBoxOutput("kpi_customers", width = 4),
                valueBoxOutput("kpi_revenue", width = 4),
                valueBoxOutput("kpi_avg_palive", width = 4)
              ),
              fluidRow(
                box(title = "Customer Value Matrix (Whale Finder)", status = "info", width = 8, solidHeader = TRUE,
                    plotOutput("plot_matrix", height = 350)),
                box(title = "Future Purchase Volume", status = "primary", width = 4, solidHeader = TRUE,
                    plotOutput("plot_hist", height = 350))
              ),
              fluidRow(
                box(title = "Revenue Dependency by Segment", status = "warning", width = 6, solidHeader = TRUE,
                    plotOutput("plot_revenue_density", height = 300)),
                box(title = "P(Alive) Health Distribution", status = "danger", width = 6, solidHeader = TRUE,
                    plotOutput("plot_palive_density", height = 300))
              )
      ),
      
      # INSIGHTS TAB
      tabItem(tabName = "insights",
              fluidRow(
                box(title = "How to use the Control Panel", status = "primary", width = 12, solidHeader = TRUE,
                    h4("Targeting 'At-Risk Whales'"),
                    p("To find your most valuable customers who are about to leave: Uncheck 'Active Loyalist' in the sidebar, and drag the 'Minimum Past Spend' slider up to £1,000. The dashboard will instantly isolate high-value churners for your marketing team."),
                    h4("Validating Loyalists"),
                    p("Set the 'Minimum P(Alive)' slider to 0.80. Watch the Projected Future Revenue KPI to see exactly how much cash flow is guaranteed by your safest, most loyal customers.")
                )
              )
      )
    )
  )
)

# ------------------------------------------------------------------------------
# STEP 6: DASHBOARD SERVER LOGIC (Backend)
# ------------------------------------------------------------------------------
server <- function(input, output) {
  
  # Reactive dataframe listening to UI filters
  filtered_data <- reactive({
    model_results %>%
      filter(Customer_Status %in% input$status_filter) %>%
      filter(PAlive >= input$palive_filter) %>%
      filter(Past_Spend >= input$spend_filter)
  })
  
  # KPI Boxes
  output$kpi_customers <- renderValueBox({
    val <- nrow(filtered_data())
    valueBox(comma(val), "Customers in View", icon = icon("users"), color = "light-blue")
  })
  
  output$kpi_revenue <- renderValueBox({
    val <- sum(filtered_data()$Projected_Revenue, na.rm = TRUE)
    valueBox(dollar(val, prefix = "£"), "Projected Revenue (12 Wks)", icon = icon("credit-card"), color = "green")
  })
  
  output$kpi_avg_palive <- renderValueBox({
    val <- mean(filtered_data()$PAlive, na.rm = TRUE)
    box_color <- ifelse(val > 0.5, "olive", "red") 
    valueBox(percent(val, accuracy = 0.1), "Avg Active Probability", icon = icon("heartbeat"), color = box_color)
  })
  
  # Dynamic Plots
  output$plot_matrix <- renderPlot({
    req(nrow(filtered_data()) > 0) 
    ggplot(filtered_data(), aes(x = Past_Spend, y = CET, size = Past_Frequency, color = PAlive)) +
      geom_point(alpha = 0.7) +
      scale_x_log10(labels = dollar_format(prefix = "£")) + 
      scale_color_gradient(low = "#e74c3c", high = "#2ecc71") +
      labs(x = "Total Past Spend (Log Scale)", y = "Predicted Future Purchases", color = "P(Alive)", size = "Past Freq") +
      theme_minimal(base_size = 14) + theme(legend.position = "right")
  })
  
  output$plot_hist <- renderPlot({
    req(nrow(filtered_data()) > 0)
    ggplot(filtered_data(), aes(x = CET)) +
      geom_histogram(binwidth = 0.5, fill = "#3b82f6", color = "white") +
      coord_cartesian(xlim = c(0, 15)) +
      labs(x = "Predicted Purchases", y = "Count") +
      theme_minimal(base_size = 14)
  })
  
  output$plot_revenue_density <- renderPlot({
    req(nrow(filtered_data()) > 0)
    ggplot(filtered_data(), aes(x = Projected_Revenue, fill = Customer_Status)) +
      geom_density(alpha = 0.7, color = "transparent") +
      scale_x_log10(labels = dollar_format(prefix = "£")) +
      scale_fill_manual(values = c("Active Loyalist" = "#2ecc71", "Likely Churned" = "#e74c3c")) +
      labs(x = "Projected Future Revenue (Log Scale)", y = "Density", fill = "") +
      theme_minimal(base_size = 14) + theme(legend.position = "top")
  })
  
  output$plot_palive_density <- renderPlot({
    req(nrow(filtered_data()) > 0)
    ggplot(filtered_data(), aes(x = PAlive, fill = Customer_Status)) +
      geom_histogram(binwidth = 0.05, alpha = 0.8, color = "white") +
      scale_fill_manual(values = c("Active Loyalist" = "#2ecc71", "Likely Churned" = "#e74c3c")) +
      geom_vline(xintercept = 0.5, linetype = "dashed", color = "black", linewidth = 1) +
      labs(x = "P(Alive) Score", y = "Count", fill = "") +
      theme_minimal(base_size = 14) + theme(legend.position = "top")
  })
}

# ------------------------------------------------------------------------------
# STEP 7: LAUNCH APP
# ------------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
