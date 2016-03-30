class prometheus::scripts {
    require_package('python3-yaml')

    # output all nova instances for the current labs project as prometheus
    # 'targets'
    file { '/usr/local/bin/prometheus-labs-targets':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-labs-targets',
    }
}
