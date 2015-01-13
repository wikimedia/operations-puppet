# == Class role::syslog::centralserver
#
# Setup syslog-ng as a receiver of cluster wide syslog messages.
#
class role::syslog::centralserver {

    system::role { 'role::syslog::centralserver': description => 'Central syslog server' }

    class { 'misc::syslog-server': }
}
