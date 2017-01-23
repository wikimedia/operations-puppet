# sets up rsync of APT repos between 2 servers
# activates rsync for push from the primary to secondary
class aptrepo::rsync {

    $primary_server = hiera('install_server', 'install1001.wikimedia.org')

    # only activate rsync/firewall hole on the server that is NOT active
    if $::fqdn != $primary_server {
        $aptrepo::ensure = 'present'
        include rsync::server
    } else {
        $aptrepo::ensure = 'absent'
    }

    ferm::service { 'aptrepo-rysnc'
        ensure => $aptrepo::ensure,
        proto  => 'tcp',
        port   => '873',
        srange => "@resolve(${primary_server})/32",
    }

    rsync::server::module { 'aptrepo-basedir':
        ensure      => $aptrepo::ensure,
        path        => $aptrepo::basedir,
        read_only   => 'no',
        hosts_allow => "@resolve(${primary_server})",
    }
}
