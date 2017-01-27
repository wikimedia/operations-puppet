# sets up rsync of APT repos between 2 servers
# activates rsync for push from the primary to secondary
class aptrepo::rsync {

    $primary_server = hiera('install_server', 'install1001.wikimedia.org')
    $secondary_server = hiera('install_server_failover', 'install2001.wikimedia.org')

    if $::fqdn == $primary_server {

        $ensure_ferm = 'absent'
        $ensure_cron = 'present'
        $ensure_sync = 'absent'

    } else {

        $ensure_ferm = 'present'
        $ensure_cron = 'absent'
        $ensure_sync = 'present'

        include rsync::server

        rsync::server::module { 'aptrepo':
            ensure      => $ensure_sync,
            path        => $aptrepo::basedir,
            read_only   => 'no',
            hosts_allow => $primary_server,
        }
    }

    ferm::service { 'aptrepo-rsync':
        ensure => $ensure_ferm,
        proto  => 'tcp',
        port   => '873',
        srange => "@resolve(${primary_server})",
    }

    cron { 'rsync-aptrepo':
        ensure  => $ensure_cron,
        user    => 'root',
        command => "rsync -avp ${aptrepo::basedir} rsync://${secondary_server}/aptrepo',
        hour    => '*/6',
        minute  => '42',
    }
}
