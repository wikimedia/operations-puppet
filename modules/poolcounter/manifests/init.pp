# PoolCounter server
# See http://wikitech.wikimedia.org/view/PoolCounter

class poolcounter {

    package { 'poolcounter':
        ensure => 'latest',
    }

    service { 'poolcounter':
        ensure  => 'running',
        require => Package['poolcounter'],
    }
}
