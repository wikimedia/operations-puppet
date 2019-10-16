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

    # The Archiva systemd unit requires /var/run/archiva
    # to be present before starting. In some cases /var/run
    # is deployed on tmpfs mountpoints, so everything gets
    # cleared after a reboot. The directory is created by
    # the package during deb install.
    systemd::tmpfile { 'archiva':
        content => 'd /var/run/archiva 0755 archiva archiva',
    }

    service { 'archiva':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        subscribe  => File['/etc/archiva/jetty.xml'],
        require    => Package['archiva'],
    }
}