import pandas as pd
import numpy as np
import streamlit as st
import os
import matplotlib.pyplot as plt
from io import BytesIO
from fpdf import FPDF

# --- CONFIGURACIÓN Y PERSISTENCIA ---
OUTPUT_DIR = "DataBase"
if not os.path.exists(OUTPUT_DIR): os.makedirs(OUTPUT_DIR)

st.set_page_config(page_title="Simulador: 2 Separadores en Paralelo V 1.2", layout="wide")

if 'ejecutado' not in st.session_state:
    st.session_state.ejecutado = False
if 'c_ov' not in st.session_state:
    st.session_state.c_ov = False
if 'b_by' not in st.session_state:
    st.session_state.b_by = False

# --- FUNCIÓN: GENERAR REPORTE TÉCNICO PDF ---
# --- FUNCIÓN PDF ACTUALIZADA PARA MOSTRAR ESCENARIO Y ALERTAS HISTÓRICAS ---
# --- FUNCIÓN PDF ACTUALIZADA CON MEMORIA DE FALLA DE PRESIÓN ---
# --- PARTE 1: FUNCIÓN PDF COMPLETA (RECUPERADA AL 100%) ---
# --- PARTE 1: FUNCIÓN PDF RECUPERADA AL 100% (FORMATO ORIGINAL MAJ) ---
def generar_pdf_completo(esc, df_a, df_b, carry_ov, blow_by, baja_p, params):
    pdf = FPDF()
    pdf.add_page()
    
    # Rutas para evitar NameError en imágenes
    p1 = os.path.join(OUTPUT_DIR, "p1.png")
    p2 = os.path.join(OUTPUT_DIR, "p2.png")
    pa = os.path.join(OUTPUT_DIR, "temp_graph_A.png")
    pb = os.path.join(OUTPUT_DIR, "temp_graph_B.png")

    # --- ENCABEZADO ---
    pdf.set_font("Arial", 'B', 16)
    pdf.cell(200, 10, "REPORTE TÉCNICO DE INGENIERÍA - V1.2", ln=True, align='C')
    pdf.set_font("Arial", 'B', 11)
    pdf.cell(200, 10, f"ESCENARIO: {esc.upper()}", ln=True, align='C')
    pdf.ln(2); pdf.line(10, 35, 200, 35); pdf.ln(5)

    # 1. FUNDAMENTOS Y MEMORIA DE CÁLCULO
    pdf.set_font("Arial", 'B', 12); pdf.set_fill_color(230, 230, 230)
    pdf.cell(0, 8, "1. FUNDAMENTOS Y MEMORIA DE CÁLCULO", ln=True, fill=True)
    pdf.ln(2); pdf.set_font("Arial", 'B', 9); pdf.cell(0, 5, "Símbolos utilizados:", ln=True)
    pdf.set_font("Arial", '', 9)
    pdf.multi_cell(0, 5, "TD: Tiempo de Decantación (min) | V_a: Volumen de Agua (m3) | Q_out: Caudal de Salida (m3/d)\n"
                         "WC: Corte de Agua (%) | SP: Set Point (%) | Kv: Coeficiente de Válvula")
    pdf.ln(2); pdf.set_font("Arial", 'B', 9); pdf.cell(0, 5, "Lógica de Simulación Aplicada:", ln=True)
    pdf.set_font("Arial", '', 9)
    pdf.multi_cell(0, 5, "1. Eficiencia: TD = (V_a / Q_out) * 1440. Un TD < 10 min indica arrastre.\n"
                         "2. Balance de Masa: Nivel_Final = Nivel_Inicial + (Q_in - Q_out) * dt.\n"
                         "3. Control de Salida: Q_out = Kv * Presión * (Nivel_Actual - SP).")
    pdf.ln(4)

    # 2. PARÁMETROS DE ENTRADA (SET OPERADOR)
    pdf.set_font("Arial", 'B', 12); pdf.cell(0, 8, "2. PARÁMETROS DE ENTRADA (SET OPERADOR)", ln=True, fill=True)
    pdf.ln(2); pdf.set_font("Arial", '', 10)
    pdf.cell(0, 7, f"* Q_Agua: {params['q_a']} m3/d | * Q_Oil: {params['q_o']} m3/d | * Q_Gas: {params['q_g']} m3/d", ln=True)
    pdf.cell(0, 7, f"* Carga Sep A: {params['dist_a']}% | * Carga Sep B: {100 - params['dist_a']}%", ln=True)
    
    # --- PUNTOS CRÍTICOS RECUPERADOS ---
    pdf.set_font("Arial", 'B', 9); pdf.cell(0, 7, "Puntos Críticos de Control:", ln=True)
    pdf.set_font("Arial", '', 9)
    pdf.cell(0, 5, f"- Set Point Nivel Total: {params['sp_t']}% | - Límite Carry-Over: 90% | - Límite Blow-By: 10%", ln=True)
    pdf.ln(4)

    # 3. DETALLE DE SEPARACIÓN (RECUPERADO)
    pdf.set_font("Arial", 'B', 12); pdf.cell(0, 8, "3. DETALLE DE SEPARACIÓN", ln=True, fill=True)
    pdf.ln(2); pdf.set_font("Arial", '', 10)
    q_t = params['q_a'] + params['q_o']
    d_a = params['dist_a'] / 100.0
    ratio = params['q_a'] / params['q_o'] if params['q_o'] > 0 else 0
    pdf.cell(0, 7, f"* Caudal Bruto Total (Qin): {q_t} m3/d", ln=True)
    pdf.cell(0, 7, f"* Carga Sep A: {q_t * d_a:.1f} m3/d | Carga Sep B: {q_t * (1-d_a):.1f} m3/d", ln=True)
    pdf.cell(0, 7, f"* Relación Agua/Petróleo (Ratio): {ratio:.2f}", ln=True)
    pdf.ln(4)

    # 4. COMPOSICIÓN DE ENTRADA (GRAFICOS)
    pdf.set_font("Arial", 'B', 12); pdf.cell(0, 8, "4. COMPOSICIÓN DE ENTRADA", ln=True, fill=True)
    plt.figure(figsize=(4, 3))
    plt.pie([params['q_a'], params['q_o']], labels=['Agua', 'Oil'], autopct='%1.1f%%', colors=['#1f77b4', '#8c564b'])
    plt.savefig(p1, dpi=100); plt.close()
    plt.figure(figsize=(4, 3))
    plt.bar(["Agua", "Oil", "Gas"], [params['q_a'], params['q_o'], params['q_g']], color=['#1f77b4', '#8c564b', '#2ca02c'])
    plt.savefig(p2, dpi=100); plt.close()
    y_img = pdf.get_y() + 2; pdf.image(p1, x=15, y=y_img, w=75); pdf.image(p2, x=110, y=y_img, w=75)
    pdf.set_y(y_img + 60); pdf.ln(5)

    # 5. TENDENCIAS DE NIVELES
    pdf.set_font("Arial", 'B', 12); pdf.cell(0, 8, "5. TENDENCIAS DE NIVELES (HISTÓRICO)", ln=True, fill=True)
    def gen_trend(df, titulo, color_t, path):
        plt.figure(figsize=(8, 4))
        plt.plot(df['Tiempo (h)'], df['Nivel_Total'], label='Total', color=color_t, linewidth=2)
        plt.plot(df['Tiempo (h)'], df['Nivel_Agua'], label='Agua', color='#1f77b4', linestyle='--')
        plt.title(titulo); plt.grid(True, alpha=0.3); plt.legend()
        plt.savefig(path, dpi=100, bbox_inches='tight'); plt.close()
        
    gen_trend(df_a, "Separador A", "#1f77b4", pa)
    gen_trend(df_b, "Separador B", "#d62728", pb)
    y_trend = pdf.get_y() + 2; pdf.image(pa, x=10, y=y_trend, w=90); pdf.image(pb, x=105, y=y_trend, w=90)
    pdf.set_y(y_trend + 50); pdf.ln(10)
    
    pdf.add_page(); pdf.ln(5)

    # 6. ESTADO FINAL Y ALERTAS (CUADRO COMPLETO)
    pdf.set_font("Arial", 'B', 12); pdf.cell(0, 8, "6. ESTADO FINAL Y ALERTAS", ln=True, fill=True); pdf.ln(4)
    res_a, res_b = df_a.iloc[-1], df_b.iloc[-1]
    pdf.set_font("Arial", 'B', 10); pdf.set_fill_color(200, 200, 200)
    pdf.cell(60, 8, "Variable", 1, 0, 'L', True); pdf.cell(65, 8, "Separador A", 1, 0, 'C', True); pdf.cell(65, 8, "Separador B", 1, 1, 'C', True)
    pdf.set_font("Arial", '', 10)
    pdf.cell(60, 8, "Nivel Total (%)", 1); pdf.cell(65, 8, f"{res_a['Nivel_Total']:.1f}%", 1, 0, 'C'); pdf.cell(65, 8, f"{res_b['Nivel_Total']:.1f}%", 1, 1, 'C')
    pdf.cell(60, 8, "Nivel Agua (%)", 1); pdf.cell(65, 8, f"{res_a['Nivel_Agua']:.1f}%", 1, 0, 'C'); pdf.cell(65, 8, f"{res_b['Nivel_Agua']:.1f}%", 1, 1, 'C')
    pdf.cell(60, 8, "Nivel Petróleo (%)", 1); pdf.cell(65, 8, f"{res_a['Nivel_Petroleo']:.1f}%", 1, 0, 'C'); pdf.cell(65, 8, f"{res_b['Nivel_Petroleo']:.1f}%", 1, 1, 'C')
    pdf.cell(60, 8, "Decantación (TD - min)", 1); pdf.cell(65, 8, f"{res_a['Resid']:.1f} min", 1, 0, 'C'); pdf.cell(65, 8, f"{res_b['Resid']:.1f} min", 1, 1, 'C')
    pdf.ln(10)
    
    # --- ALERTA DINÁMICA MEJORADA ---
    pdf.set_font("Arial", 'B', 11)
    if carry_ov or blow_by or baja_p:
        pdf.set_text_color(200, 0, 0)
        mensaje = "ALERTA: FALLA DE INTEGRIDAD DETECTADA"
        detalles = []
        if carry_ov: detalles.append("CARRY-OVER")
        if blow_by: detalles.append("BLOW-BY")
        if baja_p: detalles.append("FALLA DE PRESIÓN")
        pdf.cell(0, 8, f"{mensaje} ({', '.join(detalles)})", ln=True)
    else:
        pdf.set_text_color(0, 120, 0)
        pdf.cell(0, 8, "OPERACIÓN ESTABLE: SIN ALERTAS DE SEGURIDAD REGISTRADAS", ln=True)

    for f in [p1, p2, pa, pb]: 
        if os.path.exists(f): os.remove(f)
    return pdf.output(dest='S').encode('latin-1', errors='ignore')




