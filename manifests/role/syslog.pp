# == Class role::syslog::centralserver
#
# Setup syslog-ng as a receiver of cluster wide syslog messages.
#
class role::syslog::centralserver {

    system::role { 'role::syslog::centralserver': description => 'Central syslog server' }


    class { 'misc::syslog-server':
        config   => 'nfs',
        basepath => '/home/wikipedia/syslog',
    }

}

# == Class role::syslog::centralserver::beta
#
# Setup syslog-ng as a receiver for the beta cluster syslog messages.
#
class role::syslog::centralserver::beta {

    system::role { 'role::syslog::centralserver::beta': description => 'Central syslog server for beta cluster' }

    if $::realm == 'production' {
        fail( 'role::syslog::centralserver::beta must not be used in production' )
    }

    class { 'misc::syslog-server':
        config   => 'nfs',
        basepath => '/data/project/syslog',
    }

}
