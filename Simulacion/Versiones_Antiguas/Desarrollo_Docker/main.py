import numpy as np
import pandas as pd
import os

# Parámetros
dt = 0.5  # paso de tiempo en minutos
t1 = 30   # minutos para subir de 0 a 54
t2 = 30   # minutos de meseta
t3 = 3    # minutos para subir de 54 a 90
t4 = 2    # minutos para bajar de 90 a ~55
t5 = 30   # minutos de estabilización final

# Tramo 1: subida lineal 0 → 54 en 30 min
tiempo1 = np.arange(0, t1, dt)
nivel1 = np.linspace(0, 54, len(tiempo1))

# Tramo 2: meseta entre 50 y 57 (con ruido)
tiempo2 = np.arange(t1, t1+t2, dt)
nivel2 = np.random.uniform(50, 57, len(tiempo2))

# Tramo 3: subida rápida 54 → 90 en 3 min
tiempo3 = np.arange(t1+t2, t1+t2+t3, dt)
nivel3 = np.linspace(54, 90, len(tiempo3))

# Tramo 4: bajada rápida 90 → 55 en 2 min
tiempo4 = np.arange(t1+t2+t3, t1+t2+t3+t4, dt)
nivel4 = np.linspace(90, 55, len(tiempo4))

# Tramo 5: estabilización entre 54 y 57 por 30 min
tiempo5 = np.arange(t1+t2+t3+t4, t1+t2+t3+t4+t5, dt)
nivel5 = np.random.uniform(54, 57, len(tiempo5))

# Concatenar todo
tiempo = np.concatenate([tiempo1, tiempo2, tiempo3, tiempo4, tiempo5])
nivel = np.concatenate([nivel1, nivel2, nivel3, nivel4, nivel5])

# Guardar resultados con nombres estandarizados
os.makedirs("data", exist_ok=True)
df = pd.DataFrame({"tiempo": tiempo, "nivel": nivel})
df.to_csv("data/resultados.csv", index=False)

print("Simulación extendida completada. Resultados guardados en data/resultados.csv")