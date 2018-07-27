class role::jobqueue_redis::master {
    include ::standard
    include ::profile::base::firewall
    include ::profile::redis::multidc

    system::role { 'jobqueue_redis::master':
        description => 'Jobqueue master',
    }
}
