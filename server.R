library(shiny)
library(leaflet)
library(RColorBrewer)
library(dplyr)
library(ggplot2)
library(fmsb)

########## The Server Body  #############

shinyServer(function(input, output){
  
  ########### Tab1 - The Map  #############
  
  # Tab1 - Output 1 --- Interactive Map Name -----
  
  myMapName <- reactive({
    switch(input$Ratio,
           "Perceived Opportunities" = "Percentage of 18-64 population who see good opportunities to start a firm in the area where they live",
           "Perceived Capabilities" = "Percentage of 18-64 population who believe they have the required skills and knowledge to start a business",
           "Fear of Failure Rate" = "Percentage of 18-64 population who indicate that fear of failure would prevent them from setting up a business",
           "Entrepreneurial Intention" = "Percentage of 18-64 population who intend to start a business within three years")
  })
  
  output$mapname <- renderText(myMapName())
  
  # Tab1 - Output 2 --- Interactive Map ---------
  
  #  Step 1 ----- Create dynamic map inputs ----
  
  mypal <- reactive({
    colorNumeric(
      palette = switch (input$Ratio,
                        "Perceived Opportunities" = "YlOrRd",
                        "Perceived Capabilities" = "YlGn",
                        "Fear of Failure Rate" = "YlGnBu",
                        "Entrepreneurial Intention" = "RdPu"
      ),
      domain = switch (input$Ratio,
                       "Perceived Opportunities" = worldaps$Perceived.Opportunities,
                       "Perceived Capabilities" = worldaps$Perceived.Capabilities,
                       "Fear of Failure Rate" = worldaps$Fear.of.Failure.Rate,
                       "Entrepreneurial Intention" = worldaps$Entrepreneurial.Intention
      )
    )
  })
  
  myratio <- reactive({
    switch (input$Ratio,
            "Perceived Opportunities" = worldaps$Perceived.Opportunities,
            "Perceived Capabilities" = worldaps$Perceived.Capabilities,
            "Fear of Failure Rate" = worldaps$Fear.of.Failure.Rate,
            "Entrepreneurial Intention" = worldaps$Entrepreneurial.Intention
    )
  })
  
  mylegtitle <- reactive({
    switch(input$Ratio,
           "Perceived Opportunities" = "% Perceived Opportunities",
           "Perceived Capabilities" = "% Perceived Capabilities",
           "Fear of Failure Rate" = "% Fear of Failure",
           "Entrepreneurial Intention" = "% Entrepreneurial Intention"
    )
  })
  
  detail_popup <-  reactive({
    paste0("<strong> ",worldaps$Economy," </strong>",
           "<br><strong>" ,
           switch(input$Ratio,
                  "Perceived Opportunities" = "Perceived Opportunities: ",
                  "Perceived Capabilities" = "Perceived Capabilities: ",
                  "Fear of Failure Rate" = "Fear of Failure: ",
                  "Entrepreneurial Intention" = "Entrepreneurial Intention: "
           ), "</strong>",
           switch (input$Ratio,
                   "Perceived Opportunities" = worldaps$Perceived.Opportunities,
                   "Perceived Capabilities" = worldaps$Perceived.Capabilities,
                   "Fear of Failure Rate" = worldaps$Fear.of.Failure.Rate,
                   "Entrepreneurial Intention" = worldaps$Entrepreneurial.Intention
           ),
           "%"
    )
  })
  
  #  Step 2 --- Render Reactive Map -------------- 
  
  output$mymap <- renderLeaflet({
    leaflet(worldaps) %>%
      setView(lng = -64.787342, lat = 32.300140, zoom = 2) %>%
      addProviderTiles("CartoDB.Positron") %>%
      addPolygons(stroke = TRUE, weight = 3, smoothFactor = 0.2, fillOpacity = 0.7,
                  color = mypal()(myratio()), popup = detail_popup()
      ) %>%
      addLegend("bottomleft", pal = mypal(),
                values = myratio(),
                title = mylegtitle(),
                labFormat = labelFormat(suffix = "%"),
                opacity = 0.7
      )
  })

  ########### Tab2 - The Country Profile  #############
  
  # Tab2 - Output 1myRadarName --- Interactive Chart Name -----
  
  myRadarName <- reactive({
    country_selected <-  paste0(input$Country, collapse = ', ')
    paste0("Entrepreneurial Framework Condition Scores of ", 
           "<strong>",country_selected,"</strong>")
  })
  
  output$radarname <- renderUI(HTML(myRadarName()))
  
  # Tab2 - Output 2 --- Interactive Radar Chart ---------
  
  #  Step 1 ----- Create dynamic dataframe inputs ---- 
  
  myNesRadar <- reactive({
    nesRadar %>%
      filter(Economy %in% c("8", "0", input$Country))
  })
  
  COL<-reactive({
    colorRampPalette(c(1:10))(nrow(myNesRadar())-2) 
  })
  
  #  Step 2 ----- Create Radar Chart ----    
  
  output$myradar <- renderPlot({  
    radarchart(myNesRadar()[,-1], axistype = 1, seg = 8,
               plwd = 2.5, pcol = COL(), pfcol = COL(), pdensity = 4,  
               plty = 1, cglcol="orange", cglty= 3, cglwd = 2,
               axislabcol="orange", caxislabels=seq(0,8,1),
               centerzero = TRUE, vlcex=1.2, calcex = 1.2)
    
    legend(1.4, 1.25, legend = levels(as.factor(myNesRadar()$Economy[-c(1,2)])), 
           title = "Country", col = COL(), seg.len = 2, border = "transparent", pch = 16, lty = 1
    )
  })
  
  # Tab3 - Output 1 --- Interactive Rank Charts ---------
  
  Rank1table <- reactive({
    tail(arrange_(aps, input$Ratio2[1]),input$rank_)
  })

  Rank2table <- reactive({
    tail(arrange_(aps, input$Ratio2[2]),input$rank_)
  })
  
  output$Rank1 <- renderPlot({
    ggplot(data = Rank1table(),
           aes(x = reorder(Economy, desc(Rank1table()[[input$Ratio2[1]]])), 
               y = Rank1table()[[input$Ratio2[1]]]
               )
           ) +
      geom_bar(stat = "identity", aes(fill = Economy)) +
      theme(axis.text.x=element_blank()) +
      labs(x = "Country", y = input$Ratio2[1])
  })
  
  output$Rank2 <- renderPlot({
    ggplot(data = Rank2table(),
           aes(x = reorder(Economy, desc(Rank2table()[[input$Ratio2[2]]])), 
               y = Rank2table()[[input$Ratio2[2]]]
           )
           ) +
      geom_bar(stat = "identity", aes(fill = Economy)) +
      theme(axis.text.x=element_blank()) +
      labs(x = "Country", y = input$Ratio2[2]) 
  })
  
  
  # Tab4 - Output 1 --- Data Tables ---------
  output$nesTable <- DT::renderDataTable(nes, options = list(scrollX = TRUE))
  
  output$apsTable <- DT::renderDataTable(aps, options = list(scrollX = TRUE))
  
})
