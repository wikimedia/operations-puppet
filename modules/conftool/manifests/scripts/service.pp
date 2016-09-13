# Define: service::conftool
#
# Installs helper scripts to semi-reliably pool and depool a service host
#
# === Parameters
#
# [*port*]
#   The service's port
#
# TODO: move to conftool::script::service
define conftool::scripts::service(
    $lvs_config,
    $lvs_class_hosts,
    $lvs_name=$title,
    ) {
    require ::conftool::scripts
    $service = $lvs_config['service']
    $port = $lvs_config['port']
    $hostnames = $lvs_class_hosts[$lvs_config['class']]
    $lvs_ips = inline_template(
        "<%= @hostnames.map{|h| function_ipresolve([h])}.join(',') %>")
    file { "/usr/local/bin/pool-${title}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('conftool/pool-service.erb'),
    }

    file { "/usr/local/bin/depool-${title}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('conftool/depool-service.erb'),
    }

}
