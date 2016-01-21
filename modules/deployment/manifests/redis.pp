# == Class deployment::redis
# Simple wrapper to enable replication between trebuchet masters

class deployment::redis($deployment_server) {

    if ($::fqdn != $deployment_server) {
        $deployment_ipv4 = ipresolve($deployment_server, 4)
        # Just a read-only slave for now
        redis::instance { 6379:
            settings => {
                daemonize       => false,
                slave_read_only => true,
                slaveof         => "${deployment_ipv4} 6379"
            }
        }
    } else {
        redis::instance{ 6379:
            settings => {
                daemonize       => false,
            }
        }
    }
}
