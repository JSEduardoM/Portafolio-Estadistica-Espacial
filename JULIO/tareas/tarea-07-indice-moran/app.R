library(shiny)
library(leaflet)
library(sf)
library(spdep)
library(dplyr)
library(haven)
library(stringr)
library(geodata)
library(classInt)
library(ggplot2)

# --- CONFIGURACIÓN GLOBAL Y CARGA DE DATOS ---

# 1. Obtener polígonos de Perú
# Descarga o carga los polígonos si no están en cache
peru_poligonos <- gadm("PER", level = 1, path = tempdir())
peru_sf <- st_as_sf(peru_poligonos)

# Limpieza de nombres de departamentos para cruzar
peru_sf <- peru_sf %>%
  mutate(NAME_1 = toupper(NAME_1)) %>%
  mutate(NAME_1 = case_when(
    grepl("APURÍMAC", NAME_1) ~ "APURIMAC",
    grepl("HUÁNUCO", NAME_1) ~ "HUANUCO",
    grepl("JUNÍN", NAME_1) ~ "JUNIN",
    grepl("SAN MARTÍN", NAME_1) ~ "SAN MARTIN",
    TRUE ~ NAME_1
  ))

# Matriz de vecinos espaciales para Perú (K-vecinos para evitar islas sin conexión)
coords_peru <- st_coordinates(st_centroid(st_geometry(peru_sf)))
knn_peru <- knn2nb(knearneigh(coords_peru, k = 4))
listw_peru <- nb2listw(knn_peru, style = "W", zero.policy = TRUE)

# 2. Cargar datos Carolina del Norte (sf)
nc_sf <- st_read(system.file("shape/nc.shp", package="sf")[1], quiet = TRUE)
# Matriz de vecinos espaciales para NC (Queen)
nb_nc <- poly2nb(nc_sf)
listw_nc <- nb2listw(nb_nc, style = "W", zero.policy = TRUE)

# 3. Función para cargar y procesar datos ENA según producto
cargar_ena_producto <- function(producto_nombre) {
  # Cargar base preprocesada (súper rápido)
  ruta_resumen <- "datos_ena_resumen.rds"
  
  if (!file.exists(ruta_resumen)) {
    stop("Falta ejecutar el script preprocesar_ena.R para generar los datos resumidos.")
  }
  
  datos <- readRDS(ruta_resumen)
  
  # Filtrar producto
  resumen <- datos %>%
    filter(Producto == producto_nombre)
    
  # Unir con polígonos
  mapa_datos <- peru_sf %>%
    left_join(resumen, by = c("NAME_1" = "NOMBREDD")) %>%
    mutate(Valor = ifelse(is.na(Valor), 0, Valor)) # Rellenar NA con 0 para análisis espacial completo
    
  return(mapa_datos)
}

# --- UI ---
ui <- fluidPage(
  titlePanel("Índice de Moran: Análisis Espacial (Tarea 07)"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Selección de Dataset"),
      selectInput("dataset_selector", "Elige un conjunto de datos:",
                  choices = c(
                    "Dataset Clásico: Carolina del Norte (SIDS)" = "NC",
                    "ENA - Producción de Papa" = "PAPA",
                    "ENA - Producción de Café" = "CAFE",
                    "ENA - Producción de Maíz" = "MAIZ"
                  ),
                  selected = "NC"),
      hr(),
      p("Esta aplicación permite evidenciar el Índice de Moran Global y Local usando múltiples conjuntos de datos espaciales."),
      p("El Índice de Moran mide la autocorrelación espacial de una variable.")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Mapa de la Variable", leafletOutput("mapa_variable", height = 600)),
        tabPanel("Moran Global", 
                 h3("Resultados del Test de Moran Global"),
                 verbatimTextOutput("moran_test"),
                 h4("Diagrama de Dispersión de Moran (Moran Scatterplot)"),
                 plotOutput("moran_plot")
        ),
        tabPanel("Moran Local (LISA)", 
                 h3("Mapa de Clústers (LISA)"),
                 leafletOutput("mapa_lisa", height = 600),
                 p("Leyenda de Clústers:"),
                 tags$ul(
                   tags$li("High-High: Altos valores rodeados de altos valores."),
                   tags$li("Low-Low: Bajos valores rodeados de bajos valores."),
                   tags$li("High-Low: Altos valores rodeados de bajos valores."),
                   tags$li("Low-High: Bajos valores rodeados de altos valores."),
                   tags$li("Not Significant: Sin autocorrelación espacial significativa.")
                 )
        )
      )
    )
  )
)

