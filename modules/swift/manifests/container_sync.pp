# SPDX-License-Identifier: Apache-2.0
class swift::container_sync (
    Hash[String, Hash] $accounts,
    Hash[String, Hash] $keys,
) {
    file { '/etc/swift/container-sync-realms.conf':
        ensure    => present,
        mode      => '0440',
        owner     => 'swift',
        group     => 'swift',
        content   => template('swift/container-sync-realms.conf.erb'),
        show_diff => false,
    }
}
