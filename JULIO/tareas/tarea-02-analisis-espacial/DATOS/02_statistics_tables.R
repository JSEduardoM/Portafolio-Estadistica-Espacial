# =============================================================================
# PASO 2: ANÁLISIS ESTADÍSTICO DE PÉRDIDAS
# =============================================================================
library(dplyr)
library(tidyr)

archivo_rds <- "c:/Users/User/Documents/SEMESTRE X/ESTADISTICA ESPACIAL/DATOS/ena_subset.rds"

if(!file.exists(archivo_rds)) stop("ERROR: No se encuentra el subset. Corra el Paso 1.")

data <- readRDS(archivo_rds)

cat(">>> CALCULANDO RESÚMENES ESTADÍSTICOS...\n")

# 1. Promedio de superficie (224D)
resumen_general <- data %>%
  summarise(
    Casos_Totales = n(),
    Superficie_Promedio_Ha = mean(superficie_total, na.rm = TRUE),
    Superficie_Maxima_Ha = max(superficie_total, na.rm = TRUE)
  )

print("--- ESTADÍSTICA GENERAL (224D) ---")
print(resumen_general)

# 2. Resumen por Cultivo (224B)
resumen_cultivo <- data %>%
  group_by(cultivo) %>%
  summarise(
    N = n(),
    Suma_Ha = sum(superficie_total, na.rm = TRUE),
    Promedio_Ha = mean(superficie_total, na.rm = TRUE)
  ) %>%
  arrange(desc(Promedio_Ha))

print("--- TOP CULTIVOS POR ÁREA PROMEDIO PERDIDA ---")
print(head(resumen_cultivo, 10))

# 3. Análisis Combinado de las 3 Variables (Cultivo, Superficie, Motivos)
cat("\n--- ANÁLISIS UNIFICADO (Variable 224B + 224D + 224E) ---\n")
resumen_unificado <- data %>%
  group_by(cultivo) %>%
  summarise(
    Casos = n(),
    Promedio_Ha = mean(superficie_total, na.rm = TRUE),
    Motivo_Principal = names(which.max(c(
      Plagas = sum(P224E_3 == 1),
      Heladas = sum(P224E_4 == 1),
      Sequia = sum(P224E_6 == 1),
      Inundaciones = sum(P224E_2 == 1)
    )))
  ) %>%
  arrange(desc(Promedio_Ha))

print(head(resumen_unificado, 10))

# 4. Estadística en un Punto Geográfico Específico (Query Local)
cat("\n--- ESTADÍSTICA EN UN PUNTO GEOGRÁFICO DE INTERÉS ---\n")
punto_interes <- data %>% arrange(desc(superficie_total)) %>% head(1)

cat("Coordenadas: ", punto_interes$LONGITUD, ", ", punto_interes$LATITUD, "\n")
cat(">> Cultivo Afectado (224B): ", punto_interes$cultivo, "\n")
cat(">> Superficie Perdida (224D): ", punto_interes$superficie_total, " hectáreas\n")
cat(">> Motivos Identificados (224E): \n")

motivos <- c()
if(punto_interes$P224E_1 == 1) motivos <- c(motivos, "Huaycos")
if(punto_interes$P224E_2 == 1) motivos <- c(motivos, "Inundaciones")
if(punto_interes$P224E_3 == 1) motivos <- c(motivos, "Plagas")
if(punto_interes$P224E_4 == 1) motivos <- c(motivos, "Heladas")
if(punto_interes$P224E_5 == 1) motivos <- c(motivos, "Granizada")
if(punto_interes$P224E_6 == 1) motivos <- c(motivos, "Sequía")
if(punto_interes$P224E_7 == 1) motivos <- c(motivos, "Otros")

cat("   - ", paste(motivos, collapse = ", "), "\n")

cat(">>> ANÁLISIS ESTADÍSTICO COMPLETADO.\n")
