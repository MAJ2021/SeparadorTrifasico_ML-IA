FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# --- PASO CRUCIAL: Instalar herramientas de compilación ---
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

COPY Simulacion/requirements.txt .

# Actualizar herramientas de empaquetado antes de instalar requirements
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

COPY Dashboard/ ./Dashboard/
COPY Simulacion/ ./Simulacion/
RUN mkdir -p /app/DataBase

EXPOSE 8501

CMD ["streamlit", "run", "Simulacion/dataset_generator_v50_1.py", "--server.port=8501", "--server.address=0.0.0.0"]