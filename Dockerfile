FROM python:3.11-slim

WORKDIR /app

# Copiar código fuente desde el contexto raíz
COPY Dashboard/ /app/Dashboard/
COPY Simulacion/ /app/Simulacion/

# Copiar requirements desde Simulacion
COPY Simulacion/requirements.txt /app/

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Crear carpeta de datos dentro del contenedor
RUN mkdir -p /app/DataBase

# Comando por defecto: lanzar Streamlit
CMD ["streamlit", "run", "Simulacion/dataset_generator_v50_1.py", "--server.port=8501", "--server.address=0.0.0.0"]