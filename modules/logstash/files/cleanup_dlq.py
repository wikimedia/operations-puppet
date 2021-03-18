#!/usr/bin/env python3
"""
Tool to clear the dead letter queue and restart logstash when the queue gets within N% of
dead_letter_queue.max_bytes.

This tool is a hack to work around https://github.com/elastic/logstash/issues/8795.

If a better option should come available, this utility should be discarded.
"""
import argparse
from datetime import datetime, timedelta
import json
import pathlib
import subprocess
from wmflib import config

DATA_UNITS = {'kb': 10 ** 3, 'mb': 10 ** 6, 'gb': 10 ** 9, 'tb': 10 ** 12}
TIME_UNITS = {'m': 60, 'h': 60 ** 2, 'd': 60 ** 2 * 24}
STATE_FILE = '/tmp/manage_dlq_state.json'
DEFAULT_DLQ_PATH = '/var/lib/logstash/dead_letter_queue'
DEFAULT_MAX_BYTES = '1024mb'
GLOB_PATTERN = '*.log'


def in_bytes(x: str) -> int:
    """
    Converts human-friendly data size string to size in bytes.

    Example. '1024mb' -> 1024000000000
    """
    unit = x[-2:].lower()
    if DATA_UNITS.get(unit) is not None:
        return int(x[:-2]) * DATA_UNITS[unit]
    # if there is no unit provided, assume bytes
    # raises ValueError if x cannot be cast to int
    return int(x)


def remove_queue_files(file_path: pathlib.Path, dry_run: bool) -> None:
    """ Removes all non-hidden files from directory. """
    if dry_run:
        print('NOOP: Running "rm {}"'.format(file_path))
    else:
        for f in file_path.glob(GLOB_PATTERN):
            f.unlink()


def restart_service(systemd_unit: str, dry_run: bool) -> None:
    """ Restarts the service """
    if dry_run:
        print('NOOP: {} restarted'.format(systemd_unit))
    else:
        write_state({'date': {'last_restarted': datetime.utcnow()}})
        subprocess.run(['/usr/bin/systemctl', 'restart', systemd_unit])


def read_state() -> dict:
    """ Reads the saved state file and pre-parses date entries. """
    try:
        with open(STATE_FILE, 'r') as f:
            parsed = json.load(f)
    except (FileNotFoundError, json.decoder.JSONDecodeError):
        parsed = {}

    for key, value in parsed.get('date', {}).items():
        parsed['date'][key] = datetime.fromisoformat(value)
    return parsed


def write_state(state: dict) -> None:
    """ Writes the provided dictionary to the state file """
    for key, value in state.get('date').items():
        state['date'][key] = value.isoformat()
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f)


def main(args):
    last_restarted = read_state().get('date', {}).get('last_restarted')
    if last_restarted is not None:
        if args.dry_run:
            print('Last restarted {}'.format(last_restarted.isoformat()))
        if last_restarted + timedelta(seconds=args.limit) >= datetime.utcnow():
            return  # Was restarted recently

    logstash_settings = config.load_yaml_config(args.config)
    dlq_path = pathlib.Path(logstash_settings.get('path.dead_letter_queue', DEFAULT_DLQ_PATH))
    dlq_max_size = in_bytes(
        logstash_settings.get('dead_letter_queue.max_bytes', DEFAULT_MAX_BYTES)) * args.percent
    schedule_restart = False

    for pipeline in dlq_path.iterdir():
        total_size = sum(
            [x.stat().st_size for x in pipeline.glob(GLOB_PATTERN) if x.resolve().is_file()])
        if total_size >= dlq_max_size:
            remove_queue_files(pipeline, args.dry_run)
            schedule_restart = True

    if schedule_restart:
        restart_service(args.systemd_unit, args.dry_run)


def percentage_factor(x: str) -> float:
    """ Argparse percentage factor type and validation """
    x = x[:-1] if x[-1] == '%' else x
    factor = int(x) / 100
    if 0 < factor < 1:
        return factor
    raise ValueError('Percent must be greater than 0% and less than 100%.')


def in_seconds(x: str) -> int:
    """ Argparse human-friendly time limit type and validation """
    unit = x[-1].lower()
    if TIME_UNITS.get(unit) is not None:
        return int(x[:-1]) * TIME_UNITS[unit]
    # if there is no unit provided, assume seconds
    # raises ValueError if x cannot be cast to int
    return int(x)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Manage Logstash DLQ size')
    parser.add_argument('--systemd_unit', default='logstash.service',
                        help='Logstash systemd unit. default logstash.service')
    parser.add_argument('--config', default='/etc/logstash/logstash.yml',
                        help='Logstash config file. default: /etc/logstash/logstash.yml')
    parser.add_argument('--percent', default='80%', type=percentage_factor,
                        help='Remove queue files at this percentage of max_bytes. default: 80%%')
    parser.add_argument('--limit', default='1h', type=in_seconds,
                        help='Limit restart to only run once every this timespan. default: 1h')
    parser.add_argument('--dry-run', action='store_true', default=False,
                        help='Do not execute cleanup or restart actions.')
    main(parser.parse_args())
