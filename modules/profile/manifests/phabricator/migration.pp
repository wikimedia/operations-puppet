# SPDX-License-Identifier: Apache-2.0
# Allow rsyncing phabricator data to other servers for hardware migration
class profile::phabricator::migration (
    Stdlib::Fqdn        $src_host  = lookup('profile::phabricator::migration::src_host'),
    Array[Stdlib::Fqdn] $dst_hosts = lookup('profile::phabricator::migration::dst_hosts'),
) {

    systemd::sysuser { 'phd':
        ensure      => present,
        id          => '920:920',
        description => 'Phabricator daemon user',
        home_dir    => '/var/run/phd',
    }

    if $facts['fqdn'] in $dst_hosts {

        file { '/srv/repos':
            ensure => 'directory',
        }

        file { '/srv/dumps':
            ensure => 'directory',
        }

        file { '/srv/homes':
            ensure => 'directory',
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
