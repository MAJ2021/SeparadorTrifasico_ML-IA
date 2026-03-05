import pandas as pd
import numpy as np
import streamlit as st
import os
from io import BytesIO
from fpdf import FPDF

# Directorio de persistencia
OUTPUT_DIR = "DataBase"
if not os.path.exists(OUTPUT_DIR): os.makedirs(OUTPUT_DIR)

st.set_page_config(page_title="Simulador: 2 Separadores en Paralelo V 1.2", layout="wide")

# --- FUNCION GENERAR PDF ---
def generar_pdf_completo(esc, df_a, df_b, carry_ov, blow_by):
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", 'B', 16)
    pdf.cell(200, 10, "REPORTE TÉCNICO: 2 SEPARADORES EN PARALELO V 1.2", ln=True, align='C')
    pdf.ln(10)
    pdf.set_font("Arial", size=12)
    pdf.cell(200, 10, f"Escenario: {esc}", ln=True)
    pdf.cell(200, 10, f"Residencia Promedio Agua A: {df_a['Resid'].mean():.1f} min", ln=True)
    if carry_ov: pdf.cell(200, 10, "ALERTA: CARRY-OVER DETECTADO", ln=True)
    if blow_by: pdf.cell(200, 10, "ALERTA: GAS BLOW-BY DETECTADO", ln=True)
    return pdf.output(dest='S').encode('latin-1')

# --- 1. SIDEBAR (CONFIGURACIÓN) ---
with st.sidebar:
    st.header("🕹️ Control de Proceso")
    escenario = st.selectbox("Escenario", ["Estable", "Bache de Agua (Slug)", "Fallo de Presión", "Ciclo Crítico de Falla"])
    q_tot = st.slider("Caudal Bruto Total (m3/d)", 500, 6000, 2440)
    wc_b = st.slider("Corte de Agua - WC (%)", 10, 95, 75) / 100.0
    dist_a = st.slider("% Carga al Separador A", 0, 100, 30) / 100.0
    st.header("🎯 Set Points")
    sp_t = st.slider("SP Nivel Total (%)", 0, 100, 75) 
    sp_a = st.slider("SP Nivel Agua (%)", 10, 90, 68) 
    sp_p = st.slider("SP Nivel Petróleo (%)", 5, 90, 56) 

st.title(f"🏭 Simulador: 2 Separadores en Paralelo V 1.2")

# --- 2. DESCRIPCIÓN DE ESCENARIOS ---
with st.container():
    if escenario == "Estable":
        st.info("**Descripción:** Operación nominal distribuida en 12 Horas. Control de interfaz Agua/Petróleo.")
    elif escenario == "Bache de Agua (Slug)":
        st.warning("**Descripción:** Transiente hidráulico por llegada de bache. El WC sube al 95% tras 60 min, evaluando la capacidad de drenaje de agua.")
    elif escenario == "Fallo de Presión":
        st.error("**Descripción:** Degradación de la presión diferencial a 1.5 bar. Monitoreo de acumulación por restricción en válvulas de descarga.")
    elif escenario == "Ciclo Crítico de Falla":
        st.error("**Análisis de Integridad Operativa: Ciclo de Falla Multivariable (12 Horas)**")
        st.markdown("""
        *   **Fase de Saturación (Hora 1-2):** Bloqueo mecánico de la LCV de Agua. Evaluación de tiempo de respuesta antes de inundación (Carry-over).
        *   **Fase de Estabilización (Hora 2-10):** Recuperación de inventarios y retorno al Set Point dinámico del 56% de Petróleo.
        *   **Fase de Depresión (Hora 10-11):** Descenso crítico de presión a 2.0 bar con apertura máxima de válvulas. Simulación de pérdida de sello hidráulico (Gas Blow-by).
        """)

# --- 3. MEMORIA DE CÁLCULO ---
with st.expander("📚 Memoria de Cálculo y Ecuaciones Técnicas"):
    st.markdown(f"""
    ### Fundamentos del Modelo
    1. **Balance de Masa Líquida:** $\Delta h = (Q_{{in}} - Q_{{out}}) \cdot \Delta t$
    2. **Control P:** $Q_{{out}} = K \cdot P_{{act}} \cdot (Nivel - SetPoint)$
    3. **Saturación:** Rango estricto $0\% \leq Nivel \leq 100\%$ mediante `np.clip`. No permite valores negativos ni superiores a escala total.
    """)

