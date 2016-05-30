class ganglia::monitor::packages {
    require_package('ganglia-monitor')

    file { ['/usr/lib/ganglia/python_modules',
            '/etc/ganglia/conf.d']:
        ensure  => directory,
        require => Package['ganglia-monitor'],
    }
}
