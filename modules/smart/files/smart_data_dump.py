#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import collections
import json
import logging
import re
import subprocess
import shlex
import sys

from logging.handlers import SysLogHandler
from prometheus_client import CollectorRegistry, Gauge, write_to_textfile
from prometheus_client.exposition import generate_latest


log = logging.getLogger(__name__)

HPSA_CONTROLLER = collections.namedtuple('HPSA_CONTROLLER', ['name', 'target', 'disks', 'type'])
"""
    Represents an hpsa controller.

    HPSA controllers group all of their physical disks behind scsi generic devices.  When there are
    multiple controllers, the device ids (passed to `smartctl -d`) conflict and overwrite one
    another.  To get around this, we will replace the smartctl type option with the device
    target according to the controller at render time.

    name: str - the host adapter identifier.
    target: str - the device to query. (e.g. /dev/sg0, /dev/sda)
    disks: dict - map of serial to 'port:box:bay'
    type: str - parameter passed to smartctl -d. For hpsa, this is almost always 'cciss'.
"""

DISK = collections.namedtuple('DISK', ['name', 'target', 'type'])
"""
    Represents a standard disk.

    For cases where the physical disk and target handle are the same.

    name: str - the physical device identifier.
    target: str - the device to query. (e.g. /dev/sg0, /dev/sda)
    type: str|None - parameter passed to smartctl -d.  Default: 'auto'
"""

SMART_DATA = collections.namedtuple(
    'SMART_DATA', ['name', 'healthy', 'model', 'firmware', 'attributes']
)
"""
    A container for passing parsed smart data.

    name: str - the physical device identifier
    healthy: int - is the device healthy?
    model: str - the device model number
    firmware: str - the device firmware version
    attributes: dict - key:value collection of parsed attributes (c.f. REPORT_ATTRIBUTES)
"""

# Parse and report these attributes (lowercased) as gauges
REPORT_ATTRIBUTES = [
    'airflow_temperature_cel',
    'available_reservd_space',
    'command_timeout',
    'crc_error_count',
    'current_pending_sector',
    'ecc_error_rate',
    'end_to_end_error',
    'erase_fail_count',
    'erase_fail_count_total',
    'g_sense_error_rate',
    'hardware_ecc_recovered',
    'host_reads_32mib',
    'host_reads_mib',
    'host_writes_32mib',
    'host_writes_mib',
    'load_cycle_count',
    'media_wearout_indicator',
    'nand_writes_1gib',
    'offline_uncorrectable',
    'power_cycle_count',
    'power_on_hours',
    'program_fail_cnt_total',
    'program_fail_count',
    'program_fail_count_chip',
    'raw_read_error_rate',
    'read_soft_error_rate',
    'reallocated_event_count',
    'reallocated_sector_ct',
    'reported_uncorrect',
    'sata_downshift_count',
    'spin_retry_count',
    'spin_up_time',
    'start_stop_count',
    'temperature_celsius',
    'total_lbas_read',
    'total_lbas_written',
    'udma_crc_error_count',
    'uncorrectable_error_cnt',
    'unsafe_shutdown_count',
    'unused_rsvd_blk_cnt_tot',
    'used_rsvd_blk_cnt_tot',
    'wear_leveling_count',
    'workld_host_reads_perc',
    'workld_media_wear_indic',
    'workload_minutes',
]

# Do not log these attributes as "unreported" (i.e. found but not in REPORT_ATTRIBUTES)
IGNORE_ATTRIBUTES = [
    'calibration_retry_count',
    'multi_zone_error_rate',
    'power-off_retract_count'
    'reallocated_event_count',
    'seek_error_rate',
    'seek_time_performance',
    'throughput_performance',
]


def _check_output(cmd, timeout=60, suppress_errors=False, stderr=subprocess.STDOUT):
    """Executes the command with a timeout and cleans up the response."""
    cmd = shlex.split('/usr/bin/timeout {} {}'.format(timeout, cmd))
    try:
        return subprocess.check_output(cmd, stderr=stderr) \
            .decode(encoding='utf-8', errors='ignore').strip()
    except subprocess.CalledProcessError as e:
        if suppress_errors:
            return e.output.decode(encoding='utf-8', errors='ignore').strip()
        log.exception(e)
        raise


