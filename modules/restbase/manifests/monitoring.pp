# === Class restbase::monitoring
#
# For now, a rudimentary check for restbase
class restbase::monitoring(
) {
    require ::restbase

    monitoring::service { 'restbase_http_root':
        description   => 'Restbase root url',
        check_command => "check_http_port_url!${::restbase::port}!/",
        contact_group => 'admins,team-services',
    }

}
