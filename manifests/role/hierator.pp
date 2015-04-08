class role::hierator {
    system::role { 'role::hierator':
        description => 'Hierator server',
    }

    #package { 'hierator/hierator':
    #    ensure => present,
    #    provider => 'trebuchet',
    #}

    # While a wip...
    ::git::clone { 'hierator':
        directory => '/srv/deployment/hierator',
        origin    => 'https://github.com/MaxSem/hierator-bin.git',
    }

    ::jetty::service { 'hierator':
        port         => 4242,
        war          => '/srv/deployment/hierator/hierator.war',
        memory_limit => '512M',
    }
}
