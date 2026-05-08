# =============================================================================
# PASO 3: VISUALIZACIÓN ESPACIAL (MAPAS)
# =============================================================================
library(sf)
library(ggplot2)
library(viridis)
library(rnaturalearth)

archivo_rds <- "c:/Users/User/Documents/SEMESTRE X/ESTADISTICA ESPACIAL/DATOS/ena_subset.rds"

if(!file.exists(archivo_rds)) stop("ERROR: No se encuentra el subset. Corra el Paso 1.")

data <- readRDS(archivo_rds)

cat(">>> CARGANDO CARTOGRAFÍA Y GENERANDO MAPA...\n")

# Obtener límites de Perú
peru <- ne_countries(scale = "medium", returnclass = "sf", country = "Peru")

# Convertir datos a objeto espacial (Puntos)
puntos_sf <- st_as_sf(data, coords = c("LONGITUD", "LATITUD"), crs = 4326)

# Crear mapa de puntos coloreados por superficie perdida
mapa <- ggplot() +
  geom_sf(data = peru, fill = "#fcfcfc", color = "gray80") +
  geom_sf(data = puntos_sf, aes(color = superficie_total, size = superficie_total), alpha = 0.6) +
  scale_color_viridis_c(option = "magma", name = "Superficie Perdida\n(Hectáreas)") +
  scale_size_continuous(range = c(1, 5), guide = "none") +
  theme_minimal() +
  labs(
    title = "Mapa de Pérdida de Producción Agrícola en Perú",
    subtitle = "Basado en variables ENA (224B, 224D, 224E)",
    x = "Longitud", y = "Latitud",
    caption = "Fuente: Encuesta Nacional Agropecuaria (ENA) 2014-2024"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    panel.background = element_rect(fill = "aliceblue")
  )

# Guardar en alta resolución
ggsave("c:/Users/User/Documents/SEMESTRE X/ESTADISTICA ESPACIAL/DATOS/mapa_ena_perdidas.png", 
       plot = mapa, width = 10, height = 12, dpi = 300)

cat(">>> MAPA EXPORTADO CON ÉXITO: mapa_ena_perdidas.png\n")
