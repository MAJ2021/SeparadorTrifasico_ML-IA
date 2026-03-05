import pandas as pd
import numpy as np
import streamlit as st
import os
from io import BytesIO
from fpdf import FPDF

# Directorio de persistencia
OUTPUT_DIR = "DataBase"
if not os.path.exists(OUTPUT_DIR): os.makedirs(OUTPUT_DIR)

st.set_page_config(page_title="Simulador de Separación Industrial", layout="wide")

# --- FUNCION GENERAR PDF ---
def generar_pdf_completo(esc, df_a, df_b, carry_ov, blow_by):
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", 'B', 16)
    pdf.cell(200, 10, "REPORTE TÉCNICO DE SIMULACIÓN INDUSTRIAL", ln=True, align='C')
    pdf.ln(10)
    pdf.set_font("Arial", size=12)
    pdf.cell(200, 10, f"Escenario: {esc}", ln=True)
    pdf.cell(200, 10, f"Residencia Promedio A: {df_a['Resid'].mean():.1f} min", ln=True)
    pdf.cell(200, 10, f"Residencia Promedio B: {df_b['Resid'].mean():.1f} min", ln=True)
    if carry_ov: pdf.cell(200, 10, "ALERTA: CARRY-OVER DETECTADO (INUNDACION)", ln=True)
    if blow_by: pdf.cell(200, 10, "ALERTA: GAS BLOW-BY DETECTADO (BAJO SELLO)", ln=True)
    return pdf.output(dest='S').encode('latin-1')

# --- 1. SIDEBAR (CONFIGURACIÓN) ---
with st.sidebar:
    st.header("🕹️ Configuración de Campo")
    escenario = st.selectbox("Escenario", ["Estable", "Bache de Agua (Slug)", "Fallo de Presión", "Ciclo Crítico de Falla"])
    q_tot = st.slider("Caudal Bruto Total (m3/d)", 500, 6000, 2440)
    wc_b = st.slider("Corte de Agua - WC (%)", 10, 95, 82) / 100.0
    dist_a = st.slider("% Carga al Separador A", 0, 100, 30) / 100.0
    st.header("🎯 Set Points")
    sp_t = st.slider("SP Nivel Total (%)", 50, 95, 75)
    sp_a = st.slider("SP Nivel Agua (%)", 10, 90, 70)
    sp_o = st.slider("SP Nivel Oil (%)", 5, 90, 56)

st.title(f"🏭 Simulador Industrial: {escenario}")

# --- 2. DESCRIPCIÓN DE ESCENARIOS (SIN MAJ) ---
with st.container():
    if escenario == "Estable":
        st.info("**Descripción:** Operación bajo condiciones nominales. Se valida el equilibrio de niveles y tiempos de residencia estándar.")
    elif escenario == "Bache de Agua (Slug)":
        st.warning("**Descripción:** Simula la llegada de un bache de agua (Slug) donde el WC sube al 95% repentinamente tras 5 minutos de operación.")
    elif escenario == "Fallo de Presión":
        st.error("**Descripción:** Caída brusca de presión a 1.5 bar. Evalúa la pérdida de capacidad de las válvulas de control para evacuar líquidos.")
    elif escenario == "Ciclo Crítico de Falla":
        st.error("**Descripción: Ciclo Crítico de Falla (5 Horas)**")
        st.markdown("""
        *   **0-35 min:** Estabilización inicial.
        *   **35-60 min:** Falla de Válvula de Agua (Cerrada). El nivel sube al **90%** (Carry-over).
        *   **60-105 min:** Recuperación (Válvulas al 100% de apertura).
        *   **105-225 min:** Operación estable con Set Points originales.
        *   **225-250 min:** Vaciado total y caída de presión a **2 bar** (Blow-by).
        """)

