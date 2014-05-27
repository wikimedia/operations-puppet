class puppetmaster::naggen2($ensure = 'present'){
    define package_singleton($ensure = $::puppetmaster::naggen2::ensure){
        if (! defined(Package[$title])) {
            package {$title:
                ensure => $ensure
            }
        }
    }
    package_singleton {['python-jinja2', 'python-mysql', 'python-sqlalchemy']: }
    file {'/usr/local/bin/naggen2':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/naggen2',
        require => [File['/etc/puppet/naggen.conf'], Package['python-mysqldb', 'python-jinja2', 'python-sqlalchemy']]
    }
}
