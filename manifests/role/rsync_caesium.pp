# T124261 - temporary
class role::rsync_caesium {

    # caesium.eqiad.wmnet
    $sourceip='10.64.32.145'

    include rsync::server

    rsync::server::module { 'releases':
        path        => '/srv/org/wikimedia',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'releases_home':
        path        => '/home',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    ferm::service { 'caesium_rsyncd':
        proto => 'tcp',
        port  => '873',
    }
}
