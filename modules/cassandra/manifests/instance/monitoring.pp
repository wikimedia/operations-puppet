# == Define: cassandra::instance::monitoring
#
# Configures monitoring for Cassandra
#
# === Usage
# cassandra::instance::monitoring { 'instance-name':
#     instances      => ...
#     contact_group  => ...
# }
define cassandra::instance::monitoring (
    $instances     = $::cassandra::instances,
    $contact_group = 'admins,team-services',
) {
    $instance_name  = $title
    $this_instance  = $instances[$instance_name]
    $listen_address = $this_instance['listen_address']

    if ! has_key($instances, $instance_name) {
        fail("instance ${instance_name} not found in ${instances}")
    }

    $service_name = $instance_name ? {
        'default' => 'cassandra',
        default   => "cassandra-${instance_name}"
    }

    nrpe::monitor_systemd_unit_state { $service_name:
        require => Service[$service_name],
    }

    # CQL query interface monitoring (T93886)
    monitoring::service { "${service_name}-cql":
        description   => "${service_name} CQL ${listen_address}:9042",
        check_command => "check_tcp_ip!${listen_address}!9042",
        contact_group => $contact_group,
    }

    # SSL cert expiration monitoring (T120662)
    if hiera('cassandra::tls_cluster_name', '') {
        monitoring::service { "${service_name}-ssl":
            description   => "${service_name} SSL ${listen_address}:7001",
            check_command => "check_ssl_on_host_port!${::hostname}-${instance_name}!${listen_address}!7001",
            contact_group => $contact_group,
        }
    }
}
