FROM python:3.11-slim

# Evita que Python genere archivos .pyc y permite logs en tiempo real
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Instalar dependencias primero para aprovechar el caché de capas de Docker
COPY Simulacion/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar el código fuente
COPY Dashboard/ ./Dashboard/
COPY Simulacion/ ./Simulacion/

# Crear carpeta para persistencia de datos
RUN mkdir -p /app/DataBase

# Exponer el puerto de Streamlit
EXPOSE 8501

# Ejecutar usando la ruta relativa al WORKDIR
CMD ["streamlit", "run", "Simulacion/dataset_generator_v50_1.py", "--server.port=8501", "--server.address=0.0.0.0"]