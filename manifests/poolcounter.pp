# PoolCounter server
# See http://wikitech.wikimedia.org/view/PoolCounter

class poolcounter {
    include nrpe

    # Process running
    monitor_service { 'poolcounterd':
        description   => 'poolcounter',
        check_command => 'nrpe_check_poolcounterd',
    }

    # TCP port 7531 reacheable
    monitor_service { 'poolcounterd_port_7531':
        description   => 'Poolcounter connection',
        check_command => 'check_tcp!7531',
    }

    package { 'poolcounter':
        ensure => latest,
    }

    service { 'poolcounter':
        ensure  => running,
        require => Package['poolcounter'],
    }
}
