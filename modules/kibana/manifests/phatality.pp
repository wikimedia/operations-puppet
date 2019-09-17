class kibana::phatality () {
    $target = 'releng/phatality'

    scap::target { $target:
        deploy_user => 'deploy-service',
        manage_user => true,
        require     => [
            File['/srv/deployment'],
            Package['kibana'],
        ],
    }

    $installcmd = '/usr/share/kibana/bin/kibana-plugin install'
    $deploydir = "/srv/deployment/${target}"

    sudo::user { 'kibana-deploy-plugin':
        user       => 'deploy-service',
        privileges => [
            "ALL = (root) NOPASSWD: ${installcmd} ${deploydir}/*",
        ]
    }
}