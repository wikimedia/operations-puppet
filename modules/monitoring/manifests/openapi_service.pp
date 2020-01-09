define monitoring::openapi_service (  # aka swagger
    String $target,
    String $description,
    String $notes_url,
    String $active_host                          = $::profile::icinga::active_host,
    Wmflib::Ensure $ensure                       = 'present',
    String $site                                 = $::site,
    Hash[String, Variant[Array, String]] $params = {},
    Integer $timeout                             = 10,
    String $host                                 = $::hostname,
    Integer $retries                             = 3,
    Variant[String, Undef] $group                = undef,
    Boolean $critical                            = false,
    Integer $check_interval                      = 1,
    Integer $retry_interval                      = 1,
    String $contact_group                        = lookup('contactgroups', {'default_value' => 'admins'}), # lint:ignore:wmf_styleguide
    String $notifications_enabled                = $::profile::base::notifications_enabled,
) {
    # only export if this is the active host
    if ($::fqdn == $active_host) {
        # prometheus expects string[] type for param values
        $params_real = $params.map |$param| {
            if $param[1] =~ Array {
                { "${param[0]}" => $param[1] }
            } else {
                { "${param[0]}" => [ $param[1] ] }
            }
        }
        # Set up swagger exporter job if targets have been defined.
        prometheus::blackbox_check_endpoint { $title:
            targets          => [$target],
            site             => $site,
            params           => $params_real,
            timeout          => "${timeout}s",
            exporter_address => '127.0.0.1:9220'  # from Prometheus host perspective
        }
    }

    if ($params['spec_segment'] != undef) {
        $check_command_real = "check_wmf_service_url!${target}!${timeout}!${params['spec_segment']}"
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
        contact_group         => $contact_group,
        notifications_enabled => $notifications_enabled
    }
}
