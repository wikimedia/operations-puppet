class nodepool( $nova_controller_hostname ) {

    package { 'nodepool':
        ensure => present,
    }

    # OpenStack CLI
    package { 'python-openstackclient':
        ensure => present,
    }

    file { '/etc/nodepool/nodepool.yaml':
        content => template('nodepool/nodepool.yaml.erb'),
        require => Package['nodepool'],
    }
}
