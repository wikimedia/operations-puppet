#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import argparse
from pathlib import Path
from typing import List

from prometheus_client import (
    CollectorRegistry,
    Gauge,
    write_to_textfile
)


def get_nic_irqs(interface: str) -> List[str]:
    nic_irqs = []
    # /sys/class/net/{interface}/msi_irqs contains a file per IRQ
    for child in Path(f'/sys/class/net/{interface}/device/msi_irqs').iterdir():
        nic_irqs.append(child.name)

    interrupts = Path('/proc/interrupts').read_text()
    queue_irqs = []
    for line in interrupts.split('\n'):
        line = line.strip()
        for nic_irq in nic_irqs:
            if line.startswith(f'{nic_irq}:') and interface in line:
                fields = line.split()
                if len(fields) > 0:
                    irq_id = fields[-1]
                    # we get 1 IRQ per queue plus an extra IRQ mapped to the interface itself
                    # we only need the IRQs mapped to the interface queues
                    if irq_id == interface:
                        break
                    queue_irqs.append(nic_irq)
                # one IRQ per line, continue with the next line
                break

    queue_irqs.sort()
    return queue_irqs


def get_cpus_from_irqs(irqs: List[str]) -> List[str]:
    cpu_set = set()
    for irq in irqs:
        affinity_hex = Path(f'/proc/irq/{irq}/smp_affinity').read_text().strip()
        affinity_hex = affinity_hex.replace(',', '')
        affinity_mask = int(affinity_hex, 16)
        max_bit = affinity_mask.bit_length()
        irq_cpu_list = [i for i in range(max_bit) if affinity_mask & (1 << i)]
        cpu_set.update(irq_cpu_list)

    return list(cpu_set)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-o',
                        '--outfile',
                        nargs='?',
                        type=Path,
                        default='/var/lib/prometheus/node.d/node-nic-queue-cpu.prom')
    parser.add_argument('-i',
                        '--interface',
                        required=True,
                        type=str,
                        help="Interface name")
    registry = CollectorRegistry()
    gauge = Gauge('node_nic_queue_cpu_assigned',
                  'CPUs assigned to handle NIC queues', ['cpu', 'interface'], registry=registry)

    args = parser.parse_args()

    nic_irqs = get_nic_irqs(args.interface)
    nic_cpus = get_cpus_from_irqs(nic_irqs)
    for nic_cpu in nic_cpus:
        gauge.labels(nic_cpu, args.interface).set(1)

    write_to_textfile(args.outfile, registry)
