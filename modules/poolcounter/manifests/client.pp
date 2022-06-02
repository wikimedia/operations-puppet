# SPDX-License-Identifier: Apache-2.0
# Installs the base configuration file for running poolcounter-enabled
# applications.
class poolcounter::client(
    Wmflib::Ensure $ensure,
    Poolcounter::Backends $backends
) {
    $shardlist = $backends.map |$b| {
        "${b['label']}:${b['fqdn']}:1"
    }
    file { '/etc/poolcounter-backends.yaml':
        ensure  => $ensure,
        content => to_yaml($shardlist),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }
}
