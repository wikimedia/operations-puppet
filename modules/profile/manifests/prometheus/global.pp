# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::global {
    prometheus::server { 'global':
        ensure         => absent,
        listen_address => '127.0.0.1:9904',
    }

    prometheus::web { 'global':
        ensure     => absent,
        proxy_pass => 'http://localhost:9904/global',
    }
}
