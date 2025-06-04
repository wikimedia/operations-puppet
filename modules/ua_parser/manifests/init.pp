# SPDX-License-Identifier: Apache-2.0
class ua_parser {
    file { '/etc/ua-parser':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Source: https://raw.githubusercontent.com/ua-parser/uap-core/6772d7bdf6176ed80d58b929f0c4aa6eab3dc97a/regexes.yaml
    # Last update: 20/03/2025
    file { '/etc/ua-parser/regexes.yaml':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/ua_parser/regexes.yaml',
    }
}
