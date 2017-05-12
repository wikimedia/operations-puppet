# setup rsyncd and config on the _non_-active phab server
# to allow pushing of /srv/repos from active to passive  (T137928)
class profile::phabricator::rsync {

    include rsync::server
    $phabricator_active_server_fqdn = hiera('phabricator_active_server_fqdn')

    if $::fqdn != $phabricator_active_server_fqdn {

        $hosts_allow_ferm_v4 = "@resolve((${phabricator_active_server_fqdn}))"
        $hosts_allow_ferm_v6 = "@resolve((${phabricator_active_server_fqdn}), AAAA)"

        ferm::service { 'phabricator-repo-rsync':
            proto  => 'tcp',
            port   => '873',
            srange => "(${hosts_allow_ferm_v4} ${hosts_allow_ferm_v6})",
        }

        rsync::server::module { 'phab-srv-repos':
            path        => '/srv/repos',
            read_only   => 'no',
            hosts_allow => $phabricator_active_server_fqdn,
        }
    }

}
