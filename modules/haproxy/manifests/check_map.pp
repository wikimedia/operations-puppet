# SPDX-License-Identifier: Apache-2.0
# @summary Provisions a script to validate map files
class haproxy::check_map () {
    file { '/usr/local/bin/check-haproxy-map':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/haproxy/check-haproxy-map.sh',
    }
}
