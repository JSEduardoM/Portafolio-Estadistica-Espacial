# =============================================================================
# ANÁLISIS ESPACIAL ENA - VARIABLES 224B, 224D, 224E
# =============================================================================

# 1. Cargar librerías necesarias
library(haven)
library(dplyr)
library(sf)
library(ggplot2)
library(viridis)
library(rnaturalearth)

# Definir ruta del archivo
archivo_sav <- "c:/Users/User/Documents/SEMESTRE X/ESTADISTICA ESPACIAL/DATOS/ENA_2014_2024.sav"

cat("Iniciando extracción de datos (esto puede tardar debido al tamaño del archivo)...\n")

# 2. Leer selectivamente las columnas para optimizar memoria (14GB es mucho)
# Seleccionamos: Geo (Long/Lat, Dep), Cultivo (224B), Superficie (224D), Motivo (224E)
columnas_interes <- c(
  "LONGITUD", "LATITUD", "P102C_DEP", 
  "P224B_NOM", 
  "P224D_SUP_1", "P224D_SUP_2",
  "P224E_1", "P224E_2", "P224E_3", "P224E_4", "P224E_5", "P224E_6", "P224E_7"
)

# Leemos solo las columnas necesarias
# Usamos encoding 'latin1' para evitar errores de caracteres especiales en etiquetas
data_subset <- read_sav(archivo_sav, col_select = all_of(columnas_interes), encoding = "latin1")

cat("Datos leídos. Filtrando registros con pérdida total...\n")

# 3. Procesamiento y Limpieza (Convertir a numérico explícitamente)
data_proc <- data_subset %>%
  # Limpiar tipos de datos (algunos vienen como haven_labelled)
  mutate(across(everything(), zap_labels)) %>% 
  mutate(across(c(LONGITUD, LATITUD, P224D_SUP_1, P224D_SUP_2), as.numeric)) %>%
  # Filtrar filas que tengan coordenadas y que tengan algún dato en superficie (indicando pérdida)
  filter(!is.na(LONGITUD), !is.na(LATITUD), !is.na(P224D_SUP_1)) %>%
  mutate(
    # Calcular superficie total (Entero + Decimal/100)
    # Usamos coalesce para tratar los decimales ausentes como 0
    superficie_total = P224D_SUP_1 + (coalesce(P224D_SUP_2, 0) / 100),
    # Convertir Departamento a factor para mejor visualización
    departamento = as_factor(P102C_DEP),
    cultivo = as_factor(P224B_NOM)
  )

cat("Calculando estadísticas generales...\n")

# 4. Estadísticas (Cálculo de promedios y resúmenes)
resumen_nacional <- data_proc %>%
  summarise(
    total_registros = n(),
    promedio_superficie = mean(superficie_total, na.rm = TRUE),
    max_superficie = max(superficie_total, na.rm = TRUE)
  )

resumen_depto <- data_proc %>%
  group_by(departamento) %>%
  summarise(
    n = n(),
    promedio_sup = mean(superficie_total, na.rm = TRUE)
  ) %>%
  arrange(desc(promedio_sup))

print("--- RESUMEN NACIONAL ---")
print(resumen_nacional)
print("--- TOP 5 DEPARTAMENTOS POR SUPERFICIE PROMEDIO PERDIDA ---")
print(head(resumen_depto, 5))

# 5. Visualización de Mapas
cat("Generando mapa...\n")

# Obtener mapa base de Perú
peru <- ne_countries(scale = "medium", returnclass = "sf", country = "Peru")

# Convertir datos de ENA a objeto espacial
puntos_sf <- st_as_sf(data_proc, coords = c("LONGITUD", "LATITUD"), crs = 4326)

# Crear el mapa
mapa <- ggplot() +
  geom_sf(data = peru, fill = "#f2f2f2", color = "gray60") +
  geom_sf(data = puntos_sf, aes(color = superficie_total, size = superficie_total), alpha = 0.6) +
  scale_color_viridis_c(option = "plasma", name = "Superficie Perdida\n(Hectáreas)") +
  scale_size_continuous(range = c(1, 6), guide = "none") +
  theme_minimal() +
  labs(
    title = "Mapas de Pérdida Total de Producción (ENA)",
    subtitle = "Visualización basada en variables 224B, 224D y 224E",
    caption = "Fuente: Encuesta Nacional Agropecuaria (ENA) 2014-2024",
    x = "Longitud", y = "Latitud"
  ) +
  theme(
    panel.grid.major = element_line(color = "white"),
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "right"
  )

# Guardar el mapa
ggsave("mapa_ena_perdidas.png", plot = mapa, width = 10, height = 12, dpi = 300)

cat("Mapa guardado como 'mapa_ena_perdidas.png'\n")

# 6. Estadística en un punto geográfico (Ejemplo: el punto con mayor pérdida)
punto_max <- data_proc %>% arrange(desc(superficie_total)) %>% head(1)

cat("\n--- ESTADÍSTICA EN UN PUNTO GEOGRÁFICO ESPECÍFICO (Máxima pérdida) ---\n")
cat("Ubicación:", punto_max$LONGITUD, ",", punto_max$LATITUD, "\n")
cat("Departamento:", as.character(punto_max$departamento), "\n")
cat("Cultivo afectado (224B):", as.character(punto_max$cultivo), "\n")
cat("Superficie perdida (224D):", punto_max$superficie_total, "ha\n")

# Motivos de pérdida (224E)
cat("Motivos reportados (224E):\n")
if(punto_max$P224E_1 == 1) cat("- Huaycos/Deslizamientos\n")
if(punto_max$P224E_2 == 1) cat("- Inundaciones\n")
if(punto_max$P224E_3 == 1) cat("- Plagas/Enfermedades\n")
if(punto_max$P224E_4 == 1) cat("- Heladas\n")
if(punto_max$P224E_5 == 1) cat("- Granizada\n")
if(punto_max$P224E_6 == 1) cat("- Sequía\n")
if(punto_max$P224E_7 == 1) cat("- Otros\n")
