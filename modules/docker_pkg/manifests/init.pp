# SPDX-License-Identifier: Apache-2.0
# === Class docker_pkg
#
# Installs all tools needed to build docker images for the WMF.
class docker_pkg () {
    ensure_packages([
        'python3-virtualenv',
        'virtualenv', 'python3-pip',
        'python3-wheel', 'make'
    ])

    scap::target { 'docker-pkg/deploy':
        deploy_user => 'deploy-service',
        manage_user => true,
        require     => File['/srv/deployment']
    }
}
