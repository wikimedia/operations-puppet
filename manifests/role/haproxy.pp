class role::puppetproxy {

    system::role { 'puppetproxy':
        description => 'Puppet proxying through haproxy host',
    }

    class { 'haproxy':
        endpoint_hostname => 'palladium',
        endpoint_ip       => '10.64.16.160',
    }
}
