class puppetmaster::naggen2($ensure = 'present'){

    $packages = ['python-jinja2', 'python-mysqldb', 'python-sqlalchemy']

    # When migrated to puppet 3, we can substitute this with ensure_resource
    # for now, we have this ugly define here.
    define ensure_package($ensure = 'present') {
        if ! defined(Package[$title]) {
            package {$title: ensure => $ensure }
        }
    }

    puppetmaster::naggen2::ensure_package {$packages:
        ensure => latest
    }

    file {'/usr/local/bin/naggen2':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/naggen2',
        require => Package[$packages]
    }
}
