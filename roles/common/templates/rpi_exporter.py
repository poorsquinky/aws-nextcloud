#!/usr/bin/env python

import time
from prometheus_client.core import GaugeMetricFamily, REGISTRY, CounterMetricFamily
from prometheus_client import start_http_server
from gpiozero import CPUTemperature

class CustomCollector(object):
    def __init__(self):
        pass

    def collect(self):
        val = CPUTemperature()
        t = GaugeMetricFamily("rpi_cpu_temperature", "CPU Temperature", labels=['instance'])
        t.add_metric(['C'], val.temperature)
        yield t

        f = GaugeMetricFamily("rpi_cpu_temperature_f", "CPU Temperature", labels=['instance'])
        f.add_metric(['F'], val.temperature * (9.0/5.0) + 32)
        yield t

if __name__ == '__main__':
    start_http_server(7998)
    REGISTRY.register(CustomCollector())
    while True:
        time.sleep(1)
