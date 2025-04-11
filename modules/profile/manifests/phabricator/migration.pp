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

    file { '/usr/local/sbin/phab_deploy_config_deploy':
        content => file('phabricator/phab_deploy_config_deploy.sh'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
    }

    file { '/usr/local/sbin/phab_deploy_promote':
        content => file('phabricator/phab_deploy_promote.sh'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
    }

    file { '/usr/local/sbin/phab_deploy_finalize':
        content => template('phabricator/phab_deploy_finalize.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
    }

    file { '/usr/local/sbin/phab_deploy_rollback':
        content => file('phabricator/phab_deploy_rollback.sh'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
    }

    $sudo_rules = [
        'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_config_deploy',
        'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_promote',
        'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_rollback',
        'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_finalize',
    ]

    scap::target { 'phabricator/deployment':
        deploy_user => 'phab-deploy',
        key_name    => 'phabricator',
        manage_user => true,
        require     => File['/usr/local/sbin/phab_deploy_finalize'],
        sudo_rules  => $sudo_rules,
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
            srange => [$src_host],
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
