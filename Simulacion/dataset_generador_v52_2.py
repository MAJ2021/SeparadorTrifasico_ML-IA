import pandas as pd
import numpy as np
import streamlit as st
import os
import math
import matplotlib.pyplot as plt
from fpdf import FPDF

# ==========================================
# 1. CONFIGURACIÓN Y PERSISTENCIA (V1.3)
# ==========================================
# =========================================================
# 1. CONFIGURACIÓN Y FUNCIÓN DE REPORTE TÉCNICO V1.3 (ORDEN CORREGIDO)
# =========================================================
OUTPUT_DIR = "DataBase"
if not os.path.exists(OUTPUT_DIR): 
    os.makedirs(OUTPUT_DIR)

st.set_page_config(page_title="Simulador: 2 Separadores en Paralelo V 1.3", layout="wide")

# Inicialización de estados de sesión
if 'ejecutado' not in st.session_state: st.session_state.ejecutado = False
if 'c_ov' not in st.session_state: st.session_state.c_ov = False
if 'b_by' not in st.session_state: st.session_state.b_by = False
if 'falla_p' not in st.session_state: st.session_state.falla_p = False

# --- FUNCIÓN: GENERAR REPORTE TÉCNICO PDF ---
def generar_pdf_completo(esc, df_a, df_b, carry_ov, blow_by, baja_p, params):
    pdf = FPDF()
    
    # --- PÁGINA 1: ESPECIFICACIONES Y MEMORIA TÉCNICA ---
    pdf.add_page()
    pdf.set_font("Arial", 'B', 16)
    pdf.cell(0, 10, "MEMORIA DE CÁLCULO Y PROTOCOLO DE INGENIERÍA", ln=True, align='C')
    pdf.set_font("Arial", 'B', 10); pdf.set_text_color(100)
    pdf.cell(0, 10, f"CONFIGURACIÓN: SEPARADORES EN PARALELO DE CUBA INDEPENDIENTE", ln=True, align='C')
    pdf.set_text_color(0); pdf.ln(5); pdf.line(10, 35, 200, 35); pdf.ln(5)

    # 1. ESPECIFICACIONES TÉCNICAS DEL EQUIPO
    pdf.set_font("Arial", 'B', 11); pdf.set_fill_color(230, 230, 230)
    pdf.cell(0, 8, "1. DESCRIPCIÓN TÉCNICA DEL SISTEMA", ln=True, fill=True)
    pdf.set_font("Arial", '', 9)
    pdf.multi_cell(0, 5, 
        "El sistema consta de dos unidades de separación horizontal trifásica de cuba independiente. "
        "Esta configuración permite un control de nivel de interfaz y nivel total autónomo para cada recipiente, "
        "optimizando el tiempo de residencia hidráulico (TRH) mediante un lazo de control proporcional."
    )
    pdf.ln(3)

    # 2. FUNDAMENTOS MATEMÁTICOS (MEMORIA DE CÁLCULO) - AHORA PUNTO 2
    pdf.set_font("Arial", 'B', 11); pdf.cell(0, 8, "2. MODELADO MATEMÁTICO Y DINÁMICA DE PROCESO", ln=True, fill=True)
    pdf.set_font("Arial", '', 9)
    pdf.multi_cell(0, 5, 
        "A. MODELO DE FLUJO: Se aplica el modelo de Flujo de Pistón (Plug Flow Model) para el cálculo del TRH.\n"
        "B. BALANCE DE MASA DIFERENCIAL: dV/dt = Q_in(t) - Q_out(t). Se resuelve mediante integración numérica "
        "para capturar perturbaciones transitorias como baches de agua (slugs).\n"
        "C. SEPARACIÓN DE FASES (LEY DE STOKES): La velocidad de sedimentación de la gota crítica se calcula como:\n"
        "   Vs = [g * d^2 * (dens_agua - dens_oil)] / (18 * visc_oil)"
    )
    pdf.ln(3)

    # 3. DETALLE DE SEPARACIÓN Y OBSERVACIÓN DINÁMICA - AHORA PUNTO 3
    pdf.set_font("Arial", 'B', 11); pdf.cell(0, 8, "3. DETALLE DE SEPARACIÓN Y CARGA DINÁMICA", ln=True, fill=True)
    pdf.set_font("Arial", '', 9)
    
    res_a, res_b = df_a.iloc[-1], df_b.iloc[-1]
    q_total_calc = params['q_a'] + params['q_o']
    carga_a = q_total_calc * params['dist_a']
    carga_b = q_total_calc * (1 - params['dist_a'])
    ratio_ap = round(params['q_a'] / params['q_o'], 2) if params['q_o'] > 0 else 0

    if esc == "Bache de Agua (Slug)":
        obs_ingenieria = (f"Se detectó un bache de agua crítico. El Separador B manejó una carga bruta de "
                          f"{carga_b:.1f} m3/d. El sistema de control proporcional estabilizó la interfaz "
                          f"en {res_b['Nivel_Agua']:.1f}% con un TRH final de {res_b['Resid']:.1f} min.")
    elif esc == "Fallo de Presión":
        obs_ingenieria = (f"La caída de presión afectó la descarga. Con un ratio de {ratio_ap}, se observa una "
                          f"acumulación de inventario líquido en el Separador B llegando al {res_b['Nivel_Total']:.1f}%.")
    else:
        obs_ingenieria = (f"Operación nominal con Ratio {ratio_ap}. Los tiempos de residencia (TRH) en la "
                          f"unidad crítica B ({res_b['Resid']:.1f} min) garantizan una separación eficiente.")

    pdf.multi_cell(0, 5, 
        f"Caudal Bruto Total (Qin): {q_total_calc} m3/d\n"
        f"Carga Sep A: {carga_a:.1f} m3/d | Carga Sep B: {carga_b:.1f} m3/d\n"
        f"Relación Agua/Petróleo (Ratio): {ratio_ap}\n\n"
        f"OBSERVACIÓN TÉCNICA: {obs_ingenieria}"
    )
    pdf.ln(3)

    # 4. PARÁMETROS DE DISEÑO SELECCIONADOS
    pdf.set_font("Arial", 'B', 11); pdf.cell(0, 8, "4. CONDICIONES DE OPERACIÓN Y SET POINTS", ln=True, fill=True)
    pdf.set_font("Arial", '', 9)
    col_w = 48
    pdf.cell(col_w, 7, "Caudal Agua:", 1); pdf.cell(col_w, 7, f"{params['q_a']} m3/d", 1)
    pdf.cell(col_w, 7, "Caudal Oil:", 1); pdf.cell(col_w, 7, f"{params['q_o']} m3/d", 1, 1)
    pdf.cell(col_w, 7, "Corte de Agua:", 1); pdf.cell(col_w, 7, f"{params['wc']:.1f}%", 1)
    pdf.cell(col_w, 7, "Carga Sep A:", 1); pdf.cell(col_w, 7, f"{params['dist_a']*100:.0f}%", 1, 1)
    pdf.cell(col_w, 7, "SP Nivel Total:", 1); pdf.cell(col_w, 7, f"{params['sp_t']}%", 1)
    pdf.cell(col_w, 7, "Escenario:", 1); pdf.cell(col_w, 7, f"{esc}", 1, 1)

    # 5. TENDENCIAS SEPARADOR A
    pdf.ln(5); pdf.set_font("Arial", 'B', 11); pdf.cell(0, 8, "5. ANÁLISIS DINÁMICO: SEPARADOR A", ln=True, fill=True)
    img_a = os.path.join(os.getcwd(), "DataBase", "reporte_sep_a.png")
    if os.path.exists(img_a): pdf.image(img_a, x=15, y=pdf.get_y()+5, w=180)

    # --- PÁGINA 2: SEPARADOR B Y RESULTADOS ---
    pdf.add_page()
    pdf.ln(5); pdf.set_font("Arial", 'B', 11); pdf.cell(0, 8, "6. ANÁLISIS DINÁMICO: SEPARADOR B", ln=True, fill=True)
    img_b = os.path.join(os.getcwd(), "DataBase", "reporte_sep_b.png")
    if os.path.exists(img_b): 
        pdf.image(img_b, x=15, y=pdf.get_y()+5, w=180)
        pdf.ln(95)

    # 7. EVALUACIÓN DE RESULTADOS
    pdf.set_font("Arial", 'B', 11); pdf.cell(0, 8, "7. RESULTADOS FINALES Y BALANCE COMPARATIVO", ln=True, fill=True)
    pdf.set_font("Arial", 'B', 9)
    pdf.cell(60, 7, "Métrica Final", 1); pdf.cell(65, 7, "Separador A", 1); pdf.cell(65, 7, "Separador B", 1, 1)
    pdf.set_font("Arial", '', 9)
    pdf.cell(60, 7, "Nivel Total (%)", 1); pdf.cell(65, 7, f"{res_a['Nivel_Total']:.1f}%", 1); pdf.cell(65, 7, f"{res_b['Nivel_Total']:.1f}%", 1, 1)
    pdf.cell(60, 7, "TRH Agua (min)", 1); pdf.cell(65, 7, f"{res_a['Resid']:.1f} min", 1); pdf.cell(65, 7, f"{res_b['Resid']:.1f} min", 1, 1)

    return pdf.output(dest='S').encode('latin-1', errors='replace')


