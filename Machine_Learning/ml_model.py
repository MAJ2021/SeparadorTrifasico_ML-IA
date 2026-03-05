import streamlit as st
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import os
from fpdf import FPDF
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score

# --- 1. FUNCIÓN DE INTELIGENCIA ARTIFICIAL (Consolidada) ---
def entrenar_modelo_ia(ruta_csv):
    """
    Cerebro de IA: Aprende la relación entre Caudal, Presión y Válvula con el Nivel.
    """
    if not os.path.exists(ruta_csv):
        return None, 0, 0
    
    data = pd.read_csv(ruta_csv)
    
    # Columnas de entrada (Features) y salida (Target)
    try:
        X = data[["Caudal_bruto (m³/d)", "Presión_in (bar)", "PID_Oil (%)"]]
        y = data["Nivel_oil (%)"]
    except KeyError:
        # Si las columnas no coinciden exactas, devolvemos error controlado
        return None, 0, 0

    # Dividir datos: 80% entrenamiento, 20% evaluación
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Crear y entrenar el Bosque Aleatorio (Random Forest)
    model = RandomForestRegressor(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)

    # Calcular métricas de precisión
    y_pred = model.predict(X_test)
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    r2 = r2_score(y_test, y_pred)

    return model, rmse, r2

# --- 2. CONFIGURACIÓN DE INTERFAZ ---
st.set_page_config(page_title="IA Control - Separador Trifásico", layout="wide")
ruta_csv = "DataBase/datos_simulacion.csv"

# --- 3. LÓGICA DE RE-ENTRENAMIENTO AUTOMÁTICO ---
if os.path.exists(ruta_csv):
    df_actual = pd.read_csv(ruta_csv)
    num_datos = len(df_actual)

    # Estado de sesión para persistencia de la IA
    if "ultimo_conteo" not in st.session_state:
        st.session_state.ultimo_conteo = 0
        st.session_state.modelo_ia = None

    # Re-entrenar cada 100 datos nuevos
    if num_datos >= st.session_state.ultimo_conteo + 100 or st.session_state.modelo_ia is None:
        with st.spinner('🤖 IA Aprendiendo de nuevos datos operativos...'):
            modelo, rmse, r2 = entrenar_modelo_ia(ruta_csv)
            if modelo:
                st.session_state.modelo_ia = modelo
                st.session_state.rmse = rmse
                st.session_state.r2 = r2
                st.session_state.ultimo_conteo = num_datos
                st.toast("✅ ¡Modelo de IA actualizado!", icon="🤖")

    # Si la IA está lista, mostrar Dashboard
    if st.session_state.modelo_ia:
        modelo = st.session_state.modelo_ia
        rmse = st.session_state.rmse
        r2 = st.session_state.r2

        st.title("📊 Dashboard Inteligente: Separador Trifásico")

        # MÉTRICAS SUPERIORES
        col_m1, col_m2, col_m3 = st.columns(3)
        col_m1.metric("Precisión IA (R²)", f"{r2:.2%}")
        col_m2.metric("Error Promedio (RMSE)", f"{rmse:.4f}")
        col_m3.metric("Datos en Memoria", num_datos)

        # SLIDERS (Caudal inicia en 2000 m3/d)
        st.sidebar.header("🕹️ Panel de Simulación IA")
        c_in = st.sidebar.slider("Caudal bruto (m³/d)", 0.0, 5000.0, 2000.0)
        p_in = st.sidebar.slider("Presión de entrada (bar)", 0.0, 50.0, 10.0)
        pid_oil = st.sidebar.slider("Apertura Válvula Oil (%)", 0.0, 100.0, 50.0)

        # PREDICCIÓN EN TIEMPO REAL
        input_df = pd.DataFrame([[c_in, p_in, pid_oil]], 
                                columns=["Caudal_bruto (m³/d)", "Presión_in (bar)", "PID_Oil (%)"])
        pred_nivel = modelo.predict(input_df)[0]

        # ALERTAS DE SEGURIDAD
        st.subheader("🔮 Predicción de Nivel en Tiempo Real")
        if pred_nivel > 90:
            estado = "CRÍTICO (Alto)"
            st.error(f"⚠️ ¡ALERTA! Nivel Predicho: {pred_nivel:.2f}% - Riesgo de Carryover")
        elif pred_nivel < 10:
            estado = "CRÍTICO (Bajo)"
            st.warning(f"📢 NIVEL BAJO: {pred_nivel:.2f}% - Riesgo de Gas Carry-under")
        else:
            estado = "OPERACIÓN NORMAL"
            st.success(f"✅ Estado Estable: {pred_nivel:.2f}%")

        st.progress(min(max(float(pred_nivel) / 100, 0.0), 1.0))

        # REPORTE PDF
        def generar_pdf(r2, rmse, c, p, pid, pred, est):
            pdf = FPDF()
            pdf.add_page()
            pdf.set_font("Arial", 'B', 16)
            pdf.cell(200, 10, "Reporte de Operacion IA - MAJ", ln=True, align='C')
            pdf.ln(10)
            pdf.set_font("Arial", size=12)
            pdf.cell(200, 10, f"Precision del Modelo: {r2:.2%}", ln=True)
            pdf.cell(200, 10, f"Entradas -> Caudal: {c} | Presion: {p} | Valvula: {pid}%", ln=True)
            pdf.cell(200, 10, f"PREDICCION DE NIVEL: {pred:.2f}% - ESTADO: {est}", ln=True)
            return pdf.output(dest='S').encode('latin-1')

        pdf_data = generar_pdf(r2, rmse, c_in, p_in, pid_oil, pred_nivel, estado)
        st.download_button("📥 Descargar Reporte PDF", data=pdf_data, file_name="reporte_separador_IA.pdf")

        # GRÁFICO COMPARATIVO
        st.subheader("📈 Validación del Modelo (Realidad vs Predicción IA)")
        df_plot = df_actual.tail(50).copy()
        df_plot['IA_Pred'] = modelo.predict(df_plot[["Caudal_bruto (m³/d)", "Presión_in (bar)", "PID_Oil (%)"]])

        fig = go.Figure()
        fig.add_trace(go.Scatter(y=df_plot["Nivel_oil (%)"], name="Dato Real (Simulación)", line=dict(color='#00d4ff')))
        fig.add_trace(go.Scatter(y=df_plot["IA_Pred"], name="Predicción de la IA", line=dict(color='#ffaa00', dash='dash')))
        fig.update_layout(template="dark", height=400, legend=dict(orientation="h", y=1.1))
        st.plotly_chart(fig, use_container_width=True)

else:
    st.error("Esperando datos de la simulación... (Inicia el script de Simulación primero)")

# --- 4. FOOTER ---
footer_html = """
<style>
.footer {
    position: fixed; left: 0; bottom: 0; width: 100%;
    background-color: #0E1117; color: #FAFAFA; text-align: center;
    padding: 10px; font-family: sans-serif; font-size: 14px;
    border-top: 1px solid #31333F; z-index: 100;
}
</style>
<div class="footer">
    <p>🚀 Desarrollado por <b>MAJ</b> | Especialista en Programación Industrial IA Machine Learning Oil & Gas | 2026</p>
</div>
"""
st.markdown(footer_html, unsafe_allow_html=True)
