class base::instance_upstarts {

    file { '/etc/init/ttyS0.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/upstart/ttyS0.conf';
    }

}