# ==========================================
# 2. SIDEBAR (CONTROLES Y LÓGICA DE GAS)
# ==========================================

# --- TÍTULO PRINCIPAL ---
st.title("🏭 Simulador: 2 Separadores en Paralelo V 1.3")

with st.sidebar:
    st.header("🕹️ Control de Operación")
    escenario = st.selectbox(
        "Escenario",
        ["Estable", "Bache de Agua (Slug)", "Fallo de Presión", "Ciclo Crítico de Falla"]
    )
    
    # 1. INICIALIZACIÓN DE SEGURIDAD (Evita NameError en cualquier escenario)
    falla_input, hora_falla_slug, duracion_slug = 90, 0, 0
    hora_reposicion, t_norm = 24, 30
    hora_falla_p, hora_recup_p = 6.0, 10.0
    p_sistema, p_falla = 3.46, 1.2
    h_inicio_critico, h_recup_critico, crecimiento, frec_olas = 4.0, 9.0, 0.15, 4.0

    # 2. CONFIGURACIÓN SEGÚN ESCENARIO
    if escenario == "Bache de Agua (Slug)":
        st.subheader("⚠️ Configuración de Falla/Mezcla")
        falla_input = st.number_input("Punto de Mezcla Total (%)", 80, 100, 90)
        if falla_input > 90: st.error(f"🚨 **AVISO CRÍTICO**: Carry-over al gas.")
        hora_falla_slug = st.number_input("Hora de inicio bache (h)", 0, 12, 4)
        duracion_slug   = st.number_input("Duración bache (min)", 1, 120, 30)
        hora_reposicion = st.number_input("Hora reposicion (h)", 0, 12, 6)
        t_norm          = st.number_input("Tiempo de normalización (min)", 15, 30)

    elif escenario == "Fallo de Presión":
        st.subheader("📉 Parámetros de Presión")
        p_sistema = st.number_input("Presión Nominal (bar)", 2.0, 10.0, 3.46)
        p_falla   = st.number_input("Presión en Falla (bar)", 0.5, 3.0, 1.2)
        st.divider()
        st.subheader("⏳ Tiempos del Evento")
        hora_falla_p = st.number_input("Inicio de la Falla (h)", 0.0, 12.0, 5.0)
        hora_recup_p = st.number_input("Hora de Recuperación (h)", 0.0, 12.0, 9.0)

    elif escenario == "Ciclo Crítico de Falla":
        st.subheader("🌀 Configuración de Ciclo Crítico")
        h_inicio_critico = st.number_input("Inicio Inestabilidad (h)", 0.0, 12.0, 4.0)
        h_recup_critico  = st.number_input("Recuperación del Ciclo (h)", 0.0, 12.0, 9.0)
        crecimiento = st.slider("Crecimiento de Amplitud", 0.01, 0.50, 0.15)
        frec_olas = st.slider("Frecuencia (Ciclos/h)", 1.0, 10.0, 4.0)

    # 3. INGRESO DE PRODUCCIÓN (Baseline)
    st.divider()
    st.subheader("📥 Ingreso de Producción")
    q_agua = st.number_input("Caudal de Agua (m3/d)", 0, 10000, 2000)
    q_oil  = st.number_input("Caudal de Petróleo (m3/d)", 0, 5000, 440)
    q_gas  = st.number_input("Caudal de Gas (m3/d)", 0, 100000, 5000)

    q_tot = q_agua + q_oil
    wc_b  = (q_agua / q_tot) if q_tot > 0 else 0
       
    dist_a_pct = st.number_input("% de Carga al Separador A", 0, 100, 30)
    dist_a = dist_a_pct / 100.0
   
    st.divider()
    st.info(f"📊 **Producción Total:** {q_tot} m3/d  \n")
    st.info(f"💧 **WC:** {wc_b*100:.1f}%")

    # 4. SET POINTS (Baseline)
    st.divider()
    st.header("🎯 Set Points")
    sp_t = st.number_input("SP Nivel Total (%)", 0, 100, 75) 
    sp_a = st.number_input("SP Nivel Agua (%)", 10, 90, 68) 
    sp_p = st.number_input("SP Nivel Petróleo (%)", 5, 90, 56)


