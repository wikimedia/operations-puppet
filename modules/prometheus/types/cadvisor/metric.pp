# SPDX-License-Identifier: Apache-2.0
# List of valid metric classes for cadvisor, taken from --help.
# Can be updated with the following:
# cadvisor --help 2>&1 | grep -A1 enable_metrics \
#   | awk -Fare '{print $2}' | tr -d ' .' \
#   | awk -F ',' '{for (i=1; i<=NF; i++) printf "'\''%s'\''%s", $i, (i<NF ? ",\n" : "\n")}'

type Prometheus::Cadvisor::Metric = Enum[
    'accelerator',
    'advtcp',
    'app',
    'cpu',
    'cpuLoad',
    'cpu_topology',
    'cpuset',
    'disk',
    'diskIO',
    'hugetlb',
    'memory',
    'memory_numa',
    'network',
    'oom_event',
    'percpu',
    'perf_event',
    'process',
    'referenced_memory',
    'resctrl',
    'sched',
    'tcp',
    'udp',
]
