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
    $content,
    $unit_type = 'service',
    $ensure  = 'present',
    $restart = false,
    $override = false,
    $service_params = {},
){
    require ::systemd
    validate_ensure($ensure)
    unless ($unit_type in $::systemd::unit_types) {
        fail("Unsupported systemd unit type ${unit_type}")
    }

    $label = "${title}.${unit_type}"
    $enable = $ensure ? {
        'present' => true,
        default   => false,
    }
    $base_params = {
        ensure   => ensure_service($ensure),
        provider => 'systemd',
        enable   => $enable,
    }
    $params = merge($base_params, $service_params)
    ensure_resource('service', $label, $params)

    systemd::unit { $label:
        ensure   => present,
        content  => $content,
        override => $override,
        restart  => $restart
    }
}
