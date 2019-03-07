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
    $instances        = $::cassandra::instances,
    $contact_group    = 'admins,team-services',
    $tls_cluster_name = $::cassandra::tls_cluster_name,
    $monitor_enabled  = $::cassandra::monitor_enabled,
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

    $ensure_monitor = $monitor_enabled ? {
        true    => present,
        false   => absent,
        default => present,
    }

    nrpe::monitor_systemd_unit_state { $service_name:
        ensure  => $ensure_monitor,
        require => Service[$service_name],
    }

    # CQL query interface monitoring (T93886)
    monitoring::service { "${service_name}-cql":
        ensure        => $ensure_monitor,
        description   => "${service_name} CQL ${listen_address}:9042",
        check_command => "check_tcp_ip!${listen_address}!9042",
        contact_group => $contact_group,
        notes_url     => 'https://phabricator.wikimedia.org/T93886',
    }

    # SSL cert expiration monitoring (T120662)
    if !empty($tls_cluster_name) {
        monitoring::service { "${service_name}-ssl":
            ensure        => $ensure_monitor,
            description   => "${service_name} SSL ${listen_address}:7001",
            check_command => "check_ssl_on_host_port!${::hostname}-${instance_name}!${listen_address}!7001",
            contact_group => $contact_group,
            notes_url     => 'https://phabricator.wikimedia.org/T120662',
        }
    }
}
