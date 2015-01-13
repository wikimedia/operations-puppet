# PoolCounter server
# See http://wikitech.wikimedia.org/view/PoolCounter

class poolcounter {

    package { 'poolcounter':
        ensure => 'installed',
    }

    service { 'poolcounter':
        ensure  => 'running',
        require => Package['poolcounter'],
    }
}
