# === Class restbase::monitoring
#
# For now, a rudimentary check for restbase
class restbase::monitoring(
    $monitor_restbase = hiera('monitor_restbase', true),
) {
    require ::restbase

    $ensure_monitor_restbase = $monitor_restbase ? {
        true    => present,
        false   => absent,
        default => present,
    }

    monitoring::service { 'restbase_http_root':
        ensure        => $ensure_monitor_restbase,
        description   => 'Restbase root url',
        check_command => "check_http_port_url!${::restbase::port}!/",
        contact_group => 'admins,team-services',
    }

}
