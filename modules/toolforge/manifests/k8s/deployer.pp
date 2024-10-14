# SPDX-License-Identifier: Apache-2.0
# toolforge specific config for deploying toolforge itself
class toolforge::k8s::deployer (
  Hash[String[1], String[1]] $toolforge_secrets,
) {
    file { '/etc/toolforge-deploy':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
    }

    file { '/etc/toolforge-deploy/secrets.yaml':
        ensure    => file,
        content   => to_yaml($toolforge_secrets),
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        show_diff => false,
    }

    # quite useful for deployment scripts
    ensure_packages(['python3-click'])
}
