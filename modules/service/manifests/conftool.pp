# Define: service::conftool
#
# Installs helper scripts to semi-reliably pool and depool a service host
#
# === Parameters
#
# [*port*]
#   The service's port
#
define service::conftool(
    $port,
) {

    include ::conftool::scripts

    file { "/usr/local/bin/pool-${title}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('service/conftool/pool-service.erb'),
    }

    file { "/usr/local/bin/depool-${title}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('service/conftool/depool-service.erb'),
    }

}
