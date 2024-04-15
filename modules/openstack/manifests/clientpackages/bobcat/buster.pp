# SPDX-License-Identifier: Apache-2.0

class openstack::clientpackages::bobcat::buster(
) {
    $py2packages = [
        'python-novaclient',
        'python-glanceclient',
        'python-keystoneclient',
        'python-openstackclient',
        'python-designateclient',
        'python-neutronclient',
    ]

    $py3packages = [
        'python3-novaclient',
        'python3-glanceclient',
        'python3-keystoneauth1',
        'python3-keystoneclient',
        # Openstacksdk is needed only to ensure the patch to it is applied in order
        # once the patch is not needed can be removed
        'python3-openstacksdk',
        'python3-openstackclient',
        'python3-troveclient',
        'python3-designateclient',
        'python3-neutronclient',
        'python3-osc-placement',
        'python3-tenacity',
    ]

    $otherpackages = [
        'ebtables',
        'python-netaddr',
        'patch',
    ]

    ensure_packages($py2packages + $py3packages + $otherpackages)


    # Wrapper python class to easily query openstack clients
    file { '/usr/lib/python2.7/dist-packages/mwopenstackclients.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientpackages/py2/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
    file { '/usr/lib/python3/dist-packages/mwopenstackclients.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientpackages/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # Apply https://review.opendev.org/c/openstack/openstacksdk/+/893283
    $instance_dir_to_patch = '/usr/lib/python3/dist-packages/openstack'
    $instance_patch_file = "${instance_dir_to_patch}.patch"
    file {$instance_patch_file:
        source => 'puppet:///modules/openstack/bobcat/openstacksdk/hacks/allow_overriding_cloud_yaml.patch',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    exec { "apply ${instance_patch_file}":
        command => "/usr/bin/patch --forward --strip=2 --directory=${instance_dir_to_patch} --input=${instance_patch_file}",
        unless  => "/usr/bin/patch --reverse --strip=2 --dry-run -f --directory=${instance_dir_to_patch} --input=${instance_patch_file}",
        require => [File[$instance_patch_file], Package['python3-openstacksdk']],
    }
}
