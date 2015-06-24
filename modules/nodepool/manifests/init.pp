class nodepool(
    $nova_controller_hostname,
    $openstack_username,
    $openstack_password,
    $openstack_tenant_id,
) {

    package { 'nodepool':
        ensure => present,
    }

    $openstack_auth_url = "http://${nova_controller_hostname}:35357/v2.0/"

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
        content => shell_exports($nodepool_user_env),
    }


    # OpenStack CLI
    package { 'python-openstackclient':
        ensure => present,
    }

    file { '/etc/nodepool/elements':
        ensure  => directory,
        owner   => 'nodepool',
        group   => 'nodepool',
        recurse => true,
        pruge   => true,
        source  => 'puppet://modules/nodepool/elements',
        require => Package['nodepool'],


    file { '/etc/nodepool/nodepool.yaml':
        content => template('nodepool/nodepool.yaml.erb'),
        require => [
            Package['nodepool'],
            File['/etc/nodepool/elements'],
        ]
    }
}
