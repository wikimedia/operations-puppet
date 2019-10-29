#!/usr/bin/env python3
"""
A utility that non-recursively counts the number of files in a directory
and writes the file count to a file to be exported by node-exporter.
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


def count_files(path):
    """ Non-recursive file count excluding directories. """
    files = [x for x in os.listdir(path) if os.path.isfile(os.path.join(path, x))]
    return len(files)


def validate_config(config):
    if not config.outfile and not config.debug:
        raise ValueError('--outfile must be defined.')


def init_metrics(name):
    count_metric = GaugeMetricFamily(
        name,
        'count of files in directory',
        labels=['path']
    )
    errors_metric = GaugeMetricFamily(
        'node_filecount_errors_total',
        'total errors in scrape'
    )
    return count_metric, errors_metric


def main(config):
    errors_count = 0
    metrics = MetricsCollection()
    count_metric, errors_metric = init_metrics(config.metric)
    for path in config.paths:
        try:
            count_metric.add_metric(value=count_files(path), labels=[path])
        except OSError:
            errors_count += 1
            if config.debug:
                print(traceback.format_exc())
    errors_metric.add_metric(value=errors_count, labels=[])
    metrics.append(count_metric)
    metrics.append(errors_metric)
    generated_metrics = generate_latest(metrics).decode()
    if config.debug:
        print(generated_metrics)
    else:
        write_file(config.outfile, generated_metrics)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--outfile', default=None)
    parser.add_argument('--debug', action='store_true')
    parser.add_argument('--metric', default='node_files_total')
    parser.add_argument('paths', nargs='+')
    args = parser.parse_args()
    validate_config(args)
    main(args)
