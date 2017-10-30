# === Class docker::builder
#
# Installs all tools needed to build docker images for the WMF.
class docker::builder () {
    # Scap target for docker-pkg
    class { '::service::deploy::common': }
    scap::target { 'docker-pkg/deploy':
        deploy_user => 'deploy-service',
        manage_user => true,
    }
    require_package(['python3', 'python3-virtualenv', 'virtualenv', 'python3-pip'])
    # Scap target for docker-pkg
    class { '::service::deploy::common': }
    scap::target { 'docker-pkg/deploy':
        deploy_user => 'deploy-service',
        manage_user => true,
    }
}
