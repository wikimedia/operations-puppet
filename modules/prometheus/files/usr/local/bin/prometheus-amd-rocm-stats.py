#!/usr/bin/python3

import argparse
import json
import logging
import sys
import subprocess

from prometheus_client import CollectorRegistry, Gauge, write_to_textfile
from prometheus_client.exposition import generate_latest

log = logging.getLogger(__name__)


def collect_stats_from_romc_smi(registry, rocm_smi_path):
    out = subprocess.run([
        rocm_smi_path, "--showuse", "--showpower",
        "--showtemp", "--showfan", "--showmeminfo", "all", "--json"
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
    gpu_stats['activity'] = Gauge(
        'activity_percent', 'GPU usage percent', ['card'],
        namespace='amd_rocm_gpu', registry=registry
    )
    gpu_stats['temperature'] = Gauge(
        'temperature_celsius', 'GPU temperature (in Celsius)',
        ['card', 'location'], namespace='amd_rocm_gpu', registry=registry
    )
    gpu_stats['power'] = Gauge(
        'power_consumption_watts', 'GPU power consumption (in Watts)',
        ['card'], namespace='amd_rocm_gpu', registry=registry
    )
    gpu_stats['fan'] = Gauge(
        'fan_usage_percent', 'GPU fan usage percent', ['card'],
        namespace='amd_rocm_gpu', registry=registry
    )

    gpu_stats['memory_total'] = Gauge(
        'memory_total_bytes', 'Total GPU memory (bytes)', ['card', 'memtype'],
        namespace='amd_rocm_gpu', registry=registry
    )
    gpu_stats['memory_used'] = Gauge(
        'memory_used_bytes', 'Used GPU memory (bytes)', ['card', 'memtype'],
        namespace='amd_rocm_gpu', registry=registry
    )
    for card in rocm_metrics:
        for metric in rocm_metrics[card]:
            # General usage
            if metric == 'GPU use (%)':
                # format example: 42
                gpu_stats['usage'].labels(card=card).set(
                    rocm_metrics[card][metric].strip())
            # It is unclear what "activity" means vis-a-vis usage, so for now
            # just drop it to squelch the fallthrough warning.
            # TODO(klausman): figure out what it means and either export it or
            # add note here on why we don't care.
            elif metric == "GFX Activity":
                continue
            # All temperature readings use the same format, e.g. 27.0
            # The old kernel-native driver has one temp reading:
            elif metric == 'Temperature (Sensor #1) (c)' \
                    or metric == 'Temperature (Sensor #1) (C)':
                gpu_stats['temperature'].labels(card=card, location="sensor1").set(
                    rocm_metrics[card][metric].strip())
            # The newer rocm-dkms driver has three separate readings:
            elif metric == 'Temperature (Sensor edge) (C)':
                gpu_stats['temperature'].labels(card=card, location="edge").set(
                    rocm_metrics[card][metric].strip())
            elif metric == 'Temperature (Sensor junction) (C)':
                gpu_stats['temperature'].labels(card=card, location="junction").set(
                    rocm_metrics[card][metric].strip())
            elif metric == 'Temperature (Sensor mem) (C)' \
                    or metric == 'Temperature (Sensor memory) (C)':
                gpu_stats['temperature'].labels(card=card, location="mem").set(
                    rocm_metrics[card][metric].strip())
            # Readings for the Instinct series include HBM sensors "HBM"
            # High-bandwidth memory. On the MI100, these seem to always be 0.
            # Since this might become useful at some point (and a reading of 0
            # is definitely not correct), we drop the metric if the value is 0
            # or N/A, and export it otherwise.
            elif metric.startswith('Temperature (Sensor HBM'):
                if rocm_metrics[card][metric].strip() in ["0", "N/A"]:
                    continue
                toks = metric.split()
                if len(toks) < 4:
                    # warning
                    log.warning(
                        "Metric '{}' listed in rocm-smi's JSON could not be parsed for HBM id"
                        .format(metric))
                    continue
                val = toks[3].rstrip(")")
                gpu_stats['temperature'].labels(card=card, location="hbm{}".format(val)).set(
                    rocm_metrics[card][metric].strip())
            # Power
            elif metric == 'Average Graphics Package Power (W)':
                # format example: 7.0
                gpu_stats['power'].labels(card=card).set(
                    rocm_metrics[card][metric].strip())

            # Fan speeds
            elif metric == 'Fan Speed (%)' \
                    or metric == 'Fan speed (%)':
                # format example: 14
                gpu_stats['fan'].labels(card=card).set(
                    rocm_metrics[card][metric].strip())
            elif metric in ['Fan Speed (level)', 'Fan speed (level)', 'Fan RPM']:
                # we care only about the percentage value
                continue

            # Memory
            # Total memory amounts, for percentage calculation with used memory
            # Note: there are two formats since we support multiple versions
            # of rocm-smi, once all nodes are on the same version we'll cleanup.
            elif metric == 'vram Total Memory (B)' \
                    or metric == 'VRAM Total Memory (B)':
                gpu_stats['memory_total'].labels(card=card, memtype='vram').set(
                    rocm_metrics[card][metric].strip())
            elif metric == 'gtt Total Memory (B)' \
                    or metric == 'GTT Total Memory (B)':
                gpu_stats['memory_total'].labels(card=card, memtype='gtt').set(
                    rocm_metrics[card][metric].strip())
            elif metric == 'vis_vram Total Memory (B)' \
                    or metric == 'VIS_VRAM Total Memory (B)':
                gpu_stats['memory_total'].labels(card=card, memtype='vis').set(
                    rocm_metrics[card][metric].strip())
            # Used memory amounts
            elif metric == 'vram Total Used Memory (B)' \
                    or metric == 'VRAM Total Used Memory (B)':
                gpu_stats['memory_used'].labels(card=card, memtype='vram').set(
                    rocm_metrics[card][metric].strip())
            elif metric == 'gtt Total Used Memory (B)' \
                    or metric == 'GTT Total Used Memory (B)':
                gpu_stats['memory_used'].labels(card=card, memtype='gtt').set(
                    rocm_metrics[card][metric].strip())
            elif metric == 'vis_vram Total Used Memory (B)' \
                    or metric == 'VIS_VRAM Total Used Memory (B)':
                gpu_stats['memory_used'].labels(card=card, memtype='vis').set(
                    rocm_metrics[card][metric].strip())

            # Unknown stuff should emit a warning (to be delivered by cron mail)
            else:
                log.warning(
                    "Metric '{}' listed in rocm-smi's JSON but not parsed"
                    .format(metric))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--outfile', metavar='FILE.prom',
                        help='Output file (stdout)')
    parser.add_argument('--rocm-smi-path', metavar='/opt/rocm/bin/rocm-smi',
                        default='/opt/rocm/bin/rocm-smi',
                        help='Full path of the rocm-smi tool')
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
    collect_stats_from_romc_smi(registry, args.rocm_smi_path)

    if args.outfile:
        write_to_textfile(args.outfile, registry)
    else:
        sys.stdout.write(generate_latest(registry).decode('utf-8'))


if __name__ == "__main__":
    sys.exit(main())
