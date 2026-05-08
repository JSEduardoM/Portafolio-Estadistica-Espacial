# Documentación Técnica: Análisis Espacial de Pérdidas Agrícolas (ENA)

Este documento detalla el proceso técnico, la estructura de datos y los resultados finales del análisis realizado sobre la **Encuesta Nacional Agropecuaria (ENA)** de Perú (periodo 2014-2024).

---

## 1. Contexto y Objetivos
El proyecto cuantifica y visualiza la **pérdida total de producción** reportada por las unidades agropecuarias, basándose en el Capítulo 200 del cuestionario ENA:
- **Variable 224B**: Identificación del cultivo.
- **Variable 224D**: Magnitud de la pérdida (Hectáreas).
- **Variable 224E**: Motivos de la pérdida (Fenómenos climáticos y biológicos).

## 2. Metodología de Particionado (Modularización)
Para manejar eficientemente la base de datos de **14 GB**, se dividió el código en 4 scripts autónomos:

1.  **`01_subset_data.R`**: Extrae las columnas críticas y las filtra. Genera un archivo optimizado `.rds`.
2.  **`02_statistics_tables.R`**: Carga el subset y genera promedios y tablas de frecuencias.
3.  **`03_mapping_viz.R`**: Genera la cartografía geoespacial (Puntos sobre mapa de Perú).
4.  **`main.R`**: Orquestador principal que ejecuta todo el flujo de trabajo.

## 3. Diccionario de Variables Utilizadas
| Código | Descripción | Variable en R |
| :--- | :--- | :--- |
| **224B** | Nombre del Cultivo | `P224B_NOM` |
| **224D** | Superficie Perdida (Ha) | `P224D_SUP_1` (E) + `P224D_SUP_2` (D) |
| **224E** | Motivos de la Pérdida | `P224E_1` a `P224E_7` |
| **GEO** | Georreferenciación | `LONGITUD`, `LATITUD` |

## 4. Resultados Estadísticos (Resumen Detallado)

###  Análisis Unificado de las 3 Variables (Cultivo + Área + Motivo)
Se analizó la relación entre el tipo de cultivo y el riesgo principal asociado:

| Cultivo (224B) | Promedio Ha (224D) | Motivo Principal (224E) |
| :--- | :--- | :--- |
| **Granadilla** | 3000.0 | Plagas |
| **Avena Grano** | 1302.8 | Heladas |
| **Papa Color** | 335.0 | Heladas |
| **Olluco** | 334.3 | Heladas |
| **Trigo** | 326.5 | Sequía |

### Estadística en un Punto Geográfico Crítico
Perfil del registro con la mayor superficie de pérdida identificada en la base de datos:
- **Ubicación (LON/LAT)**: `-73.51986 , -13.80796`
- **Cultivo Afectado**: AVENA GRANO
- **Superficie Perdida**: 4,600 hectáreas
- **Motivos reportados**: Heladas y Sequía.

##  Visualización Cartográfica Final

A continuación se presenta el mapa generado con la distribución nacional de las pérdidas. 

![Mapa Final de Pérdidas ENA](file:///c:/Users/User/Documents/SEMESTRE X/ESTADISTICA ESPACIAL/DATOS/mapa_ena_perdidas.png)

##  Estructura de Archivos
- **`ena_subset.rds`**: Base de datos ligera cargable en segundos con `readRDS()`.
- **`mapa_ena_perdidas.png`**: Mapa oficial de alta resolución generado.
- **`main.R`**: Script maestro de ejecución rápida.

---
**Instrucciones de uso:**
Para repetir o actualizar el análisis, simplemente ejecute el script maestro:
`source("DATOS/main.R")`
