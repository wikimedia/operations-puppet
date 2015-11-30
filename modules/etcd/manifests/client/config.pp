# === define etcd::client::config
# Allows to create an etcd config file that can be read by our own clients
#
# This file is by default owned by root and will not be world-readable
define etcd::client::config(
    $ensure = present,
    $owner = 'root',
    $group = 'root',
    $world_readable = false,
    $settings = {
        username => undef,
        password => undef,
        host     => undef,
        port     => undef,
        srv_dns  => undef,
        ca_cert  => undef,
        protocol => undef,
    },
    ) {

    $file_perms = $world_readable ? {
        true    => '0444',
        default => '0440',
    }

    file { $title:
        ensure  => $ensure,
        owner   => $owner,
        group   => $group,
        mode    => $file_perms,
        content => oredered_yaml($settings),
    }
}
