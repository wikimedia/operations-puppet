# == Class deployment::redis
# Simple wrapper to enable replication between trebuchet masters

class deployment::redis {
    $deployment_server = hiera('deployment_server', 'tin.eqiad.wmnet')

    if ($::fqdn != $deployment_server) {
        # Just a read-only slave for now
        redis::instance { 6379:
            settings => {
                slave_read_only => true,
                slaveof         => "${deployment_server} 6379"
            }
        }
    } else {
        redis::instance{ 6379: }
    }
}
