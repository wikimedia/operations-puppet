class puppetmaster::generators($ensure = 'present'){

    # python-mysqldb is used as one of python-sqlalchemy backends
    $packages = ['python-jinja2', 'python-mysqldb', 'python-sqlalchemy', 'python-requests']
    require_package($packages)

    file {'/usr/local/bin/naggen2':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/naggen2.py',
        require => Package[$packages],
    }

    file {'/usr/local/bin/sshknowngen':
        ensure  => absent,
    }

    file {'/usr/local/bin/prometheus-ganglia-gen':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/prometheus-ganglia-gen.py',
        require => Package[$packages],
    }
}
