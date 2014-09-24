# role for a host with apache sync scripts
class role::apachesync {

    system::role { 'apachesync':
        description => 'apache sync server',
    }

    include ::apachesync
    include dsh
    include rsync::server
    include network::constants

}