def get_raid_drivers():
    """Ask facter script for the raid drivers. Return the fact's value or None."""
    command = '/usr/bin/ruby /var/lib/puppet/lib/facter/raid.rb'
    raw_output = _check_output(command, timeout=120, stderr=subprocess.DEVNULL)
    try:
        fact_value = json.loads(raw_output).get('raid', None)
    except ValueError:
        return None

    log.debug('Fact raid discovered: %r', fact_value)
    return fact_value


def megaraid_list_pd():
    """List physical disks attached to megaraid controller. Generator to yield PD objects."""
    try:
        raw_output = _check_output('/usr/sbin/smartctl --scan-open')
    except subprocess.CalledProcessError:
        log.exception('Failed to scan for megaraid physical disks')
        return

    return megaraid_parse(raw_output)


def megaraid_parse(response):
    for line in response.splitlines():
        if 'megaraid,' not in line:
            continue
        if line.startswith('#'):
            continue
        bus, _, name, _ = line.split(' ', 3)
        yield DISK(name=name, target=bus, type=name)  # smartctl expects type to match name


def hpsa_list_pd():
    """List physical disks attached to hpsa controller."""
    try:
        raw_output = _check_output('/usr/sbin/hpssacli controller all show config detail')
    except subprocess.CalledProcessError:
        log.exception('Failed to scan for hpsa physical disks')
        return
    return hpsa_parse(raw_output, lsscsi_list_dev())


def hpsa_parse(response, lsscsi=None):
    """
    Parse the hpssacli response.

    When lsscsi data is available, extract the target by looking for a matching sas address.
    """
    if lsscsi is None:
        lsscsi = {}
    data = {}
    controller = address = serial = None
    for line in response.splitlines():
        # get controller
        m = re.match(r'^Smart (Array|HBA) ([A-Za-z0-9]*) in Slot (\d+)', line)
        if m:
            address = serial = None
            controller = line
            data[controller] = {'disks': {}, 'target': None}
        # get target from lsscsi if sas address is present
        m = re.match(r'^ {9}SAS Address: ([A-F0-9]+)', line)
        if m:
            target = lsscsi.get(m.group(1).lower())
            if target is not None:
                data[controller]['target'] = target
        # get address from physical drive
        m = re.match(r'^ {6}physicaldrive ([A-Z0-9:]+)$', line)
        if m:
            address = m.group(1)
        # get serial number from physical drive
        m = re.match(r'^ {9}Serial Number: ([A-Z0-9]+)$', line)
        if m:
            serial = m.group(1)
        # add disks to model
        if controller and address and serial:
            data[controller]['disks'][serial] = address
            address = serial = None
    return [HPSA_CONTROLLER(name=name, target=controller.get('target'),
                            disks=controller.get('disks'), type='cciss')
            for name, controller in data.items()]


def lsscsi_list_dev():
    """List scsi devices."""
    return lsscsi_parse(_check_output('/usr/bin/lsscsi -t -g'))


def lsscsi_parse(response):
    """Parse output of lsscsi and return a mapping of sas address to device target."""
    output = {}
    for line in response.splitlines():
        line = line.strip()
        if line == '':
            continue
        if line[0] == '#':
            continue
        while '  ' in line:
            line = line.replace('  ', ' ')
        if 'storage' in line:
            m = re.match(r'.*sas:0x([0-9a-f]+).*(/dev/sg[0-9])', line)
            output[m.group(1)] = m.group(2)
    log.debug('lsscsi response: {}'.format(output))
    return output


