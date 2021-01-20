# == Class role::syslog::centralserver
#
# Setup rsyslog as a receiver of cluster wide syslog messages.
#
class role::syslog::centralserver {

    system::role { 'syslog::centralserver':
        description => 'Central syslog server and web requests debugging'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::syslog::centralserver
    include ::profile::bird::anycast
    include ::profile::kafkatee::webrequest::ops
}
