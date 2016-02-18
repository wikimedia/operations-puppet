# === Class aqs::monitoring
#
# For now, a rudimentary check for AQS
class aqs::monitoring(
) {
    require ::restbase

    monitoring::service { 'aqs_http_root':
        description   => 'AQS root url',
        check_command => "check_http_port_url!${::aqs::port}!/",
        contact_group => 'admins,team-services',
    }

}
