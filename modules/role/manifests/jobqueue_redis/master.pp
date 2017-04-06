class role::jobqueue_redis::master {
    include ::standard
    include ::base::firewall
    include ::profile::redis::multidc

    system::role { 'role::jobqueue_redis::master':
        description => 'Jobqueue master',
    }
}
