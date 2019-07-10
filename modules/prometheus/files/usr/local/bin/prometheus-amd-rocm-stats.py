#!/usr/bin/python3

import argparse
import json
import logging
import sys
import subprocess

from prometheus_client import CollectorRegistry, Gauge, write_to_textfile
from prometheus_client.exposition import generate_latest

log = logging.getLogger(__name__)


def collect_stats_from_romc_smi(registry):
    out = subprocess.run([
        '/opt/rocm/bin/rocm-smi', "--showuse", "--showpower",
        "--showtemp", "--showfan", "--json"
    ], capture_output=True, text=True)
    rocm_metrics = {}
    for line in out.stdout.splitlines():
        if line.startswith('{'):
            rocm_metrics = json.loads(line)
            log.debug(
                "Metrics retrieved from rocm-smi's json: {}"
                .format(rocm_metrics))
        else:
            log.debug(
                "Discarding line from rocm-smi's output: {}"
                .format(line))

    gpu_stats = {}
    gpu_stats['usage'] = Gauge(
        'usage_percent', 'GPU usage percent', ['card'],
        namespace='amd_rocm_gpu', registry=registry
    )
    gpu_stats['temperature'] = Gauge(
        'temperature_celsius', 'GPU temperature (in Celsius)',
        ['card'], namespace='amd_rocm_gpu', registry=registry
    )
    gpu_stats['power'] = Gauge(
        'power_consumption_watts', 'GPU power consumption (in Watts)',
        ['card'], namespace='amd_rocm_gpu', registry=registry
    )
    gpu_stats['fan'] = Gauge(
        'fan_usage_percent', 'GPU fan usage percent', ['card'],
        namespace='amd_rocm_gpu', registry=registry
    )

    for card in rocm_metrics:
        for metric in rocm_metrics[card]:
            if metric == 'Current GPU use':
                # format example: 0%
                gpu_stats['usage'].labels(card=card).set(
                    rocm_metrics[card][metric].rstrip('%'))
            elif metric == 'Temperature (Sensor #1)':
                # format example: 27.0 c
                gpu_stats['temperature'].labels(card=card).set(
                    rocm_metrics[card][metric].rstrip('c').strip())
            elif metric == 'Average Graphics Package Power':
                # format example: 7.0W
                gpu_stats['power'].labels(card=card).set(
                    rocm_metrics[card][metric].rstrip('W'))
            elif metric == 'Fan Level':
                # format example: 38 (14%)
                gpu_stats['fan'].labels(card=card).set(
                    rocm_metrics[card]['Fan Level'].split('(')[1].split('%')[0])
            else:
                log.warn(
                    "Metric {} listed in rocm-smi's JSON  but not parsed"
                    .format(metric))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--outfile', metavar='FILE.prom',
                        help='Output file (stdout)')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debug logging (false)')
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.WARNING)

    if args.outfile and not args.outfile.endswith('.prom'):
        parser.error('Output file does not end with .prom')

    registry = CollectorRegistry()
    collect_stats_from_romc_smi(registry)

    if args.outfile:
        write_to_textfile(args.outfile, registry)
    else:
        sys.stdout.write(generate_latest(registry).decode('utf-8'))


if __name__ == "__main__":
    sys.exit(main())
