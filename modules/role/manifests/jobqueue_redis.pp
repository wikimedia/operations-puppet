# filtertags: labs-project-deployment-prep
class role::jobqueue_redis {
    warning('This module is deprecated. you should use role::jobqueue_redis::master instead')
    include ::standard
    include ::passwords::redis

    system::role { 'role::jobqueue_redis': }

    $password = $passwords::redis::main_password
    $instances = [6378, 6379, 6380, 6381]
    $ip = $::main_ipaddress
    $master = hiera('jobqueue_redis_slaveof', undef)

    if $master {
        $slaveof = ipresolve(hiera('jobqueue_redis_slaveof'), 4)
        mediawiki::jobqueue_redis { $instances: slaveof => $slaveof}
        # Monitoring
        redis::monitoring::instance { $instances:
            settings => {slaveof => $slaveof}
        }
    }
    else {
        mediawiki::jobqueue_redis {$instances: }
        # Monitoring
        redis::monitoring::instance { $instances: }

    }

    $uris = apply_format("localhost:%s/${password}", $instances)
    diamond::collector { 'Redis':
        settings => { instances => join($uris, ', ') }
    }

    $redis_ports = join($instances, ' ')

    ferm::service { 'redis_jobqueue_role':
        proto   => 'tcp',
        notrack => true,
        port    => inline_template('(<%= @redis_ports %>)'),
    }

}
