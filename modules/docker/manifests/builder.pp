# === Class docker::builder
#
# Installs all tools needed to build docker images for the WMF.
class docker::builder () {
    require_package(['python3', 'python3-virtualenv', 'virtualenv', 'python3-pip'])
    # Scap target for docker-pkg
    file { '/srv/deployment':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    scap::target { 'docker-pkg/deploy':
        deploy_user => 'deploy-service',
        manage_user => true,
    }
}