# =========================================================
# PARTE 3: MOTOR DE CÁLCULO (BASELINE + RUTAS IA GARANTIZADAS)
# =========================================================
# =========================================================
# PARTE 3: MOTOR DE CÁLCULO (ORIGINAL + ETIQUETA IA 0,1,2,3)
# =========================================================
if st.button("▶️ INICIAR SIMULACIÓN (12 HORAS)"):
    # 1. RUTAS ABSOLUTAS
    RUTA_ACTUAL = os.path.dirname(os.path.abspath(__file__)) 
    RUTA_RAIZ = os.path.dirname(RUTA_ACTUAL) 
    OUTPUT_DIR = os.path.join(RUTA_RAIZ, "DataBase")
    ML_DIR = os.path.join(RUTA_RAIZ, "Machine_Learning", "Datasets_Entrenamiento")
    os.makedirs(OUTPUT_DIR, exist_ok=True); os.makedirs(ML_DIR, exist_ok=True)

    # Diccionario de etiquetas para la IA
    mapa_escenarios = {"Estable": 0, "Bache de Agua (Slug)": 1, "Fallo de Presión": 2, "Ciclo Crítico de Falla": 3}
    id_esc = mapa_escenarios.get(escenario, 0)

    paso, duracion = 60, 12 * 3600
    for nombre, split in [("A", dist_a), ("B", 1.0 - dist_a)]:
        data, vol_total = [], 17.0
        h_entrada, h_agua, h_oil = (sp_t/100)*vol_total, (sp_a/100)*vol_total, (sp_p/100)*vol_total
        p_act_base, k_a, k_p = 3.46, 0.0042, 0.0042
        slug_activo, slug_finalizado = False, False
        h_falla_total, h_falla_agua, h_falla_oil = h_entrada, h_agua, h_oil

        for t in range(0, duracion + 1, paso):
            t_h = t / 3600
            
            if escenario == "Fallo de Presión":
                p_act = p_falla if (t_h >= hora_falla_p and t_h < hora_recup_p) else p_sistema
                if p_act == p_falla: st.session_state.falla_p = True
            else: p_act = 3.46

            if escenario == "Ciclo Crítico de Falla" and (t_h >= h_inicio_critico and t_h < h_recup_critico):
                delta_f = t_h - h_inicio_critico
                osc = (0.4 + (delta_f * crecimiento * 10)) * math.sin(2 * math.pi * frec_olas * t_h)
            else: osc = (math.sin(t_h * 0.4) * 0.4) + np.random.normal(0, 0.08)
            
            qi_b = (q_tot * split / 86400) * (np.random.normal(1.0, 0.005))
            qi_a, qi_p = qi_b * wc_b, qi_b * (1 - wc_b)

            if escenario == "Bache de Agua (Slug)":
                if math.isclose(t_h, hora_falla_slug, abs_tol=paso/3600) and not slug_activo: slug_activo = True
                if slug_activo and math.isclose(t_h, hora_falla_slug + duracion_slug/60, abs_tol=paso/3600):
                    nv = (h_entrada/vol_total)*100
                    if 80 <= nv < 90: h_agua, h_oil = h_entrada, h_entrada
                    elif nv >= 90: h_oil, h_agua = vol_total, h_entrada
                    slug_activo, slug_finalizado = False, True
                    h_falla_total, h_falla_agua, h_falla_oil = h_entrada, h_agua, h_oil
                if slug_activo: h_entrada = (falla_input / 100) * vol_total

            # Bifasicidad
            nv_g = (h_entrada / vol_total) * 100
            if 80 <= nv_g < 90: h_agua, h_oil = h_entrada, h_entrada
            elif nv_g >= 90: h_oil, h_agua = vol_total, h_entrada

            if slug_finalizado and t_h >= hora_reposicion:
                d_t = t_h - hora_reposicion
                if d_t <= (t_norm / 60):
                    f = d_t / (t_norm / 60)
                    h_entrada = h_falla_total*(1-f) + (sp_t/100)*vol_total*f
                    h_agua = h_falla_agua*(1-f) + (sp_a/100)*vol_total*f
                    h_oil = h_falla_oil*(1-f) + (sp_p/100)*vol_total*f

            n_t, n_a, n_p = round((h_entrada/vol_total)*100+osc,2), round((h_agua/vol_total)*100+osc*0.3,2), round((h_oil/vol_total)*100+osc,2)
            q_o_a = k_a * p_act * (n_a - sp_a) if n_a > sp_a else 0
            q_o_p = k_p * p_act * (n_p - sp_p) if (n_p > sp_p and not slug_activo) else 0
            
            h_entrada += (qi_b - (qi_a + qi_p)) * paso
            h_agua += (qi_a - q_o_a) * paso
            h_oil += (qi_p - q_o_p) * paso
            h_entrada, h_agua, h_oil = np.clip([h_entrada, h_agua, h_oil], 0.2, vol_total)

            # AGREGAMOS LA COLUMNA LABEL_ESCENARIO
            data.append({
                "Tiempo (h)": round(t_h, 2), 
                "Nivel_Total": n_t, 
                "Nivel_Agua": n_a, 
                "Nivel_Petroleo": n_p, 
                "Resid": round((h_agua / qi_a / 60) if qi_a > 0 else 0, 2),
                "Label_Escenario": id_esc
            })

        df_f = pd.DataFrame(data)
        df_f.to_csv(os.path.join(OUTPUT_DIR, f"dataset_{nombre}.csv"), index=False)
        ts = pd.Timestamp.now().strftime("%Y%m%d_%H%M")
        df_f.to_csv(os.path.join(ML_DIR, f"DATA_{nombre}_{escenario.replace(' ', '_')}_{ts}.csv"), index=False)

        if nombre == "A": st.session_state.niv_A, st.session_state.agua_A, st.session_state.p_A, st.session_state.res_A = n_t, n_a, n_p, data[-1]["Resid"]
        else: st.session_state.niv_B, st.session_state.agua_B, st.session_state.p_B, st.session_state.res_B = n_t, n_a, n_p, data[-1]["Resid"]
    
    st.session_state.ejecutado = True; st.rerun()