# --- SERVER ---
server <- function(input, output, session) {
  
  # Reactive para cargar datos según selección
  datos_reactivos <- reactive({
    showNotification("Cargando datos espaciales...", duration = 3, id = "cargando_msg")
    
    if (input$dataset_selector == "NC") {
      # Retorna NC y su variable SID74
      return(list(
        sf = nc_sf,
        var = nc_sf$SID74,
        var_name = "SID74",
        listw = listw_nc,
        label_col = "NAME"
      ))
    } else {
      # Carga datos ENA según producto
      df_sf <- cargar_ena_producto(input$dataset_selector)
      return(list(
        sf = df_sf,
        var = df_sf$Valor,
        var_name = paste("Producción de", input$dataset_selector),
        listw = listw_peru,
        label_col = "NAME_1"
      ))
    }
  })
  
  # Render Mapa Variable
  output$mapa_variable <- renderLeaflet({
    d <- datos_reactivos()
    sf_data <- d$sf
    variable <- d$var
    
    # Jenks breaks
    brks <- classIntervals(variable, n = 5, style = "jenks")$brks
    pal <- colorBin("YlOrRd", domain = variable, bins = brks, na.color = "transparent")
    
    leaflet(sf_data) %>%
      addTiles() %>%
      addPolygons(
        fillColor = ~pal(variable),
        weight = 1,
        opacity = 1,
        color = "white",
        dashArray = "3",
        fillOpacity = 0.7,
        highlightOptions = highlightOptions(weight = 3, color = "#666", dashArray = "", fillOpacity = 0.7, bringToFront = TRUE),
        label = ~paste0(sf_data[[d$label_col]], ": ", round(variable, 2)),
        labelOptions = labelOptions(style = list("font-weight" = "normal", padding = "3px 8px"), textsize = "15px", direction = "auto")
      ) %>%
      addLegend(pal = pal, values = variable, opacity = 0.7, title = d$var_name, position = "bottomright")
  })
  
  # Render Moran Global Test
  output$moran_test <- renderPrint({
    d <- datos_reactivos()
    test <- moran.test(d$var, d$listw, zero.policy = TRUE)
    print(test)
  })
  
  # Render Moran Plot
  output$moran_plot <- renderPlot({
    d <- datos_reactivos()
    # Escalar la variable
    var_scaled <- scale(d$var)
    # Calcular rezago espacial (spatial lag)
    var_lag <- lag.listw(d$listw, var_scaled, zero.policy = TRUE)
    
    df_plot <- data.frame(Variable = as.numeric(var_scaled), Lag = as.numeric(var_lag))
    
    ggplot(df_plot, aes(x = Variable, y = Lag)) +
      geom_point(color = "blue", size = 2) +
      geom_smooth(method = "lm", se = FALSE, color = "red", linetype = "dashed") +
      geom_hline(yintercept = 0, linetype = "dotted") +
      geom_vline(xintercept = 0, linetype = "dotted") +
      labs(x = paste(d$var_name, "(Estandarizado)"), y = paste("Rezago Espacial de", d$var_name),
           title = paste("Moran Scatterplot para", d$var_name)) +
      theme_minimal()
  })
  
  # Render Moran Local (LISA)
  output$mapa_lisa <- renderLeaflet({
    d <- datos_reactivos()
    sf_data <- d$sf
    variable <- d$var
    listw <- d$listw
    
    # Calcular Moran Local
    local_m <- localmoran(variable, listw, zero.policy = TRUE)
    
    # Clasificación LISA (Quadrants)
    var_scaled <- as.numeric(scale(variable))
    lag_var <- as.numeric(lag.listw(listw, var_scaled, zero.policy = TRUE))
    
    p_values <- local_m[, 5] # P-value (Pr(z > 0) o Pr(z != 0) según versión de spdep, index 5 es común)
    significance_level <- 0.05
    
    # Determinar cuadrantes
    quadrant <- rep("Not Significant", length(variable))
    quadrant[var_scaled > 0 & lag_var > 0 & p_values <= significance_level] <- "High-High"
    quadrant[var_scaled < 0 & lag_var < 0 & p_values <= significance_level] <- "Low-Low"
    quadrant[var_scaled > 0 & lag_var < 0 & p_values <= significance_level] <- "High-Low"
    quadrant[var_scaled < 0 & lag_var > 0 & p_values <= significance_level] <- "Low-High"
    
    # Asignar colores a los cuadrantes
    lisa_colors <- c("High-High" = "red", "Low-Low" = "blue", 
                     "High-Low" = "pink", "Low-High" = "lightblue", 
                     "Not Significant" = "white")
                     
    sf_data$LISA <- factor(quadrant, levels = names(lisa_colors))
    
    pal_lisa <- colorFactor(palette = lisa_colors, domain = sf_data$LISA)
    
    leaflet(sf_data) %>%
      addTiles() %>%
      addPolygons(
        fillColor = ~pal_lisa(LISA),
        weight = 1,
        opacity = 1,
        color = "gray",
        dashArray = "3",
        fillOpacity = 0.8,
        highlightOptions = highlightOptions(weight = 3, color = "#333", dashArray = "", fillOpacity = 0.9, bringToFront = TRUE),
        label = ~paste0(sf_data[[d$label_col]], " - Clúster: ", LISA),
        labelOptions = labelOptions(style = list("font-weight" = "normal", padding = "3px 8px"), textsize = "15px", direction = "auto")
      ) %>%
      addLegend(pal = pal_lisa, values = sf_data$LISA, opacity = 0.8, title = "Clústers LISA", position = "bottomright")
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
