# setup rsyncd and config on the _non_-active phab server
# to allow pushing of /srv/repos from active to passive  (T137928)
class role::phabricator::rsync {

    $phabricator_active_server_fqdn = hiera('phabricator_active_server_fqdn')

    if $::fqdn != $phabricator_active_server_fqdn {
        $hosts_allow = "@resolve((${phabricator_active_server_fqdn}))"

        ferm::service { 'phabricator-repo-rsync':
            proto  => 'tcp',
            port   => '873',
            srange => $hosts_allow,
        }

        include rsync::server

        rsync::server::module { 'phab-srv-repos':
            path        => '/srv/repos',
            read_only   => 'no',
            hosts_allow => $hosts_allow,
        }
    }

}
