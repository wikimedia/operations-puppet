# sets up rsync of APT repos between 2 servers
# activates rsync for push from the primary to secondary
class aptrepo::rsync {

    $primary_server = hiera('aptrepo::primary_server', 'install1001.wikimedia.org')

    if $::hostname != $primary_server {

        ferm::service { 'aptrepo-rysnc':
            proto  => 'tcp',
            port   => '873',
            srange => "@resolve(${primary_server})/32",
        }

        include rsync::server

        rsync::server::module { 'aptrepo-basedir':
            path        => $aptrepo::basedir,
            read_only   => 'no',
            hosts_allow => @resolve($primary_server),
        }
    }
}
