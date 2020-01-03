# === define etcd::client::config
# Allows to create an etcd config file that can be read by our own clients
#
# This file is by default owned by root and will not be world-readable
define etcd::client::config(
    Wmflib::Ensure         $ensure         = present,
    String[1]              $owner          = 'root',
    String[1]              $group          = 'root',
    Boolean                $world_readable = false,
    Etcd::Client::Settings $settings       = {},
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
        content => template('etcd/client_config.erb'),
    }
}
