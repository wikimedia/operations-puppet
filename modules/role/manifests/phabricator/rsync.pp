class role::phabricator::migration {

    $phabricator_active_server = hiera('phabricator_active_server')

    if $::hostname != $phabricator_active_server {
        $hosts_allow= "@resolve(${pharicator_active_server})"

        ferm::service { 'phabricator-migration-rysnc':
            proto  => 'tcp',
            port   => '873',
            srange => "${hosts_allow}/32",
        }

        include rsync::server

        rsync::server::module { 'srv-phabricator':
            path        => '/srv/repos',
            read_only   => 'no',
            hosts_allow => $hosts_allow,
        }
    }

}
