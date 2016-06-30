class role::ganglia::views {

    ganglia::views::varnishkafka { 'webrequest':
        topic_regex => 'webrequest_.+',
    }

    class { 'ganglia::views::hadoop':
        master       => 'analytics1001.eqiad.wmnet',
        worker_regex => 'analytics10(11|[3-9]|20).eqiad.wmnet',
    }

    include ganglia::views::dns

}
