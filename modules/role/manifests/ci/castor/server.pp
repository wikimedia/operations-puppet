# == Class role::ci::castor::server
#
# rsync server to store cache related material from CI jobs.
#
class role::ci::castor::server {
    requires_realm( 'labs' )

    # Castor uses an attached volume...
    include profile::labs::cindermount::srv

    class { '::profile::ci::slave::labs::common':
        # ... and we thus skip the logic to manage extended disk space
        manage_srv => false
    }

    include profile::ci::castor::server

    Class['::profile::ci::slave::labs::common'] ~> Class['::profile::ci::castor::server']

}
