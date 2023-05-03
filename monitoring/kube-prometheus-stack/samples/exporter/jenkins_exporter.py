#! /usr/bin/env python

import time
import random
from prometheus_client import start_http_server, Gauge
from api4jenkins import Jenkins

jenkins_client = Jenkins('http://localhost:8080', auth=('admin','admin'))

jenkins_jobs_counter = Gauge('jenkins_jobs_count', "Number of Jenkins Jobs")

def get_metrics():
    jenkins_jobs_counter.set(len(list(jenkins_client.iter_jobs())))

if __name__ == '__main__':
    start_http_server(9000)
    while True:
        get_metrics()
        time.sleep(15)