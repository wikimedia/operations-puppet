class role::haproxy{

    system::role { 'haproxy': description => 'haproxy host' }

    class { 'haproxy':
        endpoint_hostname => 'palladium',
        endpoint_ip       => '10.64.16.160',
    }
}
