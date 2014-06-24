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

    Exec['generate varnish.pyconf'] -> Exec['replace varnish.pyconf']
}
