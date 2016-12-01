class role::phabricator::migration {

    $phabricator_active_server = hiera('phabricator_active_server')

    if if $::hostname != $phabricator_active_server {
        $sourceip='10.64.32.150'

        ferm::service { 'phabricator-migration-rysnc':
            proto  => 'tcp',
            port   => '873',
            srange => "${sourceip}/32",
        }

        include rsync::server

        rsync::server::module { 'srv-phabricator':
            path        => '/srv/repos',
            read_only   => 'no',
            hosts_allow => $sourceip,
        }
    }

}
