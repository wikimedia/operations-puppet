# Sets up rsyncd and common modules
# for statistic servers.  Currently
# this is read/write between statistic
# servers in /a.
#
# Parameters:
#   hosts_allow - array.  Hosts to grant rsync access.
class statistics::rsyncd($hosts_allow = undef) {
    # this uses modules/rsync to
    # set up an rsync daemon service
    include rsync::server

    # Set up an rsync module
    # (in /etc/rsync.conf) for /a.
    rsync::server::module { 'a':
        path        => '/a',
        read_only   => 'no',
        list        => 'yes',
        hosts_allow => $hosts_allow,
    }

    # Set up an rsync module
    # (in /etc/rsync.conf) for /var/www.
    # This will allow $hosts_allow to host public data files
    # from the default Apache VirtualHost.
    rsync::server::module { 'www':
        path        => '/var/www',
        read_only   => 'no',
        list        => 'yes',
        hosts_allow => $hosts_allow,
    }
}

