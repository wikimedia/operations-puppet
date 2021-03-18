# == systemd::service ===
#
# Manages a systemd-based unit as a puppet service, properly handling:
# - the unit file
# - the puppet service definition and state
#
# === Parameters ===
# [*unit_type*]
#   The unit type we are defining as a service
# [*content*]
#   The content of the file. Required.
# [*ensure*]
#   The usual meta-parameter, defaults to present. Valid values are
#   'absent' and 'present'
# [*restart*]
#   Whether to handle restarting the service when the file changes.
# [*override*]
#   If the are creating an override to system-provided units or not.
#   Defaults to false
# [*monitoring_enabled*]
#   Periodically check the last execution of the unit and alarm if it ended
#   up in a failed state.
#   Default: false
# [*monitoring_contact_groups*]
#   The monitoring's contact group to send the alarm to.
#   Default: admins
# [*monitoring_notes_url*]
#   The notes url used to resolve issues, if monitoring_enabled is true this is required
# [*service_params*]
#   Additional service parameters we want to specify
#
define systemd::service(
    String $content,
    Wmflib::Ensure            $ensure                   = 'present',
    Systemd::Unit_type        $unit_type                = 'service',
    Boolean                   $restart                  = false,
    Boolean                   $override                 = false,
    Boolean                   $monitoring_enabled       = false,
    String                    $monitoring_contact_group = 'admins',
    Optional[Stdlib::HTTPUrl] $monitoring_notes_url     = undef,
    Hash                      $service_params           = {},
){
    if $unit_type == 'service' {
        $label = $title
        $provider = undef
    } else {
        # Use a fully specified label for the unit.
        $label = "${title}.${unit_type}"
        # Force the provider of the service to be systemd if the unit type is
        # not service. Otherwise, they'd fail on at least debian jessie
        $provider = 'systemd'
    }

    $enable = $ensure ? {
        'present' => true,
        default   => false,
    }

    $base_params = {
        ensure   => stdlib::ensure($ensure, 'service'),
        enable   => $enable,
        provider => $provider
    }
    $params = merge($base_params, $service_params)
    ensure_resource('service', $label, $params)

    systemd::unit { $label:
        ensure   => $ensure,
        content  => $content,
        override => $override,
        restart  => $restart
    }
    if $monitoring_enabled {
        unless $monitoring_notes_url {
            fail('Must provide $monitoring_notes_url if $monitoring_enabled')
        }
        systemd::monitor{$title:
            ensure        => $ensure,
            notes_url     => $monitoring_notes_url,
            contact_group => $monitoring_contact_group,
        }
    }
}
