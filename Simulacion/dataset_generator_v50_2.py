import pandas as pd
import numpy as np
import streamlit as st
import altair as alt
import os

# Configuración de simulación
np.random.seed(42)
tiempo_total = 600   # segundos de simulación
paso = 5             # intervalo de registro (s)

def generar_escenario(tipo="estable", q_agua_base=2000, q_oil_base=440, q_gas_base=4000,
                      temp_base=57, pres_in_base=3.5,
                      nivel_total_base=75, nivel_oil_base=54):  # FIX: nuevos parámetros
    registros = []
    for t in range(0, tiempo_total + 1, paso):
        q_agua = np.random.randint(q_agua_base - 200, q_agua_base + 200)
        q_oil  = np.random.randint(q_oil_base - 60, q_oil_base + 60)
        q_gas  = np.random.randint(q_gas_base - 1200, q_gas_base + 1200)
        temp   = np.random.uniform(temp_base - 2, temp_base + 2)
        pres_in = np.random.uniform(pres_in_base - 0.5, pres_in_base + 0.5)

        # FIX: ahora dependen de sliders
        nivel_total = np.random.normal(nivel_total_base, 2)
        nivel_oil   = np.random.normal(nivel_oil_base, 2)

        pres_gas    = np.random.uniform(3.0, 4.0)
        pid_valv    = np.clip(np.random.normal(50, 10), 0, 100)

        # Calcular caudal bruto total
        caudal_bruto = q_agua + q_oil + q_gas

        if tipo == "perturbado_leve":
            q_agua *= 1.05
            nivel_total += 3
            estado = "Alerta"
        elif tipo == "perturbado_severo":
            q_gas *= 1.20
            nivel_oil += 6
            estado = "Fallo"
        elif tipo == "fallo_control":
            pid_valv = np.clip(pid_valv + 30, 0, 100)
            nivel_total += 10
            estado = "Fallo"
        elif tipo == "meseta":
            nivel_total = np.clip(nivel_total + (t/tiempo_total)*5, 0, 100)
            estado = "Alerta"
        else:
            estado = "Normal"

        registros.append([t, q_agua, q_oil, q_gas, temp, pres_in,
                          nivel_total, nivel_oil, pres_gas, pid_valv,
                          caudal_bruto, estado])
    return registros

# --- Interfaz Streamlit ---
st.title("Generador de Datasets Sintéticos v50.4")

escenario = st.sidebar.selectbox(
    "Selecciona el escenario",
    ["estable", "perturbado_leve", "perturbado_severo", "fallo_control", "meseta"]
)

q_agua_base = st.sidebar.slider("Caudal Agua (m³/d)", 1800, 2200, 2000)
q_oil_base  = st.sidebar.slider("Caudal Oil (m³/d)", 380, 500, 440)
q_gas_base  = st.sidebar.slider("Caudal Gas (m³/d)", 2800, 5200, 4000)
temp_base   = st.sidebar.slider("Temperatura (°C)", 55, 60, 57)
pres_in_base = st.sidebar.slider("Presión de Entrada (bar)", 3.0, 4.0, 3.5)

# FIX: nuevos sliders para niveles
nivel_total_base = st.sidebar.slider("Nivel Total (%)", 60, 90, 75)
nivel_oil_base   = st.sidebar.slider("Nivel Oil (%)", 40, 70, 54)

# Nuevo slider para caudal bruto y tolerancia
caudal_bruto_base = st.sidebar.slider("Caudal Bruto Total (m³/d)", 5000, 8000, 6450)
tolerancia = st.sidebar.slider("Tolerancia validación (%)", 1, 20, 5) / 100.0

# FIX: pasar los nuevos parámetros a la función
data = generar_escenario(escenario, q_agua_base, q_oil_base, q_gas_base,
                         temp_base, pres_in_base,
                         nivel_total_base, nivel_oil_base)

df = pd.DataFrame(data, columns=[
    "Tiempo (s)", "Q_agua (m³/d)", "Q_oil (m³/d)", "Q_gas (m³/d)",
    "Temp (°C)", "Presión_in (bar)", "Nivel_total (%)", "Nivel_oil (%)",
    "Presión_gas (bar)", "Señal_PID_valv (%)", "Caudal_bruto (m³/d)", "Estado"
])

# Guardar dataset
output_dir = "DataBase"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

output_path = os.path.join(output_dir, f"dataset_{escenario}_v50_4.csv")
df.to_csv(output_path, index=False)

st.success(f"Dataset generado y guardado en {output_path}")

