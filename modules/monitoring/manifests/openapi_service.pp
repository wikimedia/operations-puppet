define monitoring::openapi_service (  # aka swagger
    String $target,
    String $description,
    String $notes_url,
    String $active_host                      = $::profile::icinga::active_host,
    Wmflib::Ensure $ensure                   = 'present',
    String $site                             = $::site,
    Hash[String, Array[String]] $params      = {},
    Integer $timeout                         = 10,
    String $host                             = $::hostname,
    Integer $retries                         = 3,
    Variant[String, Undef] $group            = undef,
    Boolean $critical                        = false,
    Integer $check_interval                  = 1,
    Integer $retry_interval                  = 1,
    Optional[String] $contact_group          = undef,
    Optional[Boolean] $notifications_enabled = undef,
) {
    include monitoring
    $_contact_group = pick($contact_group, $monitoring::contact_group)
    $_notifications_enabled = pick($notifications_enabled, $monitoring::notifications_enabled)

    # Create the Icinga host for this service.
    # The service::catalog integration used to create these hosts
    # automatically via 'monitoring' section (now deprecated).
    # See also https://phabricator.wikimedia.org/T291946
    @monitoring::host { $host:
        ip_address    => ipresolve($host, 4),
        contact_group => $_contact_group,
        critical      => $critical,
        group         => 'lvs',
    }

    # only export if this is the active host
    if ($::fqdn == $active_host) {
        # Set up swagger exporter job if targets have been defined.
        prometheus::blackbox_check_endpoint { $title:
            targets          => [$target],
            site             => $site,
            params           => $params,
            timeout          => $timeout,
            exporter_address => '127.0.0.1:9220'  # from Prometheus host perspective
        }
    }

    if ($params['spec_segment'] != undef) {
        $check_command_real = "check_wmf_service_url!${target}!${timeout}!${params['spec_segment'][0]}"
    } else {
        $check_command_real = "check_wmf_service!${target}!${timeout}"
    }

    monitoring::service { $title:
        ensure                => $ensure,
        description           => $description,
        check_command         => $check_command_real,
        notes_url             => $notes_url,
        host                  => $host,
        retries               => $retries,
        group                 => $group,
        critical              => $critical,
        check_interval        => $check_interval,
        retry_interval        => $retry_interval,
        contact_group         => $_contact_group,
        notifications_enabled => $_notifications_enabled
    }
}
