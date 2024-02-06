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
    String            $contact_group    = 'admins,team-services',
    Boolean           $monitor_enabled  = true,
    Boolean           $tls_use_pki      = false,
    Hash              $instances        = {},
    Optional[String]  $tls_cluster_name = undef,
    Optional[Integer] $tls_port         = 7001,
    Optional[Integer] $cql_port         = 9042,
) {

    include cassandra
    $_instances = $instances.empty ? {
        true    => $cassandra::instances,
        default => $instances,
    }
    $instance_name  = $title
    $this_instance  = $_instances[$instance_name]
    $listen_address = $this_instance['listen_address']

    if ! has_key($instances, $instance_name) {
        fail("instance ${instance_name} not found in ${_instances}")
    }

    $service_name = $instance_name ? {
        'default' => 'cassandra',
        default   => "cassandra-${instance_name}"
    }

    $ensure_monitor = $monitor_enabled.bool2str('present', 'absent')

    # SSL cert expiration monitoring (T120662)
    if $tls_cluster_name {
        $ensure_nagios_monitor = $tls_use_pki ? {
            true  => 'absent',
            false => $ensure_monitor,
        }
        if $tls_use_pki {
            # The TLS certificates provided by PKI are automatically
            # renewed by puppet, and reloaded by Cassandra automatically.
            # This alert is needed to warn the admins in case something goes
            # wrong and the new cert is not picked up as expected.
            prometheus::blackbox::check::tcp { "${service_name}-ssl":
                # The blackbox probe doesn't support one servername
                # for each instance, so we fallback to a CN: cassandra
                # to have a single config supported by all PKI-enabled
                # instances.
                server_name             => 'cassandra',
                port                    => $tls_port,
                force_tls               => true,
                certificate_expiry_days => 5,
                ip4                     => $listen_address,
                ip_families             => ['ip4'],
                instance_label          => "${::hostname}-${instance_name}",
            }

            prometheus::blackbox::check::tcp { "${service_name}-cql":
                # The blackbox probe doesn't support one servername
                # for each instance, so we fallback to a CN: cassandra
                # to have a single config supported by all PKI-enabled
                # instances.
                server_name             => 'cassandra',
                port                    => $cql_port,
                force_tls               => true,
                certificate_expiry_days => 5,
                ip4                     => $listen_address,
                ip_families             => ['ip4'],
                instance_label          => "${::hostname}-${instance_name}",
            }
        }

        # CQL query interface monitoring (T93886)
        monitoring::service { "${service_name}-cql":
            ensure        => $ensure_nagios_monitor,
            description   => "${service_name} CQL ${listen_address}:${cql_port}",
            check_command => "check_tcp_ip!${listen_address}!${cql_port}",
            contact_group => $contact_group,
            notes_url     => 'https://phabricator.wikimedia.org/T93886',
        }

        monitoring::service { "${service_name}-ssl":
            ensure        => $ensure_nagios_monitor,
            description   => "${service_name} SSL ${listen_address}:${tls_port}",
            check_command => "check_ssl_on_host_port!${facts['hostname']}-${instance_name}!${listen_address}!${tls_port}",
            contact_group => $contact_group,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Cassandra#Installing_and_generating_certificates',
        }
    }
}
