class hierator {
    include ::java::tools

    package { 'jetty8':
        ensure => present,
    }

    file { '/etc/default/jetty8':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => '', # Use all defaults
        notify  => Service['jetty8'],
    }

    service { 'jetty8':
        require => Package['jetty8'],
        ensure  => running,
    }

    # Nuke default webroot
    file { '/usr/share/jetty8/webapps/root':
        ensure => absent,
    }


    # While a wip...
    ::git::clone { 'hierator':
        directory => '/srv/deployment/hierator',
        origin    => 'https://github.com/MaxSem/hierator-bin.git',
    }
    file { '/usr/share/jetty8/webapps/root.war':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        ensure => link,
        target => '/srv/deployment/hierator/hierator.war',
    }
}
