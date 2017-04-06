class role::jobqueue_redis::slave {
    include ::standard
    include ::base::firewall

    include profile::redis::slave

    system::role { 'role::jobqueue_redis::slave':
        description => 'Jobqueue slave',
    }
}
