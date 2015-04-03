class nodepool( $nova_controller_hostname ) {

    file { '/etc/nodepool/nodepool.yaml':
        content => template('nodepool/nodepool.yaml.erb')
    }
}
