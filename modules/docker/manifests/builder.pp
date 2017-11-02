# === Class docker::builder
#
# Installs all tools needed to build docker images for the WMF.
class docker::builder () {
    require_package([
        'python3', 'python3-virtualenv',
        'virtualenv', 'python3-pip',
        'python3-wheel',
    ])

    scap::target { 'docker-pkg/deploy':
        deploy_user => 'deploy-service',
        manage_user => true,
        require     => File['/srv/deployment']
    }
}
