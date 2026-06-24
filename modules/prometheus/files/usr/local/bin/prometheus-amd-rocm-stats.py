#!/usr/bin/python3

import argparse
import json
import logging
import sys
import subprocess
import os

from prometheus_client import CollectorRegistry, Gauge, write_to_textfile
from prometheus_client.exposition import generate_latest

log = logging.getLogger(__name__)


def get_gpu_stats(registry):
    """Helper function to create the Prometheus config."""
    gpu_stats = {}

    gpu_stats['usage'] = Gauge(
        'usage_percent', 'GPU usage percent', ['card'],
        namespace='amd_rocm_gpu', registry=registry
    )
    gpu_stats['partition_usage'] = Gauge(
        'partition_usage_percent', 'Per-partition GPU usage percent', ['card'],
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

    return gpu_stats


# amd-smi misreports VRAM on partitioned (CPX) MI300X GPUs (ROCm/ROCm#4750):
# the *primary* partition of each card (partition_id 0) reports the whole
# card's total and used VRAM instead of its own slice, while the remaining
# partitions report correctly. We therefore take the per-partition VRAM total
# from the KFD topology (correct for every partition, unlike the SMI tools and
# the PCI mem_info_* sysfs, which both report the whole card on the primary
# partition) and the used VRAM from amd-smi. For the primary partition, whose
# reported "used" is the whole-card figure, we reconstruct its real usage by
# subtracting its sibling partitions. The amd-smi GPU index is mapped to its
# KFD node and card UUID via `amd-smi list`.
MIB = 1024 * 1024


def kfd_vram_total_bytes(node_id):
    """Per-partition VRAM total (bytes) from the KFD topology for a node.

    Sums the framebuffer memory banks (heap_type 1 == HEAP_TYPE_FB_PUBLIC).
    This is the authoritative per-partition total: it is correct for every
    partition even when the SMI tools report the whole card. Returns None if
    nothing could be read.
    """
    banks_dir = '/sys/class/kfd/kfd/topology/nodes/{}/mem_banks'.format(node_id)
    total = 0
    found = False
    try:
        banks = os.listdir(banks_dir)
    except OSError:
        return None
    for bank in banks:
        props = {}
        try:
            with open('{}/{}/properties'.format(banks_dir, bank)) as f:
                for line in f:
                    fields = line.split()
                    if len(fields) == 2:
                        props[fields[0]] = fields[1]
        except OSError:
            continue
        if props.get('heap_type') == '1' and 'size_in_bytes' in props:
            try:
                total += int(props['size_in_bytes'])
                found = True
            except ValueError:
                continue
    return total if found else None


def amd_smi_mib_to_bytes(mem_usage, field):
    """Return amd-smi mem_usage[field] as bytes, or None if unavailable.

    amd-smi reports these values in MiB (labelled "MB" in its JSON).
    """
    value = mem_usage.get(field)
    if isinstance(value, dict) and isinstance(value.get('value'), (int, float)):
        return int(round(value['value'] * MIB))
    return None


def amd_smi_value(field):
    """Return the numeric 'value' from an amd-smi metric field, else None.

    Many amd-smi metric fields are either the string "N/A" or a dict like
    {"value": <number>, "unit": ...}.
    """
    if isinstance(field, dict) and isinstance(field.get('value'), (int, float)):
        return field['value']
    return None


def amd_smi_partition_map(amd_smi_path):
    """Map amd-smi GPU index -> its `amd-smi list` record (bdf, node_id, ...).

    Returns an empty dict on failure.
    """
    try:
        out = subprocess.run(
            [amd_smi_path, "list", "--json"], capture_output=True, text=True)
        records = json.loads(out.stdout)
    except (OSError, ValueError) as e:
        log.warning("Could not read 'amd-smi list --json': {}".format(e))
        return {}
    return {rec['gpu']: rec for rec in records if 'gpu' in rec}


def amd_smi_used_vram_bytes(amd_smi_path):
    """Per-partition used VRAM (bytes), summed from amd-smi's per-process list.

    amd-smi's aggregate VRAM usage is reported in the whole-board address frame
    on each card's primary partition (ROCm/ROCm#4750), but the per-process VRAM
    figures are attributed to the correct partition. Summing them therefore
    yields a correct per-partition used value for every partition, including the
    primary. Returns {gpu_index: used_bytes}, or None if data is unavailable.
    """
    try:
        out = subprocess.run(
            [amd_smi_path, "process", "--json"], capture_output=True, text=True)
        records = json.loads(out.stdout)
    except (OSError, ValueError) as e:
        log.warning("Could not read 'amd-smi process --json': {}".format(e))
        return None
    used = {}
    for record in records:
        if not isinstance(record, dict) or record.get('gpu') is None:
            continue
        total = 0
        process_list = record.get('process_list')
        # Idle partitions report a placeholder string instead of a process list.
        if isinstance(process_list, list):
            for entry in process_list:
                info = entry.get('process_info') if isinstance(entry, dict) else None
                if not isinstance(info, dict):
                    continue
                vram = info.get('memory_usage', {}).get('vram_mem', {})
                value = vram.get('value') if isinstance(vram, dict) else None
                if isinstance(value, (int, float)):
                    total += int(value)
        used[record['gpu']] = total
    return used


def collect_stats_from_amd_smi(registry, amd_smi_path):
    """Run the amd-smi tool to gather GPU metrics, to then render them in Prometheus format."""
    out = subprocess.run([
        amd_smi_path, "metric", "--json"
    ], capture_output=True, text=True)
    rocm_metrics = {}
    rocm_metrics = json.loads(out.stdout)
    log.debug(
        "Metrics retrieved from amd-smi's json: {}"
        .format(rocm_metrics))

    gpu_stats = get_gpu_stats(registry)
    gpu_map = amd_smi_partition_map(amd_smi_path)
    used_vram = amd_smi_used_vram_bytes(amd_smi_path)
    # (uuid, partition_id) -> card index, used to place the primary partition's
    # per-XCP usage breakdown onto the correct partition's card.
    partition_card = {
        (rec.get('uuid'), rec.get('partition_id')): card
        for card, rec in gpu_map.items()
    }

    # First pass: emit non-memory metrics and gather per-partition memory facts.
    # All memory values are in bytes. VRAM total comes from the KFD topology
    # (correct per partition); VRAM/GTT used come from amd-smi (correct except
    # for the whole-card figure on each card's primary partition).
    mem_facts = {}
    for gpu_settings in rocm_metrics['gpu_data']:
        card = gpu_settings['gpu']
        # See https://github.com/ROCm/amdsmi/issues/134
        if isinstance(gpu_settings['usage'], dict):
            gpu_stats['usage'].labels(card=card).set(gpu_settings['usage']['gfx_activity']['value'])
        else:
            if gpu_settings['usage'] != 'N/A':
                gpu_settings['usage'].labels(card=card).set(
                    gpu_settings['usage'].strip())

        # Per-partition GFX activity. The device-level gfx_activity above is the
        # whole-card figure (reported only on the primary partition). The same
        # primary also carries a per-XCP breakdown (gfx_busy_inst.xcp_<id>)
        # covering every partition on the physical card; secondaries report
        # usage as "N/A". Each xcp_<id> is an array of per-XCC values; in CPX a
        # partition owns one XCD, so the first populated entry is its usage.
        usage = gpu_settings.get('usage')
        if isinstance(usage, dict) and isinstance(usage.get('gfx_busy_inst'), dict):
            uuid = gpu_map.get(card, {}).get('uuid')
            for xcp_key, xccs in usage['gfx_busy_inst'].items():
                try:
                    partition_id = int(xcp_key.rsplit('_', 1)[1])
                except (IndexError, ValueError):
                    continue
                value = None
                if isinstance(xccs, list):
                    for xcc in xccs:
                        value = amd_smi_value(xcc)
                        if value is not None:
                            break
                target = partition_card.get((uuid, partition_id))
                if value is not None and target is not None:
                    gpu_stats['partition_usage'].labels(card=target).set(value)

        # Temperature, power and fan are physical-card properties: amd-smi
        # reports them only on each card's primary partition (the others read
        # "N/A"), so emitting where a real value exists yields one reading per
        # physical card. amd-smi's sensor names are mapped onto the locations
        # used by the rocm-smi path so MI300X and older GPUs share labels.
        temperature = gpu_settings.get('temperature', {})
        if isinstance(temperature, dict):
            for amd_key, location in (
                    ('edge', 'edge'), ('hotspot', 'junction'), ('mem', 'mem')):
                value = amd_smi_value(temperature.get(amd_key))
                if value is not None:
                    gpu_stats['temperature'].labels(
                        card=card, location=location).set(value)

        power = gpu_settings.get('power', {})
        if isinstance(power, dict):
            value = amd_smi_value(power.get('socket_power'))
            if value is not None:
                gpu_stats['power'].labels(card=card).set(value)

        fan = gpu_settings.get('fan', {})
        if isinstance(fan, dict):
            value = amd_smi_value(fan.get('usage'))
            if value is not None:
                gpu_stats['fan'].labels(card=card).set(value)

        entry = gpu_map.get(card, {})
        node_id = entry.get('node_id')
        mem_usage = gpu_settings.get('mem_usage', {})
        mem_facts[card] = {
            'vram_total': kfd_vram_total_bytes(node_id) if node_id is not None else None,
            'gtt_total': amd_smi_mib_to_bytes(mem_usage, 'total_gtt'),
            'gtt_used': amd_smi_mib_to_bytes(mem_usage, 'used_gtt'),
        }

    # Emit memory metrics (bytes). On MI300X the visible VRAM equals the total
    # VRAM, so 'vis' mirrors 'vram'.
    #
    # VRAM total comes from the KFD topology (correct for every partition).
    # VRAM used is summed from amd-smi's per-process accounting: amd-smi's
    # aggregate 'mem_usage' reports the whole card on each card's primary
    # partition (ROCm/ROCm#4750), but the per-process VRAM figures are attributed
    # to the correct partition, so summing them is correct for every partition.
    # Note this counts process allocations only, so an idle partition reads ~0
    # rather than the driver's baseline reservation.
    for card, facts in mem_facts.items():
        total = facts['vram_total']
        if total is not None:
            for memtype in ('vram', 'vis'):
                gpu_stats['memory_total'].labels(
                    card=card, memtype=memtype).set(total)
        else:
            log.warning("No per-partition VRAM total for card {}".format(card))

        if used_vram is not None:
            used = used_vram.get(card, 0)
            for memtype in ('vram', 'vis'):
                gpu_stats['memory_used'].labels(
                    card=card, memtype=memtype).set(used)
        else:
            log.warning("No per-partition VRAM used for card {}".format(card))

        # GTT (host memory) is not affected by the partitioning bug; amd-smi
        # only reports it on the primary partition, so emit it when present.
        if facts['gtt_total'] is not None:
            gpu_stats['memory_total'].labels(
                card=card, memtype='gtt').set(facts['gtt_total'])
        if facts['gtt_used'] is not None:
            gpu_stats['memory_used'].labels(
                card=card, memtype='gtt').set(facts['gtt_used'])


def collect_stats_from_rocm_smi(registry, rocm_smi_path):
    """Run the rocm-smi tool to gather GPU metrics, to then render them in Prometheus format."""
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

    gpu_stats = get_gpu_stats(registry)

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
                if rocm_metrics[card][metric].strip() in ["0", "N/A"]:
                    continue
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
    if os.path.basename(args.rocm_smi_path) == 'amd-smi':
        collect_stats_from_amd_smi(registry, args.rocm_smi_path)
    else:
        collect_stats_from_rocm_smi(registry, args.rocm_smi_path)

    if args.outfile:
        write_to_textfile(args.outfile, registry)
    else:
        sys.stdout.write(generate_latest(registry).decode('utf-8'))


if __name__ == "__main__":
    sys.exit(main())
