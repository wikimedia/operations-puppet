# = Class: role::kafkawatcher
#
# This roles sets up kafka watcher instance
#
class role::kafkawatcher  {
    $nagios_contact_group = 'perf-admins'
    
    system::role { 'role::kafkawatcher':
        ensure      => 'present',
        description => 'Kafka Watcher daemon',
    }

    include standard
    include ::kafkawatcher
    include ::kafkawatcher::memcached
}