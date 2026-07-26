###############################################################################
# Practica: Indice de Moran - Estadistica Espacial | FINESI - UNA Puno
# Entregable 2: Script de R reproducible con la salida de moran.test comentada
#
# Cubre dos casos:
#   (A) Parte A  - cinco parcelas en linea (contiguidad lineal)
#   (B) Ejercicio 1 - grilla 3x3 (contiguidad tipo torre / rook)
#
# Las salidas esperadas que aparecen comentadas fueron calculadas a mano con
# las formulas de Cliff & Ord bajo el supuesto de normalidad (mismos numeros
# que en la Hoja de calculo manual, Entregable 1), para que el estudiante
# verifique que la salida real de R coincide.
###############################################################################

library(spdep)

###############################################################################
## (A) PARTE A - Cadena lineal de 5 parcelas
###############################################################################

# 1. Datos: rendimiento (t/ha) de 5 parcelas en linea
z_A <- c(1.6, 1.8, 2.0, 1.5, 1.3)

# 2. Matriz de pesos por contiguidad lineal (vecinos adyacentes)
W_A <- matrix(0, 5, 5)
for (i in 1:4) { W_A[i, i + 1] <- 1; W_A[i + 1, i] <- 1 }
lw_A <- mat2listw(W_A, style = "B")  # B = binaria, sin estandarizar

# 3. Indice de Moran (debe coincidir con el calculo manual)
moran(z_A, lw_A, n = length(z_A), S0 = Szero(lw_A))$I
# Salida esperada: 0.207

# 4. Prueba de hipotesis analitica (supuesto de normalidad)
moran.test(z_A, lw_A, randomisation = FALSE)
# Salida esperada (aprox.):
#   Moran I statistic       I = 0.2069
#   Expectation           E[I] = -0.2500
#   Variance             Var[I] = 0.1406
#   z = 1.2187   p-value = 0.1115  (una cola, I > E[I])
#  -> NO significativo al 5%: con n=5 no hay evidencia estadistica
#     suficiente, aunque el signo apunta a agrupamiento positivo.

# 5. Prueba de hipotesis por permutaciones (mas robusta con n pequeno)
set.seed(123)
# n=5 permite un maximo de 120 permutaciones, por lo que usamos nsim = 119
moran.mc(z_A, lw_A, nsim = 119)
# Salida esperada: estadistico observado I = 0.207, p-value similar
# al de la prueba analitica (del orden de 0.10-0.15), dado que la
# distribucion nula bajo permutaciones tambien se centra en E[I].


###############################################################################
## (B) EJERCICIO 1 - Grilla 3x3, contiguidad tipo torre (rook)
###############################################################################

# 1. Datos: rendimiento (t/ha), orden de lectura de la grilla (fila por fila)
z_B <- c(2.1, 2.0, 1.6,
         1.9, 1.8, 1.5,
         1.7, 1.4, 1.3)

# 2. Coordenadas de cada celda para definir la vecindad por distancia
coords <- expand.grid(x = 1:3, y = 3:1)
coords <- coords[order(coords$y, coords$x, decreasing = c(TRUE, FALSE)), ]

# 3. Vecindad tipo torre (rook): distancia euclidiana == 1
nb_rook <- dnearneigh(as.matrix(coords), 0, 1)
lw_rook <- nb2listw(nb_rook, style = "B")

moran(z_B, lw_rook, n = length(z_B), S0 = Szero(lw_rook))$I
# Salida esperada: 0.4875

# 4. Prueba de hipotesis analitica (supuesto de normalidad)
moran.test(z_B, lw_rook, randomisation = FALSE)
# Salida esperada (aprox.):
#   Moran I statistic       I = 0.4875
#   Expectation           E[I] = -0.1250
#   Variance             Var[I] = 0.0531
#   z = 2.6574   p-value = 0.0039  (una cola, I > E[I])
#  -> SI significativo al 5% (incluso al 1%): con n=9 y un patron
#     espacial claro, se rechaza la hipotesis nula de ausencia de
#     autocorrelacion; el agrupamiento observado no es producto del azar.

# 5. Prueba por permutaciones
set.seed(123)
moran.mc(z_B, lw_rook, nsim = 999)
# Salida esperada: I = 0.4875 debe ubicarse entre los valores mas altos
# de las 1000 permutaciones (observada + 999 simuladas), dando un
# p-value pequeno (tipicamente < 0.01), consistente con la prueba analitica.


###############################################################################
# NOTA METODOLOGICA
#
# moran.test() en spdep usa por defecto randomisation = TRUE (varianza
# basada en el coeficiente de curtosis de los datos, no en la normalidad).
# Los valores de z y p-valor comentados arriba se calcularon a mano bajo
# el supuesto de normalidad (mas simple de reproducir en el papel); al
# correr este script con randomisation = TRUE (el valor por defecto, es
# decir simplemente moran.test(z, lw)) la magnitud sera parecida pero no
# identica. Se recomienda ejecutar ambas variantes y comentar la diferencia.
###############################################################################
