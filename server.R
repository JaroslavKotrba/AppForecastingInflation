# server
server <- function(input, output) {
  options(scipen=999)
  make_result <- function(x, y, z) {as.numeric(x)*(1+ (-as.numeric(y)/(1+as.numeric(y))) )^as.numeric(z)}
  output$result <- renderText({paste0(round(make_result(input$select_amount, input$select_rate, input$select_year), 2), " CZK")
  })
  
  output$difference <- renderText({ paste0(round(make_result(input$select_amount, input$select_rate, input$select_year), 2) - input$select_amount, " CZK")
  })
  
  output$percentage <- renderText({ paste0(round(((make_result(input$select_amount, input$select_rate, input$select_year)
                                                   /(input$select_amount/100)))-100, 2), " %")
  })
  
  output$years <- renderPlot({
    z_all <- 1:100
    t <- input$select_amount*(1+ (-as.numeric(input$select_rate)/(1+as.numeric(input$select_rate))) )^z_all
    plot(t, type = "l", lwd = 2, col = "red", main = "Inflation over 100 years on your amount", xlab = "Years", ylab = "Amount in CZK")
  })
  
  # CZECH INFLATION
  library(rvest)
  library(dplyr)
  library(forecast)
  library(tseries)
  library(curl)
  
  link <- "https://www.czso.cz/csu/czso/mira_inflace"
  inf <- curl::curl(link) %>% read_html()
  
  inf_table <- inf %>% html_nodes("table") %>% .[2] %>% 
    html_table(fill = TRUE) %>% .[[1]]
  
  inf_table <- inf_table[33:60,2:13] # update
  inf_vector <- as.vector(t(inf_table))
  inf_vector <- as.numeric(gsub(",", ".", inf_vector))
  
  output$inflation <- renderPlot ({
    Inflation <- ts(inf_vector, start = c(1997, 1),frequency = 12) # year month
    plot(Inflation, lwd = 2, col = "red", main = "Inflation in the Czech Republic")
  })
  
  output$current <- renderTable ({
    Inflation <- ts(inf_vector, start = c(1997, 1),frequency = 12) # ts
    dmn <- list(month.abb, unique(floor(time(Inflation)))) # df
    current <- as.data.frame(t(matrix(Inflation, 12, dimnames = dmn))) # df
    current <- cbind(Year = rownames(current), current) # index
    rownames(current) <- 1:nrow(current) # index
    current
  })
  
  output$arima <- renderPlot ({
    Inflation <- ts(inf_vector, start = c(1997, 1),frequency = 12) # pred
    Inflation <- na.remove(Inflation)
    arima <- Arima(Inflation, 
                   order = c(1,1,1), 
                   seasonal = c(0,0,2))
    arima <- forecast(arima, h = input$select_month, level=c(0,0))
    plot(arima, lwd = 2, xlab = "Time", ylab = "Inflation")
  })
  
  output$ann <- renderPlot({
    Inflation <- ts(inf_vector, start = c(1997, 1),frequency = 12) # pred
    Inflation <- na.remove(Inflation) 
    fit <- nnetar(Inflation)
    ann <- forecast(fit, h = input$select_month, PI = F) # interval confidence
    plot(ann, lwd = 2, xlab = "Time", ylab = "Inflation")
  })
  
  url <- a("https://www.czso.cz/csu/czso/mira_inflace", href="https://www.czso.cz/csu/czso/mira_inflace")
  output$link <- renderUI({
    tagList("Source:", url)
  })
}
