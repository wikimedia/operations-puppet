#!/usr/bin/env python3
"""
A utility that check for the presence of a file and writes 0 or 1
to a file to be exported by node-exporter.
"""

import os
import argparse
from prometheus_client.core import GaugeMetricFamily
from prometheus_client.exposition import generate_latest
import traceback


class MetricsCollection(list):
    def collect(self):
        for x in self:
            yield x


def write_file(path, generated_metrics):
    with open(path, 'w') as f:
        f.write(generated_metrics)


def validate_config(config):
    if not config.outfile and not config.debug:
        raise ValueError('--outfile must be defined.')


def main(config):
    errors_count = 0
    metrics = MetricsCollection()
    count_metric = GaugeMetricFamily(
        config.metric.replace('-', '_').replace(' ', '_'),
        'presence of a file',
        labels=['path']
    )
    for path in config.paths:
        try:
            count_metric.add_metric(value=int(os.path.exists(path)), labels=[path])
        except OSError:
            errors_count += 1
            if config.debug:
                print(traceback.format_exc())
    metrics.append(count_metric)
    generated_metrics = generate_latest(metrics).decode()
    if config.debug:
        print(generated_metrics)
    else:
        write_file(config.outfile, generated_metrics)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--outfile', default=None)
    parser.add_argument('--debug', action='store_true')
    parser.add_argument('--metric', default='node_file_flag')
    parser.add_argument('paths', nargs='+')
    args = parser.parse_args()
    validate_config(args)
    main(args)
