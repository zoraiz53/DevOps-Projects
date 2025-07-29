FROM python:3.10-slim

WORKDIR /app
COPY app.py .

RUN pip install flask && \
    mkdir -p /app/logs && \
    chmod a+rwx /app/logs

EXPOSE 80

CMD ["python", "app.py"]
