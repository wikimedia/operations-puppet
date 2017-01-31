# == Class nodepool
#
# Install Nodepool and craft a setting file matching Wikimedia usage.
# For further configuration see the YAML configuration file:
#    modules/nodepool/templates/nodepool.yaml.erb
#
# Parameters:
#
# [*db_host*]
# MySQL database backend hostname
#
# [*db_name*]
# Database name on db_host
#
# [*db_user*]
# Database backend username
#
# [*db_pass]
# Database password associated to user db_user
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
# [*openstack_auth_url*]
# URI to the OpenStack authentication entry point.
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
    $db_host,
    $db_name,
    $db_user,
    $db_pass,
    $dib_base_path,
    $jenkins_api_user,
    $jenkins_api_key,
    $jenkins_credentials_id,
    $jenkins_ssh_private_key,
    $jenkins_ssh_public_key,
    $openstack_auth_url,
    $openstack_username,
    $openstack_password,
    $openstack_tenant_id,
) {

    package { 'nodepool':
        ensure => present,
    }

    # Override Debian package user shell so admins can login as nodepool
    user { 'nodepool':
        home    => '/var/lib/nodepool',
        shell   => '/bin/bash',
        system  => true,
        require => Package['nodepool'],
    }

    # Nodepool 0.1.0 requires novaclient>=2.21.0
    # Jessie has 2.18.1  (T104971)
    # jessie-backports has 3.3.1
    apt::pin { 'python-novaclient':
        pin      => 'release a=jessie-backports',
        priority => '1001',
        before   => Package['nodepool'],
    }
    apt::pin { 'python-openstackclient':
        pin      => 'release a=jessie-backports',
        priority => '1001',
        before   => Package['nodepool'],
    }

    # OpenStack CLI
    package { 'python-openstackclient':
        ensure  => present,
        require => Apt::Pin['python-openstackclient'],
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

    # Script to nicely stop Nodepool scheduler from systemd
    file { '/usr/bin/nodepool-graceful-stop':
        ensure => present,
        source => 'puppet:///modules/nodepool/nodepool-graceful-stop',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    base::service_unit { 'nodepool':
        ensure         => present,
        refresh        => true,
        systemd        => true,
        service_params => {},
        require        => [
            Package['nodepool'],
            File['/usr/bin/nodepool-graceful-stop'],
        ],
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
        os_auth_url  => $openstack_auth_url,
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
        content => join([
            shell_exports($nodepool_user_env),
            "\ncd\n"
        ]),
    }

    file { '/usr/local/bin/become-nodepool':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/nodepool/become-nodepool.sh',
    }

    file { '/usr/local/bin/check_nodepool_states':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/nodepool/check_nodepool_states.py',
    }

    file { '/var/lib/nodepool/.ssh':
        ensure => directory,
        owner  => 'nodepool',
        group  => 'nodepool',
        mode   => '0700',
    }
    # Private SSH key
    file { '/var/lib/nodepool/.ssh/dib_jenkins_id_rsa':
        ensure => absent,
    }
    file { '/var/lib/nodepool/.ssh/id_rsa':
        ensure  => present,
        content => $jenkins_ssh_private_key,
        owner   => 'nodepool',
        group   => 'nodepool',
        mode    => '0600',
    }
    # Matching public SSH key
    file { '/var/lib/nodepool/.ssh/dib_jenkins_id_rsa.pub':
        ensure => absent,
    }
    file { '/var/lib/nodepool/.ssh/id_rsa.pub':
        ensure  => present,
        content => $jenkins_ssh_public_key,
        owner   => 'nodepool',
        group   => 'nodepool',
        mode    => '0600',
    }

    file { '/etc/nodepool/logging.conf':
        ensure  => present,
        owner   => 'nodepool',
        group   => 'nodepool',
        mode    => '0444',
        source  => 'puppet:///modules/nodepool/logging.conf',
        require => Package['nodepool'],
    }

    file { '/etc/nodepool/nodepool.yaml':
        content => template('nodepool/nodepool.yaml.erb'),
        require => [
            Package['nodepool'],
        ]
    }
}
