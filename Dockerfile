# --- ETAPA 1: Constructor (Builder) ---
FROM python:3.11-slim AS builder

WORKDIR /app

# Instalar herramientas necesarias para compilar paquetes de Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Instalar dependencias en una ruta específica para copiarlas luego
COPY Simulacion/requirements.txt .
RUN pip install --upgrade pip && \
    pip install --user --no-cache-dir -r requirements.txt

# --- ETAPA 2: Ejecución (Runtime) ---
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/root/.local/bin:$PATH" \
    PYTHONPATH="/app"  
    # <-- IMPORTANTE: Esto permite importar entre carpetas

WORKDIR /app

COPY --from=builder /root/.local /root/.local

# Copia TODAS las carpetas necesarias
COPY Dashboard/ ./Dashboard/
COPY Simulacion/ ./Simulacion/
COPY Machine_Learning/ ./Machine_Learning/  
# <-- ESTA FALTABA
# Aseguramos permisos en la base de datos para que el script pueda escribir
RUN mkdir -p /app/DataBase && chmod 777 /app/DataBase

EXPOSE 8501
EXPOSE 8502

# Tip: Si vas a usar los CSV generados en el puerto 8501 dentro del app.py del 8502, 
# asegúrate de que ambos apunten a /app/DataBase/
CMD ["sh", "-c", "streamlit run Simulacion/dataset_generador_v52_2.py --server.port=8501 --server.address=0.0.0.0 & streamlit run Dashboard/app.py --server.port=8502 --server.address=0.0.0.0"]