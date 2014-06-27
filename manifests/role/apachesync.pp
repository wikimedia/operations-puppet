# role for a host with apache sync scripts
class role::apachesync {

    system::role { 'apachesync':
        description => 'apache sync server',
    }

    include ::apachesync
    include misc::dsh
    include rsync::server
    include network::constants

}
