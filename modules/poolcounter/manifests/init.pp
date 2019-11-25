# PoolCounter server
# See http://wikitech.wikimedia.org/view/PoolCounter

class poolcounter {

    require_package('poolcounter', 'poolcounter-prometheus-exporter')

    service { 'poolcounter':
        ensure  => 'running',
        require => Package['poolcounter'],
    }

    systemd::service { 'poolcounter-prometheus-exporter':
        ensure  => 'present',
        content => systemd_template('poolcounter-prometheus-exporter'),
        require => Package['poolcounter-prometheus-exporter'],
        restart => true,
    }
}
