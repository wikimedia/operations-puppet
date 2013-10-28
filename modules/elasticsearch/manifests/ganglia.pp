class elasticsearch::ganglia {
    file { '/etc/ganglia/conf.d/elasticsearch.pyconf':
        owner  => root,
        group  => root,
        mode   => '0444',
        content => template('elasticsearch/ganglia/elasticsearch.pyconf.erb'),
        notify => Service['gmond'];
    }
    file { '/usr/lib/ganglia/python_modules/elasticsearch_monitoring.py':
        owner  => root,
        group  => root,
        mode   => '0444',
        content => template('elasticsearch/ganglia/elasticsearch_monitorying.py.erb'),
        notify => Service['gmond'];
    }
}
