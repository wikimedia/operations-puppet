# Define: conftool::scripts::service
#
# Installs helper scripts to semi-reliably pool and depool a service host
#
# === Parameters
#
# [*lvs_name*] The name of the service in lvs terms. Defaults to $title
#
# [*lvs_services_config*] The service configuration for lvs.
#
# [*lvs_class_hosts*] The hash with lvs-class => hostnames equivalence
#
define conftool::scripts::service(
    $lvs_services_config,
    $lvs_class_hosts,
    $lvs_name=$title,
){
    require ::conftool::scripts
    $lvs_config = $lvs_services_config[$lvs_name]

    if $lvs_config {
        $service = $lvs_config['conftool']['service']
        $port = pick($lvs_config['port'], 80)
        $hostnames = $lvs_class_hosts[$lvs_config['class']]
        $lvs_ips = inline_template(
            "<%= @hostnames.map{|h| scope.function_ipresolve([h])}.join(',') %>")
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

        file { "/usr/local/bin/restart-${title}":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => template('conftool/restart-service.erb'),
        }
    }
}
