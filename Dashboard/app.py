import streamlit as st
import pandas as pd
import os

st.set_page_config(page_title="Dashboard Base Line MAJ", layout="wide")

# --- 1. CARGA DE DATOS ---
try:
    df_A = pd.read_csv("DataBase/dataset_A.csv")
    df_B = pd.read_csv("DataBase/dataset_B.csv")
except:
    st.sidebar.warning("⏳ Esperando datos del Puerto 8501...")
    st.stop()

# --- 2. COSTADO IZQUIERDO (SIDEBAR) CON DATOS DE CAMPO ---
with st.sidebar:
    st.header("📋 Datos de Producción")
    st.subheader("Separador B (70%)")
    st.metric("Caudal Bruto", f"{df_B['Q_Bruto'].mean():.1f} m3/d")
    st.metric("Corte de Agua (WC)", f"{df_B['WC (%)'].iloc[-1]} %")
    st.metric("Residencia Agua", f"{df_B['T_Residencia (min)'].mean():.1f} min")
    st.metric("Presión de Gas", f"{df_B['Presion'].iloc[-1]} bar")
    
    st.markdown("---")
    st.subheader("Separador A (30%)")
    st.metric("Caudal Bruto A", f"{df_A['Q_Bruto'].mean():.1f} m3/d")
    st.metric("Residencia Agua A", f"{df_A['T_Residencia (min)'].mean():.1f} min")

# --- 3. PANEL PRINCIPAL (GRÁFICOS) ---
st.title("📊 Monitor Industrial: Separación Trifásica")

# Gráfico de Carga
st.subheader("📉 Carga de Entrada (Caudal Bruto)")
df_bruto = pd.DataFrame({"Tiempo": df_A["Tiempo"], "Sep A": df_A["Q_Bruto"], "Sep B": df_B["Q_Bruto"]}).set_index("Tiempo")
st.line_chart(df_bruto)

# Gráficos de Niveles
st.subheader("📊 Monitoreo de Niveles e Interfaces")
col1, col2 = st.columns(2)

def plot_control(df, titulo):
    chart_data = df[["Tiempo", "Nivel_Total", "SP_Total", "Nivel_Agua", "SP_Agua", "SP_Oil"]].set_index("Tiempo")
    st.line_chart(chart_data)

with col1:
    st.write("**Separador A**")
    plot_control(df_A, "Separador A")
with col2:
    st.write("**Separador B**")
    plot_control(df_B, "Separador B")

# --- 4. FOOTER MAJ ---
st.markdown("""<style>.footer-maj {position: fixed; left: 0; bottom: 0; width: 100%; background-color: #1E1E1E; color: white; text-align: center; padding: 10px 0; z-index: 999999; border-top: 2px solid #31333F;} .main .block-container { padding-bottom: 100px; }</style><div class="footer-maj">🚀 <b>Base Line Industrial</b> | Desarrollado por MAJ | 2026</div>""", unsafe_allow_html=True)
