FROM python:3.9

COPY py_naver_exporter.py /app/py_naver_exporter.py
COPY requirements.txt /app/requirements.txt
WORKDIR /app
RUN pip install -r requirements.txt
ENV HTTP_URL $HTTP_URL
ENV CHECK_INTERVAL $CHECK_INTERVAL
CMD ["python3", "/app/py_naver_exporter.py"]