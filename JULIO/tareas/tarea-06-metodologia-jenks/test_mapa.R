library(geodata)
library(sf)
library(dplyr)
library(leaflet)

# Obtener límites de departamentos
peru <- gadm("PER", level = 1, path = tempdir())
peru_sf <- st_as_sf(peru)

# Normalizar nombres para que coincidan (simulando los datos del usuario)
peru_sf <- peru_sf %>%
  mutate(NAME_1 = toupper(NAME_1)) %>%
  mutate(NAME_1 = case_when(
    grepl("LIMA", NAME_1) ~ "LIMA",
    grepl("CALLAO", NAME_1) ~ "CALLAO",
    grepl("APURÍMAC", NAME_1) ~ "APURIMAC",
    grepl("HUÁNUCO", NAME_1) ~ "HUANUCO",
    grepl("JUNÍN", NAME_1) ~ "JUNIN",
    grepl("SAN MARTÍN", NAME_1) ~ "SAN MARTIN",
    TRUE ~ NAME_1
  ))

print(head(peru_sf$NAME_1))
