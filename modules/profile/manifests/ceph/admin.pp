# SPDX-License-Identifier: Apache-2.0
# Class: profile::ceph::admin
#
# This profile installs the tools that an SRE uses on a Ceph administration
# host. profile::ceph::client supplies the cluster configuration and the
# administrative keyring.
#
# Later work adds the desired state file, the apply tooling and the gateway
# credentials to this profile.
#
# See #T435608
#
# @param packages The administration tools to install.
# @param rgw_endpoint The endpoint of the Rados Gateway API
# @param iam_root_access_key Access key associated with a global opentofu user
# @param iam_root_secret_key Secret key associated with a global opentofu user
# @param accounts Hash of structure <account>: {account_id: xxx, access_key: xxx, secret_key: xxx} used to manage resources in each Ceph account
# @param global_users Hash of structure <account>: {access_key: xxx, secret_key: xxx} used to manage global Ceph users
# @param dpe_infra_config opentofu resource configuration, used by the dpe-infra repository
# @param tofu_root_modules The OpenTofu root modules in /srv/tofu-infra/resources. A path unit
#   watches the state file of each one.
# @param state_hosts The administration host of each site. Each host keeps a copy of the
#   OpenTofu state snapshots of the other sites.
class profile::ceph::admin (
    Array[String[1]]                   $packages            = lookup('profile::ceph::admin::packages'),
    Array[String[1], 1]                $tofu_root_modules   = lookup('profile::ceph::admin::tofu_root_modules'),
    Hash[String[1], Stdlib::Fqdn, 1]   $state_hosts         = lookup('profile::ceph::admin::state_hosts'),
    String                             $rgw_endpoint        = lookup('profile::ceph::admin::rgw_endpoint', {default_value => ''}),
    String                             $iam_root_access_key = lookup('profile::ceph::admin::iam_root_access_key', {default_value => ''}),
    String                             $iam_root_secret_key = lookup('profile::ceph::admin::iam_root_secret_key', {default_value => ''}),
    Hash[String, Hash[String, String]] $accounts            = lookup('profile::ceph::admin::accounts', {default_value => {}}),
    Hash[String, Hash[String, String]] $global_users        = lookup('profile::ceph::admin::global_users', {default_value => {}}),
    Hash[String, Any]                  $dpe_infra_config    = lookup('profile::ceph::admin::dpe_infra::config', {default_value => {}}),

) {
    stdlib::ensure_packages($packages)

    apt::package_from_component { 'tofu':
        component => 'thirdparty/tofu',
        packages  => ['tofu'],
    }

    file { '/root/.tofurc':
        ensure => file,
        source => 'puppet:///modules/profile/openstack/base/opentofu/tofurc',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    file { '/root/.config/.tofurc':
        ensure => absent,
    }

    file { '/usr/local/bin/tofu':
        ensure => file,
        source => 'puppet:///modules/profile/openstack/base/opentofu/tofu-wrapper.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $tofu_env = {
        'TF_VAR_rgw_endpoint' => $rgw_endpoint,
        'TF_VAR_root_access_key' => $iam_root_access_key,
        'TF_VAR_root_secret_key' => $iam_root_secret_key,
        'TF_VAR_accounts' => $accounts.stdlib::to_json(),
        'TF_VAR_global_users' => $global_users.stdlib::to_json(),
    }

    $tofu_env_str = $tofu_env.reduce('') |$memo, $value| {
        "${memo}export ${value[0]}='${value[1]}'\n"
    }

    file { '/etc/tofu.env':
        ensure    => file,
        content   => $tofu_env_str,
        owner     => 'root',
        group     => 'root',
        mode      => '0550',
        show_diff => false,
    }

    git::clone { 'repos/sre/dpe-infra':
        ensure        => 'latest',
        branch        => 'main',
        source        => 'gitlab',
        directory     => '/srv/tofu-infra',
        owner         => 'root',
        group         => 'root',
        update_method => 'checkout',
        before        => File['/srv/tofu-infra/config.yaml'],
    }

    file { '/srv/tofu-infra/config.yaml':
        ensure  => file,
        content => $dpe_infra_config.stdlib::to_yaml(),
    }

    # Keep the history of each OpenTofu state file - See #T440891
    $snapshot_dir = '/srv/tofu-state-snapshots'
    $site_snapshot_dir = "${snapshot_dir}/${::site}"
    $staging_dir = "${snapshot_dir}/.staging"
    $snapshot_command = '/usr/local/sbin/tofu-state-snapshot'

    file { [$snapshot_dir, $site_snapshot_dir, $staging_dir]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }

    file { $snapshot_command:
        ensure => file,
        source => 'puppet:///modules/profile/ceph/admin/tofu_state_snapshot.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    systemd::timer::job { 'tofu-state-snapshot':
        ensure              => present,
        description         => 'Take a snapshot of the OpenTofu state files that changed',
        command             => "${snapshot_command} --snapshot-dir ${site_snapshot_dir} --staging-dir ${staging_dir}",
        user                => 'root',
        interval            => {'start' => 'OnCalendar', 'interval' => '*-*-* *:05/10:00'},
        max_runtime_seconds => 300,
        team                => 'Data Platform',
        require             => File[$snapshot_command, $site_snapshot_dir, $staging_dir],
    }

    # The path unit can start the service several times in a few seconds.
    systemd::override { 'tofu-state-snapshot-start-limit':
        unit    => 'tofu-state-snapshot',
        content => "[Unit]\nStartLimitIntervalSec=0\n",
    }

    # Declare the path unit without systemd::service, because systemd::timer already
    # declares Systemd::Service['tofu-state-snapshot'] for the timer.
    service { 'tofu-state-snapshot.path':
        ensure    => running,
        enable    => true,
        provider  => 'systemd',
        require   => Systemd::Unit['tofu-state-snapshot.service'],
        subscribe => Systemd::Unit['tofu-state-snapshot.path'],
    }

    systemd::unit { 'tofu-state-snapshot.path':
        content => epp('profile/ceph/admin/tofu-state-snapshot.path.epp', {
            'state_files' => $tofu_root_modules.map |$module| {
                "/srv/tofu-infra/resources/${module}/terraform.tfstate"
            },
            'unit'        => 'tofu-state-snapshot.service',
        }),
        team    => 'Data Platform',
    }

    # Keep a copy of the snapshots of the other sites - See #T440891
    unless $state_hosts[$::site] == $facts['networking']['fqdn'] {
        fail("profile::ceph::admin::state_hosts must map ${::site} to ${facts['networking']['fqdn']}")
    }

    # stunnel starts its own rsync for each TLS connection, so stop the cleartext daemon.
    class { 'rsync::server':
        ensure_service => 'stopped',
        address        => '127.0.0.1',
    }

    $state_hosts.each |String $site, Stdlib::Fqdn $host| {
        $peers = values($state_hosts - [$site])
        unless $peers.empty {
            # quickdatacopy uses the same path on both hosts, so never point it at /srv/tofu-infra.
            rsync::quickdatacopy { "tofu-state-${site}":
                source_host         => $host,
                dest_host           => $peers,
                module_path         => "${snapshot_dir}/${site}",
                server_uses_stunnel => true,
                require             => File[$snapshot_dir],
            }
        }
    }
}
