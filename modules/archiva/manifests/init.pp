# == Class: archiva
#
# Installs and runs Apache Archiva.
# You must do any further configuration of Archiva
# via the archiva web interface.  Archiva will save
# its custom configurations to /var/lib/archiva/conf/archiva.xml.
#
class archiva($port = 8080)
{
    package { 'archiva':
        ensure => 'installed',
    }

    file { '/etc/archiva/jetty.xml':
        content => template('archiva/jetty.xml.erb'),
        require => Package['archiva'],
    }

    service { 'archiva':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        subscribe  => File['/etc/archiva/jetty.xml'],
    }
}