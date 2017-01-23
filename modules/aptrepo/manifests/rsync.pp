# sets up rsync of APT repos between 2 servers
# activates rsync for push from the primary to secondary
class aptrepo::rsync {

    $primary_server = hiera('install_server', 'install1001.wikimedia.org')

    # only activate rsync/firewall hole on primary server
    if $::fqdn != $primary_server {
        aptrepo_ensure = 'present'
	include rsync::server
    } else {
	aptrepo_ensure = 'absent'
    }

    ferm::service { 'aptrepo-rysnc'
        ensure => $aptrepo_ensure,
        proto  => 'tcp',
        port   => '873',
        srange => "@resolve(${primary_server})/32",
    }

    rsync::server::module { 'aptrepo-basedir':
        ensure      => $aptrepo_ensure,
        path        => $aptrepo::basedir,
        read_only   => 'no',
        hosts_allow => "@resolve(${primary_server})",
    }
}
