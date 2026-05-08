# =============================================================================
# PASO 1: EXTRACCIÓN Y SUBSETTING DE DATOS ENA (FUENTE SAV)
# =============================================================================
library(haven)
library(dplyr)

archivo_sav <- "c:/Users/User/Documents/SEMESTRE X/ESTADISTICA ESPACIAL/DATOS/ENA_2014_2024.sav"
archivo_rds <- "c:/Users/User/Documents/SEMESTRE X/ESTADISTICA ESPACIAL/DATOS/ena_subset.rds"

cat(">>> LEYENDO ARCHIVO SPSS (14GB)... USANDO COL_SELECT PARA VELOCIDAD...\n")

# Extraemos solo las variables críticas para el análisis
columnas_interes <- c(
  "LONGITUD", "LATITUD", "P102C_DEP", 
  "P224B_NOM", 
  "P224D_SUP_1", "P224D_SUP_2",
  "P224E_1", "P224E_2", "P224E_3", "P224E_4", "P224E_5", "P224E_6", "P224E_7"
)

# Lectura selectiva con encoding específico
data_raw <- read_sav(archivo_sav, col_select = all_of(columnas_interes), encoding = "latin1")

cat(">>> PROCESANDO Y LIMPIANDO REGISTROS...\n")

data_proc <- data_raw %>%
  # Limpiar etiquetas y convertir a numérico
  mutate(across(everything(), zap_labels)) %>% 
  mutate(across(c(LONGITUD, LATITUD, P224D_SUP_1, P224D_SUP_2), as.numeric)) %>%
  # Filtrar por coordenadas y existencia de pérdida (224D)
  filter(!is.na(LONGITUD), !is.na(LATITUD), !is.na(P224D_SUP_1)) %>%
  mutate(
    superficie_total = P224D_SUP_1 + (coalesce(P224D_SUP_2, 0) / 100),
    departamento = as.character(P102C_DEP),
    cultivo = as.character(P224B_NOM)
  )

cat(">>> GUARDANDO SUBSET OPTIMIZADO...\n")
saveRDS(data_proc, archivo_rds)

cat(">>> EXTRACCIÓN COMPLETADA.\n")
cat(">>> Registros con pérdida total recuperados:", nrow(data_proc), "\n")
