library(haven)
library(dplyr)
library(stringr)

# 1. Ruta al archivo original de 14.7 GB
archivo_pesado <- "C:/Users/User/Documents/SEMESTRE X/ESTADISTICA ESPACIAL/ARTICULO UNIDAD 1/ENA_2014_2024.sav"
ruta_salida <- "C:/Users/User/Documents/SEMESTRE X/ESTADISTICA ESPACIAL/PORTAFOLIO/JULIO/tareas/tarea-07-indice-moran/datos_ena_resumen.rds"

print("Cargando el archivo de 14.7 GB... Esto puede tardar varios minutos.")

# Cargar solo las columnas necesarias para ahorrar memoria RAM
datos <- read_sav(archivo_pesado,
                  encoding = "latin1",
                  col_select = c("NOMBREDD", "P229G_NOM", "P229H_EQUIV"))

print("Limpiando los datos...")
# Limpieza de NOMBREDD y conversión a numérico
datos <- datos %>%
  mutate(P229H_EQUIV = as.numeric(P229H_EQUIV)) %>%
  mutate(NOMBREDD = toupper(trimws(NOMBREDD))) %>%
  filter(NOMBREDD != "") %>%
  mutate(NOMBREDD = case_when(
    str_detect(NOMBREDD, "^AMAZON") ~ "AMAZONAS",
    str_detect(NOMBREDD, "^APUR") ~ "APURIMAC",
    str_detect(NOMBREDD, "^AREQUI") ~ "AREQUIPA",
    str_detect(NOMBREDD, "^AYACUC") ~ "AYACUCHO",
    str_detect(NOMBREDD, "^CAJAMA") ~ "CAJAMARCA",
    str_detect(NOMBREDD, "^HUANCA") ~ "HUANCAVELICA",
    str_detect(NOMBREDD, "^H.*NU") ~ "HUANUCO",
    str_detect(NOMBREDD, "^JUN") ~ "JUNIN",
    str_detect(NOMBREDD, "^LA LIB") ~ "LA LIBERTAD",
    str_detect(NOMBREDD, "^LAMBAY") ~ "LAMBAYEQUE",
    str_detect(NOMBREDD, "^MADRE") ~ "MADRE DE DIOS",
    str_detect(NOMBREDD, "^MOQUEG") ~ "MOQUEGUA",
    str_detect(NOMBREDD, "^SAN MA") ~ "SAN MARTIN",
    str_detect(NOMBREDD, "^UCAYAL") ~ "UCAYALI",
    TRUE ~ NOMBREDD
  ))

print("Resumiendo datos por producto agrícola...")
# Definir los productos
productos <- list(
  PAPA = "PAPA",
  CAFE = "CAFÉ|CAFE",
  MAIZ = "MAIZ|MAÍZ"
)

resumen_total <- data.frame()

for (prod in names(productos)) {
  regex <- productos[[prod]]
  resumen <- datos %>%
    filter(grepl(regex, P229G_NOM, ignore.case = TRUE)) %>%
    filter(!is.na(P229H_EQUIV), P229H_EQUIV > 0) %>%
    group_by(NOMBREDD) %>%
    summarise(Valor = sum(P229H_EQUIV, na.rm = TRUE)) %>%
    mutate(Producto = prod)
    
  resumen_total <- bind_rows(resumen_total, resumen)
}

# Guardar el resultado en un archivo pequeño que Shiny pueda leer al instante
saveRDS(resumen_total, ruta_salida)
print("¡Éxito! El archivo resumido se guardó correctamente. Ahora Shiny volará 🚀")