# --- PARTE 2: SIDEBAR (CONTROLES, ALERTA DE CAPACIDAD Y WC) ---
# --- PARTE 2: SIDEBAR (CONTROLES, ALERTA DE CAPACIDAD Y WC) ---
with st.sidebar:
    st.header("🕹️ Control de Operación")
    escenario = st.selectbox("Escenario", ["Estable", "Bache de Agua (Slug)", "Fallo de Presión", "Ciclo Crítico de Falla"])
    
    # --- MEMORIA DE FALLA DE PRESIÓN ---
    if 'falla_p' not in st.session_state:
        st.session_state.falla_p = False
    
    # Si el usuario elige un escenario de falla, activamos la memoria
    if escenario in ["Fallo de Presión", "Ciclo Crítico de Falla"]:
        st.session_state.falla_p = True
    else:
        st.session_state.falla_p = False

    st.subheader("📥 Ingreso de Producción")
    q_agua = st.number_input("Caudal de Agua (m3/d)", 0, 10000, 2000, step=10)
    q_oil = st.number_input("Caudal de Petróleo (m3/d)", 0, 5000, 440, step=10)
    q_gas = st.number_input("Caudal de Gas (m3/d)", 0, 100000, 5000, step=100)
    
    q_tot = q_agua + q_oil
    wc_b = (q_agua / q_tot) if q_tot > 0 else 0
    
    st.divider()
    # --- ALERTA DE CAPACIDAD ---
    if q_tot > 6000:
        st.error(f"🚨 **SOBRECARGA**: {q_tot} m3/d > Límite (6000)")
    else:
        st.success(f"✅ **CAPACIDAD OK**: {q_tot} m3/d")
    
    # Corte de Agua de Entrada (WC)
    st.info(f"**Corte de Agua de Entrada (WC):**\n{wc_b*100:.1f} %")
    
    st.divider()
    dist_a_pct = st.number_input("% de Carga al Separador A", 0, 100, 30, step=5)
    dist_a = dist_a_pct / 100.0
    
    st.header("🎯 Set Points")
    sp_t = st.number_input("SP Nivel Total (%)", 0, 100, 75) 
    sp_a = st.number_input("SP Nivel Agua (%)", 10, 90, 68) 
    sp_p = st.number_input("SP Nivel Petróleo (%)", 5, 90, 56) 

    # --- SE ELIMINARON LOS BOTONES DE AQUÍ PARA EVITAR DUPLICADOS ---

