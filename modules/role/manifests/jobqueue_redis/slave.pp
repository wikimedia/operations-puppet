class role::jobqueue_redis::slave {
    include ::standard
    include ::base::firewall

    include ::profile::redis::slave
    include ::profile::redis::jobqueue_slave

    system::role { 'jobqueue_redis::slave':
        description => 'Jobqueue slave',
    }
}
