FROM python:3.11-slim

WORKDIR /app

COPY ../Dashboard/ /app/

RUN pip install pandas numpy streamlit

CMD ["streamlit", "run", "dashboard_v50_1.py", "--server.port=8501", "--server.address=0.0.0.0"]