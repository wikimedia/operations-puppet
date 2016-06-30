# WHERE TO MOVE THIS?
class misc::monitoring::views {
    misc::monitoring::view::varnishkafka { 'webrequest':
        topic_regex => 'webrequest_.+',
    }

    class { 'misc::monitoring::view::hadoop':
        master       => 'analytics1001.eqiad.wmnet',
        worker_regex => 'analytics10(11|[3-9]|20).eqiad.wmnet',
    }

    include misc::monitoring::views::dns
}

