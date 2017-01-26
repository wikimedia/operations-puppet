# == Class deployment::redis
# Simple wrapper to enable replication between trebuchet masters

class deployment::redis($deployment_server) {

    if $::initsystem == 'upstart' {
        $daemonize_redis = false
    } else {
        $daemonize_redis = true
    }

    if ($::fqdn != $deployment_server) {
        $deployment_ipv4 = ipresolve($deployment_server, 4)
        # Just a read-only slave for now
        redis::instance { 6379:
            settings => {
                daemonize       => $daemonize_redis,
                slave_read_only => true,
                slaveof         => "${deployment_ipv4} 6379",
                bind            => '0.0.0.0',
            },
        }
    } else {
        redis::instance{ 6379:
            settings => {
                daemonize => $daemonize_redis,
                bind      => '0.0.0.0',
            },
        }
    }
}
