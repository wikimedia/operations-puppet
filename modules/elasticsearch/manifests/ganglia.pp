class elasticsearch::ganglia {
    file { '/etc/ganglia/conf.d/elasticsearch.pyconf':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/elasticsearch/ganglia/elasticsearch.pyconf',
        notify => Service['gmond'];
    }
    file { '/usr/lib/ganglia/python_modules/elasticsearch_monitoring.py':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/elasticsearch/ganglia/elasticsearch_monitoring.py',
        notify => Service['gmond'];
    }
}
