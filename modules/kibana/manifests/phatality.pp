class kibana::phatality () {
    $target = 'releng/phatality'

    scap::target { $target:
        deploy_user => 'deploy-service',
        manage_user => true,
        require     => [
            Package['kibana'],
        ],
    }

    $plugincmd = '/usr/share/kibana/bin/kibana-plugin'
    $deploydir = '/srv/deployment/releng/phatality/deploy'

    sudo::user { 'kibana-deploy-phatality':
        user       => 'deploy-service',
        privileges => [
            "ALL = (kibana) NOPASSWD: ${plugincmd} file\\://${deploydir}/*",
            "ALL = (kibana) NOPASSWD: ${plugincmd} remove *",
        ]
    }

    file { '/usr/share/kibana/bin/upgrade-phatality.sh':
        ensure => 'file',
        mode   => '0555',
        source => 'puppet:///modules/kibana/upgrade-phatality.sh',
    }
}
