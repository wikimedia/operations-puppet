# = Class: kafkawatcher::memcached
# Watching memcache events
class kafkawatcher::memcached(
    $kafka_server,
    $memcache_topic,
    $username = $::kafkawatcher::username,
    $package_dir = $::kafkawatcher::package_dir,
    ) {
        apt::pin { 'python-pymemcache':
          package  => 'python-pymemcache',
          pin      => 'version 1.3*',
          priority => 1002,
          before   => Package['python-pymemcache'],
        }

        package { 'python-pymemcache':
            ensure => present
        }

        # Service configuration
        file { '/etc/kafkawatcher/memcache.yaml':
          ensure  => present,
          content => template('kafkawatcher/memcache.yaml.erb'),
          mode    => '0444',
          owner   => root,
          group   => root,
          notify  => Service['kafka-watcher-memcache'],
          require => [ File['/etc/kafkawatcher'], Package['python-pymemcache'] ]
        }

        # The system service
        base::service_unit { 'kafka-watcher-memcache':
          template_name  => 'kafka-watcher-memcache',
          systemd        => true,
          upstart        => true,
          service_params => {
            enable => true,
          },
          require        => File['/etc/kafkawatcher/memcache.yaml'],
        }
}