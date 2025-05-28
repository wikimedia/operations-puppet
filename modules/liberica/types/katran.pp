# SPDX-License-Identifier: Apache-2.0
# katran forwarding plane configuration
# [*interface*]
#  Interface used to receive and send traffic
# [*conntrack_size*]
#  Size of the conntrack table
type Liberica::Katran = Struct[{
        'interface'        => String,
        'conntrack_size'   => Integer[0],
}]
