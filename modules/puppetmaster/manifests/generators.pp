class puppetmaster::generators($ensure = 'present'){

    $packages = ['python-jinja2', 'python-mysqldb', 'python-sqlalchemy']
    require_package($packages)

    file {'/usr/local/bin/naggen2':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/naggen2',
        require => Package[$packages],
    }

    file {'/usr/local/bin/sshknowngen':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/sshknowngen',
        require => Package[$packages],
    }

    file {'/usr/local/bin/prometheus-ganglia-gen':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/prometheus-ganglia-gen',
        require => Package[$packages],
    }
}
