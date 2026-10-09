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
# @param dpe_infra_config opentofu resource configuration, used by the dpe-infra repository
class profile::ceph::admin (
    Array[String[1]]                   $packages            = lookup('profile::ceph::admin::packages'),
    String                             $rgw_endpoint        = lookup('profile::ceph::admin::rgw_endpoint', {default_value => ''}),
    String                             $iam_root_access_key = lookup('profile::ceph::admin::iam_root_access_key', {default_value => ''}),
    String                             $iam_root_secret_key = lookup('profile::ceph::admin::iam_root_secret_key', {default_value => ''}),
    Hash[String, Hash[String, String]] $accounts            = lookup('profile::ceph::admin::accounts', {default_value => {}}),
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
        directory     => '/srv/dpe-infra',
        owner         => 'root',
        group         => 'root',
        update_method => 'checkout',
        before        => File['/srv/dpe-infra/config.yaml'],
    }

    file { '/srv/dpe-infra/config.yaml':
        ensure  => file,
        content => $dpe_infra_config.stdlib::to_yaml(),
    }

}
