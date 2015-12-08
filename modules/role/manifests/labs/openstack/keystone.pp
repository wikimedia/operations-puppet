class role::labs::openstack::keystone::server {

    system::role { $name: }

    $nova_controller   = hiera('labs_nova_controller')
    $keystoneconfig    = hiera_hash('keystoneconfig', {})
    $slaveof           = hiera('keystone_redis_slaveof', undef)

    class { 'openstack::keystone::service':
        keystoneconfig => $keystoneconfig,
    }

    redis::instance { 6379:
	settings => {
	    appendfilename              => "${::hostname}-6379.aof"
	    appendonly                  => true,
	    client_output_buffer_limit  => 'slave 512mb 200mb 60',
	    dbfilename                  => "${::hostname}-6379.rdb"
	    dir                         => '/var/lib/redis/',
	    logfile                     => '/var/log/redis/redis.log',
	    masterauth                  => $keystoneconfig['db_pass'],
	    maxmemory                   => '250mb',
	    maxmemory_policy            => 'volatile-lru',
	    maxmemory_samples           => 5,
	    no_appendfsync_on_rewrite   => true,
	    requirepass                 => $keystoneconfig['db_pass'],
	    save                        => '""',
	    slave_read_only             => false,
	    slaveof                     => $slaveof,
	    stop_writes_on_bgsave_error => false,
	    auto_aof_rewrite_min_size   => '64mb',
	},
    }
}
