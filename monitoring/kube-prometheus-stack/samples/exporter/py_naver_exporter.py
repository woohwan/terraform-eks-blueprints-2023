#!/usr/bin/env python

import os
import requests
import time
from prometheus_client import start_http_server, Enum, Histogram

naver_health_status = Enum("naver_health_status", "connection health", states=["healthy", "unhealthy"])
naver_health_request_time = Histogram('naver_health_request_time', 'connection response time (seconds)')

def get_metrics():

    with naver_health_request_time.time():
        resp = requests.get(url=os.environ['HTTP_URL'])

    print(resp.status_code)

    if not (resp.status_code == 200):
        naver_health_status.state("unhealthy")

if __name__ == '__main__':
    start_http_server(9000)
    while True:
        get_metrics()
        time.sleep(int(os.environ['CHECK_INTERVAL']))
