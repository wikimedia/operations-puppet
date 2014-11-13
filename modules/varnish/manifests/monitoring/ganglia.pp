class varnish::monitoring::ganglia($varnish_instances=['']) {
    $instances = join($varnish_instances, ',')

    file { '/usr/lib/ganglia/python_modules/varnish.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/${module_name}/ganglia/ganglia-varnish.py",
        require => File['/usr/lib/ganglia/python_modules'],
    }

    exec { 'generate varnish.pyconf':
        require => [
            File['/usr/lib/ganglia/python_modules/varnish.py'],
            File['/etc/ganglia/conf.d'],
        ],
        command => "/usr/bin/python /usr/lib/ganglia/python_modules/varnish.py \"${instances}\" > /etc/ganglia/conf.d/varnish.pyconf.new",
    }

    exec { 'replace varnish.pyconf':
        cwd     => '/etc/ganglia/conf.d',
        path    => '/bin:/usr/bin',
        unless  => 'diff -q varnish.pyconf.new varnish.pyconf && rm varnish.pyconf.new',
        command => 'mv varnish.pyconf.new varnish.pyconf',
        notify  => Service['gmond'],
    }

    file { '/usr/local/sbin/check-gmond-restart':
        ensure => present,
        source => 'puppet:///modules/varnish/ganglia/check-gmond-restart',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }

    file { '/etc/cron.d/check-gmond-restart':
        ensure  => present,
        content => "*/5 * * * * root /usr/local/sbin/check-gmond-restart > /dev/null 2>&1",
        require => File['/usr/local/sbin/check-gmond-restart'],
    }

    # Dependencies
    # Exec the config generation AFTER all varnish instances have started
    Service <| tag == 'varnish_instance' |> -> Exec['generate varnish.pyconf']
    Exec['generate varnish.pyconf'] -> Exec['replace varnish.pyconf']
}