def noraid_list_pd():
    """List all physical disks. Generator to yield PD objects."""
    try:
        # We use --nodeps to exclude paritions or dependent devices
        raw_output = _check_output('/bin/lsblk --nodeps --output NAME,TYPE,VENDOR --json')
    except subprocess.CalledProcessError:
        log.exception('Failed to scan for directly attached physical disks')
        return
    return noraid_parse(raw_output)


def noraid_parse(response):
    blk_devs = json.loads(response)['blockdevices']
    for blk_dev in blk_devs:
        if blk_dev['type'] != 'disk':
            continue
        if blk_dev['name'].startswith('drbd') or blk_dev['name'].startswith('nbd'):
            continue
        # The vendor value returned by lsblk is a fixed width string of 8 chars,
        # with space padding on the right.
        # iDRAC may expose USB block devices to the host, but we do not care
        # about their smart status
        if blk_dev['vendor'] is not None and blk_dev['vendor'].rstrip() == 'iDRAC':
            continue
        # lsblk will report "nvme0n1", but smartctl wants the base "nvme0" device
        name = re.sub(r'^(nvme[0-9])n[0-9]$', r'\1', blk_dev['name'])
        yield DISK(name=name, target='/dev/{}'.format(name), type=None)


def collect_smart_metrics(devices, metrics):
    """Collect SMART metrics from list of devices into Prometheus registry."""
    for dev in devices:
        if isinstance(dev, HPSA_CONTROLLER):
            for smart_data in _handle_controller(dev):
                log.debug(smart_data)
                collect_smart_data(smart_data, metrics)
        else:
            smart_data = _handle_disk(dev)
            log.debug(smart_data)
            collect_smart_data(smart_data, metrics)


def collect_smart_data(smart_data, metrics):
    metrics.get('smart_health').labels(smart_data.name).set(smart_data.healthy)
    metrics.get('device_info').labels(smart_data.name, smart_data.model, smart_data.firmware) \
        .set(1)
    for metric_name, metric_value in smart_data.attributes.items():
        metrics.get(metric_name).labels(smart_data.name).set(metric_value)


def _handle_disk(disk):
    cmd = '/usr/sbin/smartctl --info --health -d {} {}'.format(disk.type or 'auto', disk.target)
    smart_info = _check_output(cmd, suppress_errors=True)
    healthy, model, firmware, serial = _parse_smart_info(smart_info)
    cmd = '/usr/sbin/smartctl --attributes -d {} {}'.format(disk.type or 'auto', disk.target)
    attribute_info = _check_output(cmd, suppress_errors=True)
    return SMART_DATA(healthy=healthy, model=model, firmware=firmware, name=disk.name,
                      attributes=_parse_smart_attributes(attribute_info))


def _handle_controller(controller):
    output = []
    for disk_id in range(len(controller.disks)):
        disk_id = ','.join([controller.type, str(disk_id)])
        cmd = '/usr/sbin/smartctl --info --health -d {} {}'.format(disk_id, controller.target)
        smart_info = _check_output(cmd, suppress_errors=True)
        healthy, model, firmware, serial = _parse_smart_info(smart_info)
        cmd = '/usr/sbin/smartctl --attributes -d {} {}'.format(disk_id, controller.target)
        attribute_info = _check_output(cmd, suppress_errors=True)
        output.append(
            SMART_DATA(
                healthy=healthy, model=model, firmware=firmware,
                name=controller.disks.get(serial),  # get PORT:BOX:BAY representation
                attributes=_parse_smart_attributes(attribute_info)
            )
        )
    return output


def _parse_smart_attributes(response):
    in_attributes = False
    output = {}
    for line in response.splitlines():
        if line.startswith('ID#'):
            in_attributes = True
            continue

        if not in_attributes or not line:
            continue

        try:
            attribute_id, name, flag, value, worst, thresh, attribute_type, updated, when_failed, \
                raw_value = re.split(' +', line.strip(), 9)
        except ValueError as e:
            log.error('Unparseable line from smartctl: %r %r', e, line)
            continue

        metric_name = name.lower()
        # Normalize metric name from smartctl output to Prometheus-accepted names
        metric_name = metric_name.replace('-', '_')
        if metric_name not in REPORT_ATTRIBUTES:
            if metric_name not in IGNORE_ATTRIBUTES:
                log.info('Unreported attribute %r: %r', metric_name, line)
            continue

        try:
            metric_value = raw_value.split(' ')[0]
            output[metric_name] = metric_value
        except ValueError:
            log.error('Unparseable %r', line)
    return output


