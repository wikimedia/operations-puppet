#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
A utility that exposes the file age (UNIX time of the last modification)
to a file to be exported by node-exporter.
"""

import argparse
import os
import traceback

from prometheus_client.core import CounterMetricFamily
from prometheus_client.exposition import generate_latest


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
    count_metric = CounterMetricFamily(
        config.metric.replace('-', '_').replace(' ', '_'),
        'file age (UNIX time of the last modification)',
        labels=['path']
    )
    for path in config.paths:
        try:
            value = int(os.path.getmtime(path))
            count_metric.add_metric(value=value, labels=[path])
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
    parser.add_argument('--metric', default='node_file_age_timestamp_seconds')
    parser.add_argument('paths', nargs='+')
    args = parser.parse_args()
    validate_config(args)
    main(args)
