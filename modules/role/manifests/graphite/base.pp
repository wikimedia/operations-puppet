class role::graphite::base {
    system::role { 'graphite':
        description => 'real-time metrics processor',
    }

    include ::profile::graphite::base
}