def _parse_smart_info(response):
    smart_healthy_value = 0
    model = 'NA'
    firmware = 'NA'
    serial = 'UNKNOWN'
    for line in response.splitlines():
        if ':' not in line:
            continue
        key, value = line.split(':', 1)
        key = key.lower()
        value = value.strip()

        if key in ('product', 'device model'):
            model = value
        if key in ('firmware version', 'revision'):
            firmware = value
        if key == 'serial number':
            serial = value
        m = re.match('^smart (overall-)?health', key)
        if m and value.lower() in ('ok', 'passed'):
            smart_healthy_value = 1
    return smart_healthy_value, model, firmware, serial


def get_metrics_cache(registry, namespace=''):
    """Returns a dict mapping attributes to their corresponding Metric instances."""
    output = {
        attribute: Gauge(attribute, 'SMART attribute %s' % attribute, namespace=namespace,
                         registry=registry, labelnames=['device']) for attribute in
        REPORT_ATTRIBUTES
    }
    output['smart_health'] = Gauge('healthy', 'SMART health', namespace=namespace,
                                   registry=registry, labelnames=['device'])
    output['device_info'] = Gauge('info', 'Disk info', namespace=namespace,
                                  registry=registry, labelnames=['device', 'model', 'firmware'])
    output['device_count'] = Gauge('device_count', 'Count of detected devices', namespace=namespace,
                                   registry=registry)
    return output


# TODO(filippo): handle mpt controllers
DRIVER_HANDLERS = {
    'megaraid': megaraid_list_pd,
    'hpsa': hpsa_list_pd,
}


def main():
    parser = argparse.ArgumentParser(description='Collect SMART information from all physical disks'
                                                 ' and report as Prometheus metrics')
    parser.add_argument('--outfile', metavar='FILE.prom',
                        help='Output file (stdout)')
    parser.add_argument('--syslog', action='store_true', default=False,
                        help='Log to syslog (%(default)s)')
    parser.add_argument('-d', '--debug', action='store_true', default=False,
                        help='Enable debug logging (%(default)s)')
    args = parser.parse_args()
    script_name = parser.prog

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.WARNING)

    if args.syslog:
        handler = SysLogHandler(address='/dev/log')
        handler.setFormatter(logging.Formatter(script_name + ': %(message)s'))
        root_logger = logging.getLogger()
        root_logger.handlers = []
        root_logger.addHandler(handler)

    if args.outfile and not args.outfile.endswith('.prom'):
        parser.error('Output file does not end with .prom')

    physical_disks = []

    raid_drivers = get_raid_drivers()
    if raid_drivers is None:
        log.error('Invalid value for "raid" fact: %r', raid_drivers)
        return 1

    for driver in raid_drivers:
        handler = DRIVER_HANDLERS.get(driver)
        if handler is None:
            continue
        for pd in handler():
            physical_disks.append(pd)

    # TODO(filippo): handle machines with disks attached to raid controllers _and_ regular sata
    if not raid_drivers or raid_drivers == ['md']:
        for pd in noraid_list_pd():
            physical_disks.append(pd)

    log.debug('Gathering SMART data from physical disks: %r', [x.name for x in physical_disks])

    registry = CollectorRegistry()
    metrics = get_metrics_cache(registry, 'device_smart')
    collect_smart_metrics(physical_disks, metrics)
    metrics['device_count'].set(len(physical_disks))

    if args.outfile:
        write_to_textfile(args.outfile, registry)
    else:
        sys.stdout.write(generate_latest(registry).decode('utf-8'))


if __name__ == '__main__':
    sys.exit(main())
