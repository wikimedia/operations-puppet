# SPDX-License-Identifier: Apache-2.0
# Allow rsyncing phabricator data to other servers for hardware migration
# and setup scap user before deploying the first time to a new or reimaged server.
class profile::phabricator::migration (
    Stdlib::Fqdn        $src_host  = lookup('phabricator_active_server'),
    Array[Stdlib::Fqdn] $dst_hosts = lookup('profile::phabricator::migration::dst_hosts'),
) {

    class { '::scap::user': }
    class { '::phabricator::phd::user': }

    if $facts['fqdn'] in $dst_hosts {

        file { '/srv/repos':
            ensure => directory,
        }

        file { '/srv/dumps':
            ensure => directory,
        }

        file { '/srv/homes':
            ensure => directory,
        }

        ferm::service { 'phabricator-migration-rsync':
            proto  => 'tcp',
            port   => '873',
            srange => "(@resolve((${src_host})) @resolve((${src_host}), AAAA))",
        }

        class { 'rsync::server': }

        rsync::server::module { 'phabricator-srv-repos':
            path        => '/srv/repos',
            read_only   => 'no',
            hosts_allow => $src_host,
        }

        rsync::server::module { 'phabricator-srv-dumps':
            path        => '/srv/dumps',
            read_only   => 'no',
            hosts_allow => $src_host,
        }
    }
}
