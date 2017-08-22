class openstack2::glance::monitor(
    $active,
) {

    require openstack2::glance::service

    # nagios doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    monitoring::service { 'glance-api-http':
        ensure        => $ensure,
        description   => 'glance-api http',
        check_command => 'check_http_on_port!9292',
    }
}
