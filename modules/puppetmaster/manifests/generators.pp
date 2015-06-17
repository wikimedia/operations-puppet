class puppetmaster::generators($ensure = 'present'){

    $packages = ['python-jinja2', 'python-mysqldb', 'python-sqlalchemy']
    ensure_packages($packages)

    file {'/usr/local/bin/naggen2':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/naggen2',
        require => Package[$packages]
    }

    file {'/usr/local/bin/sshknowngen':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/sshknowngen',
        require => Package[$packages]
    }
}