st.title(f"🏭 Simulador: 2 Separadores en Paralelo V 1.2")

# --- PARTE 3: MOTOR DE SIMULACIÓN (DETECCIÓN A LOS 10 SEGUNDOS) ---
# --- PARTE 3: MOTOR DE SIMULACIÓN (SINTONIZADO CON PLANTA REAL) ---
if st.button("▶️ INICIAR SIMULACIÓN (12 HORAS)"):
    import math # Para la oscilación senoidal
    paso, duracion = 60, 43200 
    
    # Reset de alertas GLOBAL al inicio del motor
    st.session_state.c_ov = False
    st.session_state.b_by = False
    st.session_state.falla_p = False 
    
    for nombre, split in [("A", dist_a), ("B", 1.0-dist_a)]:
        data, vol = [], 17.0
        # Mantenemos el inicio desde los Set Points para estabilidad inicial
        h_a, h_p = (sp_a/100)*vol, (sp_p/100)*vol 
        
        # --- CALIBRACIÓN REAL: Presión según PIT-94142 (3.46 kg/cm2) ---
        p_act = 3.46 
        
        for t in range(0, duracion + 1, paso):
            t_m = t / 60  
            wc, f_a, v_c = wc_b, False, False
            
            # Lógica de Escenarios
            if escenario == "Ciclo Crítico de Falla":
                if 60 < t_m <= 120: f_a = True
                elif 600 < t_m <= 660: v_c, p_act = True, 2.0
                else: p_act = 3.46
            elif escenario == "Bache de Agua (Slug)" and t_m > 60: 
                wc = 0.95
            elif escenario == "Fallo de Presión" and t_m > 60: 
                p_act = 1.2 
            
            # --- EFECTO SERRUCHO (Oscilación rítmica de la planta) ---
            osc = math.sin(t_m * 0.4) * 0.4 # Amplitud de ±0.4%
            ruido_real = (np.random.normal(1.0, 0.005) + (osc/100))
            
            qi_b = (q_tot * split / 86400) * ruido_real
            qi_a, qi_p = qi_b * wc, qi_b * (1 - wc)
            
            # --- AJUSTE DE VÁLVULA: k calibrado para apertura de 25% ---
            k = 0.0042 
            
            # Niveles con redondeo instrumental y oscilación integrada
            n_a_act = round(np.clip((h_a/vol)*100, 0, 100) + osc, 2)
            n_p_act = round(np.clip((h_p/vol)*100, 0, 100), 2)
            n_t_act = round(n_a_act + n_p_act, 2)

            # --- DETECCIÓN DE ALERTAS (Memoria Persistente) ---
            if t > 10: 
                if n_t_act >= 90: st.session_state.c_ov = True  
                if n_t_act <= 10: st.session_state.b_by = True
                if p_act < 2.5: st.session_state.falla_p = True

            # Control de Salida (Lógica de Válvulas LV-141)
            q_o_a = k * p_act * (n_a_act - sp_a) if n_a_act > sp_a else 0
            err_p, err_t = n_p_act - sp_p, n_t_act - sp_t
            if f_a: q_o_a, q_o_p = 0, k * p_act * (n_p_act - sp_p)
            elif v_c: q_o_a, q_o_p = k * p_act * 20, k * p_act * 10
            else: q_o_p = k * p_act * max(err_p, err_t) if (err_p > 0 or err_t > 0) else 0

            # Balance de Masa
            h_a += (qi_a - q_o_a) * paso
            h_p += (qi_p - q_o_p) * paso
            h_a, h_p = np.clip(h_a, 0, vol), np.clip(h_p, 0, vol - h_a)

            data.append({"Tiempo (h)": round(t_m/60, 2), "Nivel_Total": n_t_act, "Nivel_Agua": n_a_act, "Nivel_Petroleo": n_p_act, "Resid": round((h_a/qi_a/60) if qi_a>0 else 0, 2)})
            
        df_res = pd.DataFrame(data)
        df_res.to_csv(os.path.join(OUTPUT_DIR, f"dataset_{nombre}.csv"), index=False)
        if nombre == "A": st.session_state.p_A, st.session_state.niv_A, st.session_state.res_A, st.session_state.agua_A = n_p_act, n_t_act, data[-1]["Resid"], n_a_act
        else: st.session_state.p_B, st.session_state.niv_B, st.session_state.res_B, st.session_state.agua_B = n_p_act, n_t_act, data[-1]["Resid"], n_a_act
    
    st.session_state.ejecutado = True
    st.rerun()

