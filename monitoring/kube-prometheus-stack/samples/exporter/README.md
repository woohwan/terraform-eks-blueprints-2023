- https://rtfm.co.ua/en/prometheus-building-a-custom-prometheus-exporter-in-python/

- naver_health_expoert.py  환경변수
HTTP_URL: health check하려면 doamin (stirng)
CHECK_INTERVAL: check interval (int)

- docker
```
# build
docker build -t whpark70/naver-health-exporter

# run
docker run -p 9000:9000 -e HTTP_URL=https://naver.com -e CHECK_INTERVAL=5 whpark70/naver-health-exporter

# push
docker push whpark70/naver-health-exporter
```