# --- 3. EJECUCIÓN ---
if st.button("▶️ INICIAR SIMULACIÓN"):
    paso, duracion = 30, (18000 if escenario == "Ciclo Crítico de Falla" else 600)
    st.session_state.c_ov, st.session_state.b_by = False, False
    for nombre, split in [("A", dist_a), ("B", 1.0-dist_a)]:
        data, vol = [], 17.0
        h_max_fis = vol * 0.9
        h_a, h_o, p_act = (sp_a/100)*vol, (sp_o/100)*vol, 3.5
        for t in range(0, duracion + 1, paso):
            t_m, wc, f_a, r_f, v_c = t/60, wc_b, False, False, False
            if escenario == "Ciclo Crítico de Falla":
                if 35 < t_m <= 60: f_a = True
                elif 60 < t_m <= 105: r_f = True
                elif 225 < t_m <= 250: v_c, p_act = True, 2.0
                else: p_act = 3.5
            elif escenario == "Bache de Agua (Slug)" and t_m > 5: wc = 0.95
            elif escenario == "Fallo de Presión" and t_m > 4: p_act = 1.5
            qi_b = (q_tot * split / 86400) * np.random.normal(1.0, 0.05)
            qi_a, qi_o = qi_b * wc, qi_b * (1 - wc)
            k = 0.0008; err_a, err_t = ((h_a/vol)*100)-sp_a, (((h_a+h_o)/vol)*100)-sp_t
            if f_a: q_o_a, q_o_o = 0, k * p_act * err_t
            elif r_f: q_o_a, q_o_o = k * p_act * 10, k * p_act * 10
            elif v_c: q_o_a, q_o_o = k * p_act * 15, k * p_act * 5
            else: q_o_a, q_o_o = k * p_act * err_a, k * p_act * err_t
            q_o_a, q_o_o = max(0, min(q_o_a, (h_a/paso)+qi_a)), max(0, min(q_o_o, (h_o/paso)+qi_o))
            h_a, h_o = h_a + (qi_a-q_o_a)*paso, h_o + (qi_o-q_o_o)*paso
            nt = ((h_a+h_o)/vol)*100
            if nt >= 90: st.session_state.c_ov = True
            if nt <= 5: st.session_state.b_by = True
            h_a, h_o = np.clip(h_a, 0, h_max_fis), np.clip(h_o, 0, h_max_fis-h_a)
            data.append({"Tiempo (min)": round(t_m, 1), "Nivel_Total": round(nt, 2), "Nivel_Agua": round((h_a/vol)*100, 2), "Nivel_Oil": round((h_o/vol)*100, 2), "Presion": round(p_act, 2), "Resid": round((h_a/qi_a/60) if qi_a>0 else 0, 2)})
        df_res = pd.DataFrame(data)
        df_res.to_csv(os.path.join(OUTPUT_DIR, f"dataset_{nombre}.csv"), index=False)
        if nombre == "A": st.session_state.res_A, st.session_state.niv_A, st.session_state.oil_A = df_res['Resid'].iloc[-1], df_res['Nivel_Total'].iloc[-1], df_res['Nivel_Oil'].iloc[-1]
        else: st.session_state.res_B, st.session_state.niv_B, st.session_state.oil_B = df_res['Resid'].iloc[-1], df_res['Nivel_Total'].iloc[-1], df_res['Nivel_Oil'].iloc[-1]
    st.session_state.ejecutado = True
    st.rerun()

# --- 4. RESULTADOS (EXPANDER DERECHA) ---
if st.session_state.get('ejecutado', False):
    with st.expander("📊 Ver Resultados Detallados de Operación", expanded=True):
        st.subheader("📍 Indicadores Finales")
        col_res_a, col_res_b = st.columns(2)
        with col_res_a:
            st.markdown("**Separador A**")
            c1, c2, c3 = st.columns(3)
            c1.metric("Nivel Total", f"{st.session_state.niv_A:.1f}%")
            c2.metric("Nivel Oil", f"{st.session_state.oil_A:.1f}%")
            c3.metric("Residencia", f"{st.session_state.res_A:.1f} min")
        with col_res_b:
            st.markdown("**Separador B**")
            c4, c5, c6 = st.columns(3)
            c4.metric("Nivel Total", f"{st.session_state.niv_B:.1f}%")
            c5.metric("Nivel Oil", f"{st.session_state.oil_B:.1f}%")
            c6.metric("Residencia", f"{st.session_state.res_B:.1f} min")

        st.markdown("---")
        df_a, df_b = pd.read_csv(os.path.join(OUTPUT_DIR, "dataset_A.csv")), pd.read_csv(os.path.join(OUTPUT_DIR, "dataset_B.csv"))
        c_d1, c_d2 = st.columns(2)
        c_d1.download_button("📥 Descargar Datos (CSV)", pd.concat([df_a, df_b]).to_csv(index=False).encode('utf-8'), f"Datos_{escenario}.csv")
        c_d2.download_button("📄 Descargar Reporte (PDF)", generar_pdf_completo(escenario, df_a, df_b, st.session_state.c_ov, st.session_state.b_by), f"Reporte_{escenario}.pdf")

        tab_a, tab_b = st.tabs(["Curvas Separador A", "Curvas Separador B"])
        with tab_a: st.line_chart(df_a.set_index("Tiempo (min)")[["Nivel_Total", "Nivel_Agua", "Nivel_Oil"]])
        with tab_b: st.line_chart(df_b.set_index("Tiempo (min)")[["Nivel_Total", "Nivel_Agua", "Nivel_Oil"]])

# --- FOOTER PERSONALIZADO MAJ ---
st.markdown("""
<style>
.footer-maj {position: fixed; left: 0; bottom: 0; width: 100%; background-color: #1E1E1E; color: white; text-align: center; padding: 5px 0; border-top: 2px solid #31333F; z-index: 99;}
</style>
<div class="footer-maj">
<p>🚀 Desarrollado por <b>MAJ</b> | Especialista en Programación Industrial IA & Machine Learning  | 2026</p>
</div>
""", unsafe_allow_html=True)
