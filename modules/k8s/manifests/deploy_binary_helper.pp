define k8s::deploy_binary_helper() {
    file { "/usr/local/bin/deploy-${title}":
        content => template('k8s/deploy-binary-helper'),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }
}