# --- Indicadores dinámicos ---
st.subheader("Indicadores clave")

col1, col2, col3 = st.columns(3)
col1.metric("Caudal Agua Promedio", f"{df['Q_agua (m³/d)'].mean():.1f}")
col2.metric("Caudal Oil Promedio", f"{df['Q_oil (m³/d)'].mean():.1f}")
col3.metric("Caudal Gas Promedio", f"{df['Q_gas (m³/d)'].mean():.1f}")

col4, col5, col6 = st.columns(3)
col4.metric("Nivel Total Máx", f"{df['Nivel_total (%)'].max():.1f}%")
col5.metric("Nivel Oil Máx", f"{df['Nivel_oil (%)'].max():.1f}%")
col6.metric("Presión Gas Promedio", f"{df['Presión_gas (bar)'].mean():.2f} bar")

col7, col8 = st.columns(2)
col7.metric("Caudal Bruto Promedio", f"{df['Caudal_bruto (m³/d)'].mean():.1f}")
col8.metric("Caudal Bruto Máx", f"{df['Caudal_bruto (m³/d)'].max():.1f}")

# --- Validación contra producción real ---
def validar_produccion(df, produccion_real, tolerancia=0.05):
    resultados = {}
    for var, ref in produccion_real.items():
        sim = df[f"Q_{var} (m³/d)"].mean()
        dentro_rango = abs(sim - ref) <= ref * tolerancia
        resultados[var] = {
            "Simulado": sim,
            "Referencia": ref,
            "Dentro de rango": dentro_rango
        }
    return resultados

def calcular_residencia(volumen_m3=17, caudal_bruto_m3_dia=caudal_bruto_base):
    return volumen_m3 / caudal_bruto_m3_dia

produccion_real = {"agua":q_agua_base, "oil":q_oil_base, "gas":q_gas_base}
validacion = validar_produccion(df, produccion_real, tolerancia)

st.subheader("Validación contra producción real")
for var, res in validacion.items():
    st.write(f"**{var.capitalize()}** → Simulado: {res['Simulado']:.1f}, "
             f"Referencia: {res['Referencia']}, "
             f"Dentro de rango: {res['Dentro de rango']}")

tiempo_residencia = calcular_residencia()
st.metric("Tiempo de residencia (días)", f"{tiempo_residencia:.4f}")

# --- Tabla completa ---
st.dataframe(df, use_container_width=True)

# --- Gráficos con Altair ---
nivel_chart = alt.Chart(df).mark_line().encode(
    x="Tiempo (s)", y="Nivel_total (%)", color=alt.value("blue")
) + alt.Chart(df).mark_line().encode(
    x="Tiempo (s)", y="Nivel_oil (%)", color=alt.value("orange")
).properties(title="Evolución de Niveles")
st.altair_chart(nivel_chart, use_container_width=True)

pres_chart = alt.Chart(df).mark_line().encode(
    x="Tiempo (s)", y="Presión_gas (bar)", color=alt.value("green")
) + alt.Chart(df).mark_line().encode(
    x="Tiempo (s)", y="Presión_in (bar)", color=alt.value("red")
).properties(title="Evolución de Presiones")
st.altair_chart(pres_chart, use_container_width=True)

# FIX: ordenar caudales consecutivos incluyendo caudal bruto
caudal_df = df.melt(
    id_vars=["Tiempo (s)"],
    value_vars=["Q_agua (m³/d)", "Q_oil (m³/d)", "Q_gas (m³/d)", "Caudal_bruto (m³/d)"],
    var_name="Variable", value_name="Caudal"
)

# Líneas de referencia de campo
ref_data = pd.DataFrame({
    "Variable": ["Q_agua (m³/d)", "Q_oil (m³/d)", "Q_gas (m³/d)", "Caudal_bruto (m³/d)"],
    "Caudal": [2000, 440, 4000, 6440]  # referencia aproximada
})

caudal_chart = alt.Chart(caudal_df).mark_line().encode(
    x="Tiempo (s)", y="Caudal", color="Variable"
) + alt.Chart(ref_data).mark_rule().encode(
    y="Caudal", color="Variable"
).properties(title="Evolución de Caudales con Referencias")
st.altair_chart(caudal_chart, use_container_width=True)

# --- Botón de descarga ---
csv = df.to_csv(index=False).encode("utf-8")
st.download_button(
    label="Descargar dataset",
    data=csv,
    file_name=f"dataset_{escenario}_v50_4.csv",
    mime="text/csv",
)
