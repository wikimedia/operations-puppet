class role::jobqueue_redis::slave {
    include ::standard
    include ::profile::base::firewall

    include ::profile::redis::slave

    system::role { 'jobqueue_redis::slave':
        description => 'Jobqueue slave',
    }
}
