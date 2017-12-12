# sets up rsync of APT repos between 2 servers
# activates rsync for push from the primary to secondary
class aptrepo::rsync (
    $primary_server = hiera('install_server'),
    $secondary_server = hiera('install_server_failover'),
){
    # only activate rsync/firewall hole on the server that is NOT active
    if $::fqdn == $primary_server {

        $ensure_ferm = 'absent'
        $ensure_cron = 'present'
        $ensure_sync = 'absent'

    } else {

        $ensure_ferm = 'present'
        $ensure_cron = 'absent'
        $ensure_sync = 'present'

        include rsync::server

        rsync::server::module { 'install-srv':
            ensure      => $aptrepo::rsync::ensure,
            path        => '/srv',
            read_only   => 'no',
            hosts_allow => $primary_server,
        }

        rsync::server::module { 'install-home':
            ensure      => $aptrepo::rsync::ensure,
            path        => '/home',
            read_only   => 'no',
            hosts_allow => $primary_server,
        }
    }

    ferm::service { 'aptrepo-rsync':
        ensure => $ensure_ferm,
        proto  => 'tcp',
        port   => '873',
        srange => "(@resolve((${primary_server})) @resolve((${primary_server}), AAAA))",
    }

    cron { 'rsync-aptrepo':
        ensure  => $ensure_cron,
        user    => 'root',
        command => "rsync -avp --delete /srv/ rsync://${secondary_server}/install-srv > /dev/null",
        hour    => '*/6',
        minute  => '42',
    }
}
