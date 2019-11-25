# PoolCounter server
# See http://wikitech.wikimedia.org/view/PoolCounter

class poolcounter {
    require_package('poolcounter')

    service { 'poolcounter':
        ensure  => 'running',
        require => Package['poolcounter'],
    }
}
