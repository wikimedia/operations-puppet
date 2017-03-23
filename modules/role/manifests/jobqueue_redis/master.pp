class role::jobqueue_redis::master {
    include ::standard
    include ::base::firewall
    include ::profile::redis::multidc
}
