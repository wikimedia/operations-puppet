class role::jobqueue_redis::master {
    include ::standard
    include ::base::firewall
    include ::profile::jobqueue_redis::master
}
