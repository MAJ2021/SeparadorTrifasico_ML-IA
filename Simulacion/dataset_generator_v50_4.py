import pandas as pd
import numpy as np
import streamlit as st
import altair as alt
import os

# Configuración general
np.random.seed(42)
tiempo_total = 600   # segundos de simulación
paso = 5             # intervalo de registro (s)

def generar_escenario(nombre, tipo="estable",
                      q_agua_base=2000, q_oil_base=440, q_gas_base=4000,
                      temp_base=57, pres_in_base=3.5,
                      nivel_total_base=75, nivel_oil_base=54):
    registros = []
    for t in range(0, tiempo_total + 1, paso):
        q_agua = np.random.randint(q_agua_base - 200, q_agua_base + 200)
        q_oil  = np.random.randint(q_oil_base - 60, q_oil_base + 60)
        q_gas  = np.random.randint(q_gas_base - 1200, q_gas_base + 1200)
        temp   = np.random.uniform(temp_base - 2, temp_base + 2)
        pres_in = np.random.uniform(pres_in_base - 0.5, pres_in_base + 0.5)

        nivel_total = np.random.normal(nivel_total_base, 2)
        nivel_oil   = np.random.normal(nivel_oil_base, 2)
        pres_gas    = np.random.uniform(3.0, 4.0)

        pid_agua = np.clip(np.random.normal(50, 10), 0, 100)
        pid_oil  = np.clip(np.random.normal(45, 8), 0, 100)

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
            pid_agua = np.clip(pid_agua + 30, 0, 100)
            nivel_total += 10
            estado = "Fallo"
        elif tipo == "meseta":
            nivel_total = np.clip(nivel_total + (t/tiempo_total)*5, 0, 100)
            estado = "Alerta"
        else:
            estado = "Normal"

        registros.append([nombre, t, caudal_bruto, q_agua, q_oil, q_gas, temp, pres_in,
                          nivel_total, nivel_oil, pres_gas, pid_agua, pid_oil, estado])
    return registros

st.title("Simulación de Dos Separadores en Paralelo v51.3")

escenario = st.sidebar.selectbox(
    "Selecciona el escenario",
    ["estable", "perturbado_leve", "perturbado_severo", "fallo_control", "meseta"]
)

# Parámetros base de producción total
q_agua_base = st.sidebar.slider("Caudal Agua Total (m³/d)", 1800, 2200, 2000)
q_oil_base  = st.sidebar.slider("Caudal Oil Total (m³/d)", 380, 500, 440)
q_gas_base  = st.sidebar.slider("Caudal Gas Total (m³/d)", 2800, 5200, 4000)
temp_base   = st.sidebar.slider("Temperatura (°C)", 55, 60, 57)
pres_in_base = st.sidebar.slider("Presión de Entrada (bar)", 3.0, 4.0, 3.5)

nivel_total_base = st.sidebar.slider("Nivel Total (%)", 60, 90, 75)
nivel_oil_base   = st.sidebar.slider("Nivel Oil (%)", 40, 70, 54)

# Slider de reparto de producción
porcentaje_A = st.sidebar.slider("Porcentaje al Separador A (%)", 0, 100, 60) / 100.0
porcentaje_B = 1 - porcentaje_A

# Ajustar caudales para cada separador
q_agua_A = int(q_agua_base * porcentaje_A)
q_oil_A  = int(q_oil_base * porcentaje_A)
q_gas_A  = int(q_gas_base * porcentaje_A)

q_agua_B = q_agua_base - q_agua_A
q_oil_B  = q_oil_base - q_oil_A
q_gas_B  = q_gas_base - q_gas_A

# Generar escenarios para A y B
data_A = generar_escenario("Separador A", escenario, q_agua_A, q_oil_A, q_gas_A,
                           temp_base, pres_in_base, nivel_total_base, nivel_oil_base)

data_B = generar_escenario("Separador B", escenario, q_agua_B, q_oil_B, q_gas_B,
                           temp_base, pres_in_base, nivel_total_base, nivel_oil_base)

# Crear DataFrames con columnas ordenadas
columnas = [
    "Separador", "Tiempo (s)", "Caudal_bruto (m³/d)",
    "Q_agua (m³/d)", "Q_oil (m³/d)", "Q_gas (m³/d)",
    "Temp (°C)", "Presión_in (bar)", "Nivel_total (%)", "Nivel_oil (%)",
    "Presión_gas (bar)", "PID_Agua (%)", "PID_Oil (%)", "Estado"
]

df_A = pd.DataFrame(data_A, columns=columnas)
df_B = pd.DataFrame(data_B, columns=columnas)

# Guardar datasets
output_dir = "DataBase"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

df_A.to_csv(os.path.join(output_dir, "dataset_A.csv"), index=False)
df_B.to_csv(os.path.join(output_dir, "dataset_B.csv"), index=False)

st.success("Datasets de Separador A y B generados y guardados")

