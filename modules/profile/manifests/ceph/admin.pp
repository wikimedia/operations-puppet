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
class profile::ceph::admin (
    Array[String[1]] $packages                       = lookup('profile::ceph::admin::packages'),
    Boolean          $infrastructure_as_code_enabled = lookup('profile::ceph::admin::infrastructure_as_code_enabled', {default_value => false}),
    String           $rgw_endpoint                   = lookup('profile::ceph::admin::rgw_endpoint', {default_value => ''}),
    String           $iam_access_key                 = lookup('profile::ceph::admin::iam_access_key', {default_value => ''}),
    String           $iam_secret_key                 = lookup('profile::ceph::admin::iam_secret_key', {default_value => ''}),

) {
    stdlib::ensure_packages($packages)

    if $infrastructure_as_code_enabled {
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

        file { '/srv/tofu-infra':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }

        $tofu_env = {
            'TF_VAR_rgw_endpoint' => $rgw_endpoint,
            'TF_VAR_access_key' => $iam_access_key,
            'TF_VAR_secret_key' => $iam_secret_key,
        }

        $tofu_env_str = $tofu_env.reduce('') |$memo, $value| {
            "${memo}export ${value[0]}=\"${value[1]}\"\n"
        }

        file { '/etc/tofu.env':
            ensure    => file,
            content   => $tofu_env_str,
            owner     => 'root',
            group     => 'root',
            mode      => '0550',
            show_diff => false,
        }
    }

}
