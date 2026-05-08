# =============================================================================
# SCRIPT MAESTRO: CONTROL DE FLUJO MODULAR - ENA
# =============================================================================

cat("\n****************************************************")
cat("\n*  SISTEMA MODULAR DE ANÁLISIS ESPACIAL (ENA)      *")
cat("\n****************************************************\n\n")

# Paso 1: Extracción y Limpieza
cat("[PASO 1] Iniciando extracción de datos...\n")
source("c:/Users/User/Documents/SEMESTRE X/ESTADISTICA ESPACIAL/DATOS/01_subset_data.R")

# Paso 2: Análisis Estadístico
cat("\n[PASO 2] Generando tablas y estadísticas...\n")
source("c:/Users/User/Documents/SEMESTRE X/ESTADISTICA ESPACIAL/DATOS/02_statistics_tables.R")

# Paso 3: Visualización Cartográfica
cat("\n[PASO 3] Creando mapa regional...\n")
source("c:/Users/User/Documents/SEMESTRE X/ESTADISTICA ESPACIAL/DATOS/03_mapping_viz.R")

cat("\n>>> PROCESO COMPLETADO EXITOSAMENTE.\n\n")