# --- Validación ---
def validar_produccion(df, produccion_real, tolerancia=0.05):
    resultados = {}
    for var, ref in produccion_real.items():
        sim = df[f"Q_{var} (m³/d)"].mean()
        dentro_rango = abs(sim - ref) <= ref * tolerancia
        desvio = (sim - ref) / ref * 100
        resultados[var] = {
            "Simulado": sim,
            "Referencia": ref,
            "Dentro de rango": dentro_rango,
            "Desvío (%)": desvio
        }
    return resultados

produccion_A = {"agua": q_agua_A, "oil": q_oil_A, "gas": q_gas_A}
produccion_B = {"agua": q_agua_B, "oil": q_oil_B, "gas": q_gas_B}

validacion_A = validar_produccion(df_A, produccion_A, 0.05)
validacion_B = validar_produccion(df_B, produccion_B, 0.05)

with st.expander("Validación de Separadores"):
    st.subheader("Separador A")
    for var, res in validacion_A.items():
        st.write(f"**{var.capitalize()}** → Simulado: {res['Simulado']:.1f}, "
                 f"Referencia: {res['Referencia']}, "
                 f"Desvío: {res['Desvío (%)']:.2f}%, "
                 f"Dentro de rango: {res['Dentro de rango']}")

    st.subheader("Separador B")
    for var, res in validacion_B.items():
        st.write(f"**{var.capitalize()}** → Simulado: {res['Simulado']:.1f}, "
                 f"Referencia: {res['Referencia']}, "
                 f"Desvío: {res['Desvío (%)']:.2f}%, "
                 f"Dentro de rango: {res['Dentro de rango']}")

with st.expander("Gráficos comparativos"):
    st.subheader("Comparación de Niveles")
    nivel_chart = alt.Chart(df_A).mark_line(color="blue").encode(
        x="Tiempo (s)", y="Nivel_total (%)"
    ) + alt.Chart(df_B).mark_line(color="orange").encode(
        x="Tiempo (s)", y="Nivel_total (%)"
    ).properties(title="Nivel Total A vs B")
    st.altair_chart(nivel_chart, use_container_width=True)

    st.subheader("Comparación de Caudales Brutos")
    caudal_chart = alt.Chart(df_A).mark_line(color="green").encode(
        x="Tiempo (s)", y="Caudal_bruto (m³/d)"
    ) + alt.Chart(df_B).mark_line(color="red").encode(
        x="Tiempo (s)", y="Caudal_bruto (m³/d)"
    ).properties(title="Caudal Bruto A vs B")
    st.altair_chart(caudal_chart, use_container_width=True)

    st.subheader("Comparación de PID Agua")
    pid_agua_chart = alt.Chart(df_A).mark_line(color="blue").encode(
        x="Tiempo (s)", y="PID_Agua (%)"
    ) + alt.Chart(df_B).mark_line(color="orange").encode(
        x="Tiempo (s)", y="PID_Agua (%)"
    ).properties(title="PID Agua A vs B")
    st.altair_chart(pid_agua_chart, use_container_width=True)

    st.subheader("Comparación de PID Oil")
    pid_oil_chart = alt.Chart(df_A).mark_line(color="green").encode(
        x="Tiempo (s)", y="PID_Oil (%)"
    ) + alt.Chart(df_B).mark_line(color="red").encode(
        x="Tiempo (s)", y="PID_Oil (%)"
    ).properties(title="PID Oil A vs B")
    st.altair_chart(pid_oil_chart, use_container_width=True)
with st.expander("Tablas completas"):
    st.subheader("Datos Separador A")
    st.dataframe(df_A, use_container_width=True)

    st.subheader("Datos Separador B")
    st.dataframe(df_B, use_container_width=True)

    # --- Tabla comparativa A vs B ---
    df_merge = pd.merge(
        df_A[["Tiempo (s)", "Caudal_bruto (m³/d)", "Q_agua (m³/d)", "Q_oil (m³/d)", "Q_gas (m³/d)"]],
        df_B[["Tiempo (s)", "Caudal_bruto (m³/d)", "Q_agua (m³/d)", "Q_oil (m³/d)", "Q_gas (m³/d)"]],
        on="Tiempo (s)",
        suffixes=("_A", "_B")
    )

    st.subheader("Caudales Comparativos A vs B")
    st.dataframe(df_merge, use_container_width=True)

with st.expander("Descargar datasets"):
    csv_A = df_A.to_csv(index=False).encode("utf-8")
    csv_B = df_B.to_csv(index=False).encode("utf-8")
    csv_total = df_merge.to_csv(index=False).encode("utf-8")

    st.download_button(
        label="Descargar dataset Separador A",
        data=csv_A,
        file_name="dataset_A.csv",
        mime="text/csv",
    )

    st.download_button(
        label="Descargar dataset Separador B",
        data=csv_B,
        file_name="dataset_B.csv",
        mime="text/csv",
    )

    st.download_button(
        label="Descargar dataset comparativo A vs B",
        data=csv_total,
        file_name="dataset_comparativo.csv",
        mime="text/csv",
    )

# --- Footer ---
st.markdown(
    """
    <hr style="margin-top:50px; margin-bottom:10px;">
    <div style="text-align:center; color:gray;">
        © 2026 - Simulación de Separadores | Desarrollado por Marco A Jakuto
    </div>
    """,
    unsafe_allow_html=True
)
