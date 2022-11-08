# SPDX-License-Identifier: Apache-2.0
class profile::failoid {
    # As last rule reject all TCP traffic
    ferm::rule { 'failoid-reject_all_tcp':
        rule => 'proto tcp REJECT;',
        prio => '99',
    }
}
