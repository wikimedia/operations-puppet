# == Class: kafkatee
#
# Installs and configures a kafkatee instance. This does not configure any
# inputs or outputs for the kafkatee instance.  You should configure them
# using the kafkatee::input and kafkatee::output defines.
#
# == Parameters:
#
# $configure_rsyslog         - Add necessary configuration files for logrotate
#                              and rsyslog. The rsyslog/logrotate configuration
#                              are handled by two separate puppet modules
#                              (named rsyslog and logrotate), so setting this
#                              option to 'true' will require both of them to
#                              work properly.
#                              Default: true

class kafkatee(
    $configure_rsyslog = true,
) {
    require_package('kafkatee')

    file { '/etc/kafkatee':
        ensure => 'directory',
    }

    if $configure_rsyslog {
        # Basic logrotate.d configuration to rotate /var/log/kafkatee.log
        logrotate::conf { 'kafkatee':
            source => 'puppet:///modules/kafkatee/kafkatee_logrotate',
        }
        # Basic rsyslog configuration to create /var/log/kafkatee.log
        rsyslog::conf { 'kafkatee':
            source   => 'puppet:///modules/kafkatee/kafkatee_rsyslog.conf',
            priority => 70,
        }
    }
}