# --- 4. EJECUCIÓN ---
if st.button("▶️ INICIAR SIMULACIÓN (12 HORAS)"):
    paso, duracion = 60, 43200 
    st.session_state.c_ov, st.session_state.b_by = False, False
    
    for nombre, split in [("A", dist_a), ("B", 1.0-dist_a)]:
        data, vol = [], 17.0
        h_a, h_p = (sp_a/100)*vol, (5/100)*vol
        p_act = 3.5
        
        for t in range(0, duracion + 1, paso):
            t_m, wc, f_a, v_c = t/60, wc_b, False, False
            if escenario == "Ciclo Crítico de Falla":
                if 60 < t_m <= 120: f_a = True
                elif 600 < t_m <= 660: v_c, p_act = True, 2.0
                else: p_act = 3.5
            elif escenario == "Bache de Agua (Slug)" and t_m > 60: wc = 0.95
            
            qi_b = (q_tot * split / 86400) * np.random.normal(1.0, 0.01)
            qi_a, qi_p = qi_b * wc, qi_b * (1 - wc)
            
            k = 0.0025
            n_a_act = np.clip((h_a/vol)*100, 0, 100)
            n_p_act = np.clip((h_p/vol)*100, 0, 100)
            n_t_act = np.clip(n_a_act + n_p_act, 0, 100)
            
            q_o_a = k * p_act * (n_a_act - sp_a) if n_a_act > sp_a else 0
            err_p, err_t = n_p_act - sp_p, n_t_act - sp_t
            
            if f_a: q_o_a, q_o_p = 0, k * p_act * (n_p_act - sp_p)
            elif v_c: q_o_a, q_o_p = k * p_act * 20, k * p_act * 10
            else:
                q_o_p = k * p_act * max(err_p, err_t) if (err_p > 0 or err_t > 0) else 0

            q_o_a = max(0, min(q_o_a, (h_a/paso)+qi_a))
            q_o_p = max(0, min(q_o_p, (h_p/paso)+qi_p))
            
            h_a += (qi_a - q_o_a) * paso
            h_p += (qi_p - q_o_p) * paso
            h_a = np.clip(h_a, 0, vol)
            h_p = np.clip(h_p, 0, vol - h_a)
            
            if n_t_act >= 92: st.session_state.c_ov = True
            if n_t_act <= 5: st.session_state.b_by = True
            
            data.append({"Tiempo (h)": round(t_m/60, 2), "Nivel_Total": round(n_t_act, 2), "Nivel_Agua": round(n_a_act, 2), "Nivel_Petroleo": round(n_p_act, 2), "Resid": round((h_a/qi_a/60) if qi_a>0 else 0, 2)})
            
        df_res = pd.DataFrame(data)
        df_res.to_csv(os.path.join(OUTPUT_DIR, f"dataset_{nombre}.csv"), index=False)
        if nombre == "A": st.session_state.p_A, st.session_state.niv_A, st.session_state.res_A, st.session_state.agua_A = df_res['Nivel_Petroleo'].iloc[-1], df_res['Nivel_Total'].iloc[-1], df_res['Resid'].iloc[-1], df_res['Nivel_Agua'].iloc[-1]
        else: st.session_state.p_B, st.session_state.niv_B, st.session_state.res_B, st.session_state.agua_B = df_res['Nivel_Petroleo'].iloc[-1], df_res['Nivel_Total'].iloc[-1], df_res['Resid'].iloc[-1], df_res['Nivel_Agua'].iloc[-1]
    st.session_state.ejecutado = True
    st.rerun()

# --- 5. RESULTADOS ---
if st.session_state.get('ejecutado', False):
    with st.expander("📊 Resultados Finales (Operación 12H)", expanded=True):
        col_res_a, col_res_b = st.columns(2)
        with col_res_a:
            st.markdown("**Separador A**")
            c1, c2, c3, c4 = st.columns(4)
            c1.metric("Total", f"{st.session_state.niv_A:.1f}%")
            c2.metric("Agua", f"{st.session_state.agua_A:.1f}%")
            c3.metric("Petróleo", f"{st.session_state.p_A:.1f}%")
            c4.metric("Resid.", f"{st.session_state.res_A:.1f} min")
        with col_res_b:
            st.markdown("**Separador B**")
            c5, c6, c7, c8 = st.columns(4)
            c5.metric("Total", f"{st.session_state.niv_B:.1f}%")
            c6.metric("Agua", f"{st.session_state.agua_B:.1f}%")
            c7.metric("Petróleo", f"{st.session_state.p_B:.1f}%")
            c8.metric("Resid.", f"{st.session_state.res_B:.1f} min")
        df_a, df_b = pd.read_csv(os.path.join(OUTPUT_DIR, "dataset_A.csv")), pd.read_csv(os.path.join(OUTPUT_DIR, "dataset_B.csv"))
        tab_a, tab_b = st.tabs(["Curvas Separador A", "Curvas Separador B"])
        with tab_a: st.line_chart(df_a.set_index("Tiempo (h)")[["Nivel_Total", "Nivel_Agua", "Nivel_Petroleo"]])
        with tab_b: st.line_chart(df_b.set_index("Tiempo (h)")[["Nivel_Total", "Nivel_Agua", "Nivel_Petroleo"]])

# --- FOOTER PERSONALIZADO MAJ ---
st.markdown("""
<style>.footer-maj {position: fixed; left: 0; bottom: 0; width: 100%; background-color: #1E1E1E; color: white; text-align: center; padding: 5px 0; border-top: 2px solid #31333F; z-index: 99;}</style>
<div class="footer-maj"><p>🚀 Desarrollado por <b>MAJ</b> | Especialista en Programación Industrial IA & Machine Learning | 2026</p></div>
""", unsafe_allow_html=True)
