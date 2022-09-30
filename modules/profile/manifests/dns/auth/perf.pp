# SPDX-License-Identifier: Apache-2.0
# Perf tweaks that do not impact correctness
class profile::dns::auth::perf {
    # Enable TFO, which gdnsd-3.x supports by default if enabled
    sysctl::parameters { 'TCP Fast Open for AuthDNS':
        values => {
            'net.ipv4.tcp_fastopen' => 3,
        },
    }

    interface::rps { 'primary':
        interface => $facts['interface_primary'],
    }
}
