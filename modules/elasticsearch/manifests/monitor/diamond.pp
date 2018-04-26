# == Class: elasticsearch::monitor::diamond
#

class elasticsearch::monitor::diamond {
    diamond::collector { 'WMFElastic':
        ensure => absent,
        source => 'puppet:///modules/elasticsearch/monitor/wmfelastic.py',
    }
}

