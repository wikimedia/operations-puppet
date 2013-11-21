class role::haproxy{

    system::role { 'haproxy': description => 'haproxy host' }

    class { 'haproxy':
        endpoint_hostname => 'stafford',
        endpoint_ip       => '10.0.0.24',
    }
}
