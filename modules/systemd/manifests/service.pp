# @summary Manages a systemd-based unit as a puppet service, properly handling:
# - the unit file
# - the puppet service definition and state
# @param unit_type The unit type we are defining as a service
# @param content The content of the file.
# @param ensure The usual meta-parameter, defaults to present.
# @param restart Whether to handle restarting the service when the file changes.
# @param override If the are creating an override to system-provided units or not.
# @param override_filename When creating an override, filename to use instead of
#                          the one forged by systemd::unit.
# @param monitoring_enabled Periodically check the last execution of the unit and
#                           alarm if it ended up in a failed state.
# @param monitoring_contact_group The monitoring's contact group to send the alarm to.
# @param monitoring_notes_url The notes url used to resolve issues, if
#                             monitoring_enabled is true this is required
# @param monitoring_critical If monitoring is enabled allows paging if the execution
#                            of the unit ended up in a failed state.
# @param team The team which owns this service
# @param service_params Additional service parameters we want to specify
#
define systemd::service (
    String $content,
    Wmflib::Ensure            $ensure                   = 'present',
    Systemd::Unit::Type       $unit_type                = 'service',
    Boolean                   $restart                  = false,
    Boolean                   $override                 = false,
    Optional[String[1]]       $override_filename        = undef,
    Boolean                   $monitoring_enabled       = false,
    String                    $monitoring_contact_group = 'admins',
    Optional[Stdlib::HTTPUrl] $monitoring_notes_url     = undef,
    Boolean                   $monitoring_critical      = false,
    Optional[Wmflib::Team]    $team                     = undef,
    Hash                      $service_params           = {},
) {
    if $unit_type == 'service' {
        $label = $title
        $provider = undef
    } else {
        # Use a fully specified label for the unit.
        $label = "${title}.${unit_type}"
        # Force the provider of the service to be systemd if the unit type is
        # not service.
        $provider = 'systemd'
    }

    $enable = $ensure ? {
        'present' => true,
        default   => false,
    }

    $base_params = {
        ensure   => stdlib::ensure($ensure, 'service'),
        enable   => $enable,
        provider => $provider,
    }
    $params = merge($base_params, $service_params)
    ensure_resource('service', $label, $params)

    systemd::unit { $label:
        ensure            => $ensure,
        content           => $content,
        override          => $override,
        override_filename => $override_filename,
        restart           => $restart,
        team              => $team,
    }
    if $monitoring_enabled {
        unless $monitoring_notes_url {
            fail('Must provide $monitoring_notes_url if $monitoring_enabled')
        }
        systemd::monitor { $title:
            ensure        => $ensure,
            notes_url     => $monitoring_notes_url,
            contact_group => $monitoring_contact_group,
            critical      => $monitoring_critical,
        }
    }
}