# ==========================================
# 4. RESULTADOS, MÉTRICAS Y VISUALIZACIÓN
# ==========================================
# ==========================================
# 4. RESULTADOS, MÉTRICAS Y VISUALIZACIÓN
# ==========================================
# PARCHE DE RUTAS PARA EVITAR NameError
BASE_PATH = os.getcwd() 
DATABASE_DIR = os.path.join(BASE_PATH, "DataBase")

if st.session_state.get('ejecutado', False):
    # Carga de datos procesados (Tu lógica original)
    df_a = pd.read_csv(os.path.join(DATABASE_DIR, "dataset_A.csv"))
    df_b = pd.read_csv(os.path.join(DATABASE_DIR, "dataset_B.csv"))
    
    # --- GENERACIÓN DE GRÁFICOS TÉCNICOS PARA PDF ---
    plt.style.use('bmh') 
    for n, df_proc in [("a", df_a), ("b", df_b)]:
        fig, ax = plt.subplots(figsize=(10, 4))
        ax.plot(df_proc['Tiempo (h)'], df_proc['Nivel_Total'], color='#1f77b4', linewidth=2, label='Nivel Total %')
        ax.plot(df_proc['Tiempo (h)'], df_proc['Nivel_Agua'], color='#2ca02c', linewidth=1.5, label='Nivel Agua %')
        ax.axhline(y=sp_t, color='red', linestyle='--', alpha=0.4, label='Set Point')
        ax.set_title(f"TENDENCIAS DINÁMICAS - SEPARADOR {n.upper()}", fontsize=12, fontweight='bold')
        ax.set_ylabel("Nivel (%)"); ax.set_xlabel("Tiempo (h)")
        ax.legend(loc='upper right', fontsize=8)
        fig.savefig(os.path.join(DATABASE_DIR, f"reporte_sep_{n}.png"), dpi=300, bbox_inches='tight')
        plt.close(fig)

    # --- 1. DETECCIÓN DE ALERTAS ---
    max_nivel_total = max(df_a['Nivel_Total'].max(), df_b['Nivel_Total'].max())
    hay_co_gas = True if max_nivel_total >= falla_input and falla_input > 90 else False
    hay_bb = True if df_a['Nivel_Total'].min() < 10 else False
    hay_fp = True if escenario == "Fallo de Presión" and st.session_state.falla_p else False
    hay_ciclo = True if escenario == "Ciclo Crítico de Falla" else False

    params_pdf = {'q_a': q_agua, 'q_o': q_oil, 'q_g': q_gas, 'wc': wc_b*100, 'dist_a': dist_a, 'sp_t': sp_t, 'sp_a': sp_a, 'sp_p': sp_p}
    pdf_bytes = generar_pdf_completo(escenario, df_a, df_b, hay_co_gas, hay_bb, hay_fp, params_pdf)

    # --- 2. HERRAMIENTAS Y REPORTES ---
    with st.expander("🛠️ HERRAMIENTAS Y DOCUMENTACIÓN TÉCNICA", expanded=True):
        c1, c2, c3 = st.columns(3)
        c1.download_button("📄 DESCARGAR REPORTE PDF", pdf_bytes, f"Reporte_{escenario}.pdf", "application/pdf", use_container_width=True)
        csv_raw = pd.concat([df_a.add_suffix('_A'), df_b.add_suffix('_B')], axis=1).to_csv(index=False).encode('utf-8')
        c2.download_button("💾 DESCARGAR CSV", csv_raw, "Dataset_Simulacion.csv", "text/csv", use_container_width=True)
        if c3.button("🔄 REINICIAR SIMULADOR", use_container_width=True):
            st.session_state.ejecutado = False
            st.rerun()

    # --- 3. MÉTRICAS CON ICONOS ---
    st.divider()
    col_res_a, col_res_b = st.columns(2)
    with col_res_a:
        st.subheader("Separador A")
        m1, m2, m3, m4 = st.columns(4)
        m1.metric("Total 📏", f"{st.session_state.niv_A:.1f}%")
        m2.metric("Agua 💧", f"{st.session_state.agua_A:.1f}%")
        m3.metric("Oil 🛢️", f"{st.session_state.p_A:.1f}%")
        m4.metric("Resid. ⏳", f"{st.session_state.res_A:.1f} min")
    with col_res_b:
        st.subheader("Separador B")
        m5, m6, m7, m8 = st.columns(4)
        m5.metric("Total 📏", f"{st.session_state.niv_B:.1f}%")
        m6.metric("Agua 💧", f"{st.session_state.agua_B:.1f}%")
        m7.metric("Oil 🛢️", f"{st.session_state.p_B:.1f}%")
        m8.metric("Resid. ⏳", f"{st.session_state.res_B:.1f} min")

    # --- 4. GRÁFICOS DE TENDENCIA ---
    st.divider()
    tab_a, tab_b = st.tabs(["📈 TENDENCIAS SEPARADOR A", "📈 TENDENCIAS SEPARADOR B"])
    with tab_a: st.line_chart(df_a.set_index("Tiempo (h)")[["Nivel_Total", "Nivel_Agua", "Nivel_Petroleo"]])
    with tab_b: st.line_chart(df_b.set_index("Tiempo (h)")[["Nivel_Total", "Nivel_Agua", "Nivel_Petroleo"]])


# Footer MAJ
st.markdown("""
<style>.footer-maj {position: fixed; left: 0; bottom: 0; width: 100%; background-color: #1E1E1E; color: white; text-align: center; padding: 5px 0; border-top: 2px solid #31333F; z-index: 99;}</style>
<div class="footer-maj"><p>🚀 Desarrollado por <b>MAJ</b> | Especialista en Programación Industrial IA & Machine Learning | 2026</p></div>
""", unsafe_allow_html=True)
