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
# [*service_params*]
#   Additional service parameters we want to specify
#
define systemd::service(
    String $content,
    Systemd::Unit_type $unit_type = 'service',
    Wmflib::Ensure $ensure  = 'present',
    Boolean $restart = false,
    Boolean $override = false,
    $service_params = {},
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
        ensure   => ensure_service($ensure),
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
}
