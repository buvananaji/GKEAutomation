FROM python:3.13-slim
WORKDIR /app
COPY app.py .
USER nobody
EXPOSE 8080
CMD ["python", "-u", "app.py"]
