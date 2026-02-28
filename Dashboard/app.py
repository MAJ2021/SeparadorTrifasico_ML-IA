import streamlit as st
import pandas as pd

st.title("Simulación del Separador Trifásico")

# Botón de actualización
if st.button("Actualizar datos"):
    df = pd.read_csv("data/resultados.csv")
    st.success("Datos actualizados correctamente.")
else:
    df = pd.read_csv("data/resultados.csv")

# Mostrar tabla
st.write("Resultados de la simulación:")
st.dataframe(df)

# Mostrar gráfico
st.line_chart(df.set_index("tiempo"))

# Botón de descarga
csv = df.to_csv(index=False).encode("utf-8")
st.download_button(
    label="Descargar resultados en CSV",
    data=csv,
    file_name="resultados.csv",
    mime="text/csv",
)