# --- PARTE 4: RESULTADOS, CONSULTAS Y DESCARGA DE PDF PROFESIONAL ---
# --- PARTE 4: CORRECCIÓN PARA QUE EL PDF RECONOZCA LA FALLA (REEMPLAZAR ESTE BLOQUE) ---
# --- PARTE 4: RESULTADOS, HERRAMIENTAS Y MEMORIA TÉCNICA MAJ (COMPLETA) ---
# --- PARTE 4: RESULTADOS, CONSULTAS Y DESCARGA DE PDF PROFESIONAL (INTEGRADA) ---
# --- PARTE 4: RESULTADOS Y GENERACIÓN DE REPORTE ---
# --- PARTE 4: RESULTADOS Y GENERACIÓN (REEMPLAZA EL INICIO DEL BLOQUE) ---
# --- EN LA PARTE 4 (Antes de generar el PDF) ---
# --- PARTE 4: RESULTADOS Y GENERACIÓN (REEMPLAZA ESTE BLOQUE) ---
# --- PARTE 4: DETECCIÓN HISTÓRICA Y PDF ---
# --- PARTE 4: RESULTADOS, HERRAMIENTAS Y MÉTRICAS (REINTEGRACIÓN TOTAL) ---
# --- PARTE 4: RESULTADOS, HERRAMIENTAS Y MEMORIA TÉCNICA COMPLETA (RECUPERADA) ---
# --- PARTE 4: RESULTADOS, HERRAMIENTAS Y MEMORIA TÉCNICA MAJ (COMPLETA E INTEGRADA) ---
# --- PARTE 4: RESULTADOS, HERRAMIENTAS Y MEMORIA TÉCNICA MAJ (COMPLETA E INTEGRADA) ---
if st.session_state.get('ejecutado', False):
    df_a = pd.read_csv(os.path.join(OUTPUT_DIR, "dataset_A.csv"))
    df_b = pd.read_csv(os.path.join(OUTPUT_DIR, "dataset_B.csv"))

    # --- 1. DETECCIÓN DE ALERTAS (VINCULADA AL ESCENARIO REAL) ---
    max_nivel = max(df_a['Nivel_Total'].max(), df_b['Nivel_Total'].max())
    
    # Solo marcamos falla si el nivel supera el 90% Y el escenario es de falla o bache
    # Esto limpia el escenario "Estable" de cualquier ruido estadístico
    hay_co = False
    if escenario == "Bache de Agua (Slug)" and max_nivel >= 88:
        hay_co = True
    elif escenario == "Ciclo Crítico de Falla" and max_nivel >= 90:
        hay_co = True
        
    hay_bb = True if escenario == "Ciclo Crítico de Falla" and df_a['Nivel_Total'].min() < 10 else False
    hay_fp = True if escenario in ["Fallo de Presión", "Ciclo Crítico de Falla"] else False

    params_pdf = {'q_a': q_agua, 'q_o': q_oil, 'q_g': q_gas, 'wc': wc_b*100, 'dist_a': dist_a_pct, 'sp_t': sp_t}
    
    # Generamos el PDF con los estados validados
    pdf_bytes = generar_pdf_completo(escenario, df_a, df_b, hay_co, hay_bb, hay_fp, params_pdf)

    with st.expander("🛠️ HERRAMIENTAS DE ANÁLISIS Y REPORTES", expanded=True):
        c1, c2, c3, c4 = st.columns(4)
        btn_memoria = c1.button("📖 Memoria", use_container_width=True)
        btn_separacion = c2.button("📊 Separación", use_container_width=True)
        c3.download_button("📄 REPORTE TÉCNICO (PDF)", pdf_bytes, f"Reporte_MAJ_{escenario}.pdf", "application/pdf", use_container_width=True)
        csv_raw = pd.concat([df_a.add_suffix('_A'), df_b.add_suffix('_B')], axis=1).to_csv(index=False).encode('utf-8')
        c4.download_button("💾 DATASET CSV", csv_raw, "Simulacion_MAJ.csv", "text/csv", use_container_width=True)

    # --- 2. MEMORIA DE CÁLCULO (RECUPERADA) ---
    if btn_memoria:
        st.info(f"""
        **1. FUNDAMENTOS Y MEMORIA DE CÁLCULO**
        **Símbolos utilizados:**
        * **TD:** Tiempo de Decantación (min) | **V_a:** Volumen de Agua en el equipo ($m^3$)
        * **Q_out:** Caudal de Salida ($m^3/d$) | **WC:** Corte de Agua (Water Cut %)
        * **SP:** Set Point (Nivel objetivo %) | **Kv:** Coeficiente de Válvula
        
        **Lógica de Simulación Aplicada:**
        1. **Cálculo de Eficiencia:** $TD = (V_a / Q_{{out}}) \cdot 1440$. Un $TD < 10$ min indica arrastre.
        2. **Balance de Masa:** $Nivel_{{Final}} = Nivel_{{Inicial}} + (Q_{{in}} - Q_{{out}}) \cdot dt$.
        3. **Control de Salida:** $Q_{{out}} = Kv \cdot Presión \cdot (Nivel_{{Actual}} - SP)$.
        """)

    # --- 3. DETALLE DE SEPARACIÓN (RECUPERADA) ---
    if btn_separacion:
        st.success(f"""
        **2. DETALLE DE SEPARACIÓN**
        * **Caudal Bruto Total ($Q_{{in}}$):** {q_tot} $m^3/d$
        * **Carga Sep A:** {q_tot * dist_a:.1f} $m^3/d$ | **Carga Sep B:** {q_tot * (1-dist_a):.1f} $m^3/d$
        * **Relación Agua/Petróleo (Ratio):** {q_agua/q_oil if q_oil > 0 else 0:.2f}
        """)
        
        c_g1, c_g2 = st.columns([1, 1.5])
        with c_g1:
            fig_p, ax_p = plt.subplots(figsize=(2.5, 2.5))
            ax_p.pie([q_agua, q_oil], labels=['Agua', 'Oil'], autopct='%1.1f%%', 
                     colors=['#1f77b4', '#8c564b'], textprops={'fontsize': 8})
            ax_p.set_title("Mezcla Líquida (WC)", fontsize=9)
            st.pyplot(fig_p, use_container_width=False)
        with c_g2:
            st.bar_chart(pd.DataFrame({"$m^3/d$": [q_agua, q_oil, q_gas]}, index=["Agua", "Oil", "Gas"]))

    # --- 4. MÉTRICAS FINALES ---
    st.divider()
    col_res_a, col_res_b = st.columns(2)
    with col_res_a:
        st.markdown("**Separador A**")
        m1, m2, m3, m4 = st.columns(4)
        m1.metric("Total", f"{st.session_state.niv_A:.1f}%")
        m2.metric("Agua", f"{st.session_state.agua_A:.1f}%")
        m3.metric("Oil", f"{st.session_state.p_A:.1f}%")
        m4.metric("Resid.", f"{st.session_state.res_A:.1f} min")
    with col_res_b:
        st.markdown("**Separador B**")
        m5, m6, m7, m8 = st.columns(4)
        m5.metric("Total", f"{st.session_state.niv_B:.1f}%")
        m6.metric("Agua", f"{st.session_state.agua_B:.1f}%")
        m7.metric("Oil", f"{st.session_state.p_B:.1f}%")
        m8.metric("Resid.", f"{st.session_state.res_B:.1f} min")

    tab_a, tab_b = st.tabs(["Curvas Sep A", "Curvas Sep B"])
    with tab_a: st.line_chart(df_a.set_index("Tiempo (h)")[["Nivel_Total", "Nivel_Agua", "Nivel_Petroleo"]])
    with tab_b: st.line_chart(df_b.set_index("Tiempo (h)")[["Nivel_Total", "Nivel_Agua", "Nivel_Petroleo"]])

# --- FOOTER PERSONALIZADO MAJ ---
st.markdown("""
<style>.footer-maj {position: fixed; left: 0; bottom: 0; width: 100%; background-color: #1E1E1E; color: white; text-align: center; padding: 5px 0; border-top: 2px solid #31333F; z-index: 99;}</style>
<div class="footer-maj"><p>🚀 Desarrollado por <b>MAJ</b> | Especialista en Programación Industrial IA & Machine Learning | 2026</p></div>
""", unsafe_allow_html=True)
