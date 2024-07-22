# SPDX-License-Identifier: Apache-2.0
# Allow rsyncing phabricator data to other servers for hardware migration
# and setup scap user before deploying the first time to a new or reimaged server.
class profile::phabricator::migration (
    Stdlib::Fqdn        $src_host  = lookup('phabricator_active_server'),
    Array[Stdlib::Fqdn] $dst_hosts = lookup('profile::phabricator::migration::dst_hosts'),
) {

    # setup scap user and symlink to binary before the first deploy and
    # before 'scap install-world' has installed scap itself (T357572)

    $scap_path = '/var/lib/scap/scap/bin'

    class { '::scap::user': }

    wmflib::dir::mkdir_p($scap_path, {
        owner   => 'scap',
        require => Class['scap::user'],
    })

    file { '/usr/bin/scap':
        ensure  => 'link',
        target  => "${scap_path}/scap",
        require => File[$scap_path],
    }

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

        firewall::service { 'phabricator-migration-rsync':
            proto  => 'tcp',
            port   => [873],
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
