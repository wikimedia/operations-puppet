# SPDX-License-Identifier: Apache-2.0
# katran forwarding plane configuration
# [*forwarding_cores*]
#  List of CPU cores used to handle forwarding traffic duties
# [*numa_node*]
#  NUMA node of the CPU cores listed on forwarding_cores
# [*interface*]
#  Interface used to receive and send traffic
# [*conntrack_size*]
#  Size of the conntrack table
type Liberica::Katran = Struct[{
        'forwarding_cores' => Array[Integer],
        'numa_node'        => Integer[0],
        'interface'        => String,
        'conntrack_size'   => Integer[0],
}]
