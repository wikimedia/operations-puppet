# == Class nodepool
#
# Install Nodepool and craft a setting file matching Wikimedia usage.
# For further configuration see the YAML configuration file:
#    modules/nodepool/templates/nodepool.yaml.erb
#
# Parameters:
#
# [*dib_base_path*]
# Directory holding python-diskimagebuilder material. Will create
# subdirectories 'cache', 'images' and 'tmp'.
#
# [*jenkins_api_user*]
# A Jenkins username that has the rights to attach/detach a slave on the
# Jenkins masters.
#
# [*jenkins_api_key*]
# API token (not password) for *jenkins_api_user*
#
# [*jenkins_credentials_id*]
# Reference to a SSH user/private key hold in the Jenkins credential stores.
# Used by Jenkins to ssh to instances.
#
# [*jenkins_ssh_private_key*]
# The private SSH key. Used by Jenkins and Nodepool to ssh to instances.
#
# [*jenkins_ssh_public_key*]
# Public SSH key for above private key. Used by Jenkins and Nodepool to ssh to
# instances.
#
# [*openstack_auth_uri*]
# URI to the OpenStack authentication service.
#
# [*openstack_username*]
# User for the OpenStack API, must be able to upload/delete images and
# spawn/terminate instances.
#
# [*openstack_password*]
# OpenStack password for *openstack_username*.
#
# [*openstack_tenant_id*]
# OpenStack tenant holding the instances. Equivalent of wmflabs 'project name'.
class nodepool(
    $dib_base_path,
    $jenkins_api_user,
    $jenkins_api_key,
    $jenkins_credentials_id,
    $jenkins_ssh_private_key,
    $jenkins_ssh_public_key,
    $openstack_auth_uri,
    $openstack_username,
    $openstack_password,
    $openstack_tenant_id,
) {

    package { 'nodepool':
        ensure => present,
    }
    # python-diskimage-builder 0.1.46 missing dependency:
    # https://bugs.debian.org/791655
    package { 'uuid-runtime':
        ensure => present,
    }

    # guest disk image management system - tools
    # eg: virt-inspector, virt-ls ...
    package { 'libguestfs-tools':
        ensure => present,
    }

    # Recursively create $dib_base_path since Puppet does not support that
    exec { 'create_dib_base_path':
        command => "/bin/mkdir -p ${dib_base_path}",
        creates => $dib_base_path,
    }

    file { $dib_base_path:
        owner   => 'nodepool',
        group   => 'nodepool',
        mode    => '0775',
        require => [
            Exec['create_dib_base_path'],
            Package['nodepool'],
        ],
    }

    $dib_cache_dir  = "${dib_base_path}/cache"
    $dib_images_dir = "${dib_base_path}/images"
    $dib_tmp_dir    = "${dib_base_path}/tmp"

    file { [
        $dib_cache_dir,
        $dib_images_dir,
        $dib_tmp_dir,
        ]:
            ensure  => directory,
            owner   => 'nodepool',
            group   => 'nodepool',
            mode    => '0775',
            require => [
                Package['nodepool'],
                File[$dib_base_path],
            ],
    }

    $nodepool_user_env = {
        os_auth_uri  => $openstack_auth_uri,
        os_username  => $openstack_username,
        os_password  => $openstack_password,
        os_tenant_id => $openstack_tenant_id,
    }
    validate_hash($nodepool_user_env)

    file { '/var/lib/nodepool/.profile':
        ensure  => present,
        require => Package['nodepool'],  # provides nodepool user and homedir
        owner   => 'nodepool',
        group   => 'nodepool',
        mode    => '0440',
        content => shell_exports($nodepool_user_env),
    }

    # OpenStack CLI
    package { 'python-openstackclient':
        ensure => present,
    }

    file { '/var/lib/nodepool/.ssh':
        ensure => directory,
        owner  => 'nodepool',
        group  => 'nodepool',
        mode   => '0700',
    }
    # Private SSH key
    file { '/var/lib/nodepool/.ssh/dib_jenkins_id_rsa':
        ensure  => present,
        content => $jenkins_ssh_private_key,
        owner   => 'nodepool',
        group   => 'nodepool',
        mode    => '0600',
    }
    # Matching public SSH key
    file { '/var/lib/nodepool/.ssh/dib_jenkins_id_rsa.pub':
        ensure  => present,
        content => $jenkins_ssh_public_key,
        owner   => 'nodepool',
        group   => 'nodepool',
        mode    => '0600',
    }

    file { '/etc/nodepool/elements':
        ensure  => directory,
        owner   => 'nodepool',
        group   => 'nodepool',
        recurse => true,
        purge   => true,
        source  => 'puppet:///modules/nodepool/elements',
        require => Package['nodepool'],
    }

    file { '/etc/nodepool/nodepool.yaml':
        content => template('nodepool/nodepool.yaml.erb'),
        require => [
            Package['nodepool'],
            File['/etc/nodepool/elements'],
        ]
    }
}
