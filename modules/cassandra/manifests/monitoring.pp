# == Define: cassandra::monitoring
#
# Configures monitoring for Cassandra
#
# === Usage
# cassandra::monitoring { 'instance-name':
#     instances      => ...
#     contact_group  => ...
# }
define cassandra::monitoring (
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
}
