# == Class role::syslog::centralserver
#
# Setup rsyslog as a receiver of cluster wide syslog messages.
#
class role::syslog::centralserver {
    include profile::base::production
    include profile::firewall
    include profile::backup::host
    include profile::syslog::centralserver
    include profile::bird::anycast
    include profile::kafkatee::webrequest::ops
    include profile::netconsole::server
    include profile::benthos
}
