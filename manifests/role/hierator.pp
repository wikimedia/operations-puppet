class role::hierator {
    system::role { 'role::hierator':
        description => 'Hierator server',
    }

    package { 'hierator/hierator':
        ensure => present,
        provider => 'trebuchet',
    }

    ::jetty::service { 'hierator':
        port         => 4242,
        war          => '/srv/deployment/hierator/hierator.war',
        memory_limit => '512M',
    }
}
