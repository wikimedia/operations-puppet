# == Class role::ci::castor::server
#
# rsync server to store cache related material from CI jobs.
#
class role::ci::castor::server {
    requires_realm( 'labs' )

    system::role { 'role::ci::castor::server':
        description => 'rsync server to store caches artifacts'
    }

    include ::profile::ci::slave::labs::common
    include ::profile::ci::castor::server

    Class['::profile::ci::slave::labs::common'] ~> Class['::profile::ci::castor::server']

}
