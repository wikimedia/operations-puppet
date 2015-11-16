# == Class eventlogging::deployment::target
# Include this class on nodes to which you will be deploying
# eventlogging codebase.  For scap3, it just ensures
# that the proper deploy users's ssh key is present,
# and that the deployment target path has the proper
# ownership and permissions.
#
class eventlogging::deployment::target($path = '/srv/deployment/eventlogging/eventlogging') {
    require ::eventlogging

    # Temporary conditional while we migrate eventlogging service over to
    # using systemd on Debian Jessie.  This will allow us to individually
    # configure services on new nodes while not affecting the running
    # eventlogging instance on Ubuntu Trusty.
    if $::operatingsystem == 'Ubuntu' {
        # Ubuntu Trusty hosts use Trebuchet for deployment.
        package { 'eventlogging/eventlogging':
            provider => 'trebuchet',
        }

        # Manage EventLogging services with 'eventloggingctl'.
        # Usage: eventloggingctl {start|stop|restart|status|tail}
        file { '/sbin/eventloggingctl':
            source => 'puppet:///modules/eventlogging/eventloggingctl',
            mode   => '0755',
        }

        # Upstart job definitions.
        file { '/etc/init/eventlogging':
            source  => 'puppet:///modules/eventlogging/init',
            recurse => true,
            purge   => true,
            force   => true,
            require => [
                File['/etc/eventlogging.d'],
                File['/etc/eventlogging.d/consumers'],
                File['/etc/eventlogging.d/forwarders'],
                File['/etc/eventlogging.d/multiplexers'],
                File['/etc/eventlogging.d/processors'],
                File['/etc/eventlogging.d/reporters'],
                File['/etc/eventlogging.d/services'],
                Package['eventlogging/eventlogging'],
            ]
        }

        # 'eventlogging/init' is the master upstart task; it walks
        # </etc/eventlogging.d> and starts a job for each instance
        # definition file that it encounters.
        service { 'eventlogging/init':
            provider => 'upstart',
            require  => [
                File['/etc/init/eventlogging'],
                User['eventlogging']
            ],
        }
    }

    # New Debian systemd based host use scap3.
    else {
        # Include scap3 package and ssh ferm rules.
        include scap
        # TODO change to scap::target if
        # https://gerrit.wikimedia.org/r/#/c/259542 is merged.
        include role::scap::target

        ssh::userkey { 'eventlogging':
            source => "puppet:///modules/eventlogging/deployment/eventlogging_rsa.pub.${::realm}",
        }

        # TODO: Do I need to ensure parent path exists?
        # (/srv/deployment/eventlogging?)
        file { $path,
            ensure  => 'directory',
            owner   => 'eventlogging',
            mode    => '0755',
            # Set permissions recursively.
            recurse => true,
        }
    }
}
