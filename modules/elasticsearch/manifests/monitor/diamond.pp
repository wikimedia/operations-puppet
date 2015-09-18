# == Class: elasticsearch::monitor::diamond
#

class elasticsearch::monitor::diamond {
    diamond::collector { 'WMFElastic':
        source   => 'puppet:///modules/elasticsearch/monitor/wmfelastic.py',
    }
}

