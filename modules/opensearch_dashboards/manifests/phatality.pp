# SPDX-License-Identifier: Apache-2.0
class opensearch_dashboards::phatality () {
    $target = 'releng/phatality'

    scap::target { $target:
        deploy_user => 'deploy-service',
        manage_user => true,
        require     => [
            Package['opensearch-dashboards'],
        ],
    }

    $plugincmd = '/usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin'
    $deploydir = '/srv/deployment/releng/phatality/deploy'

    sudo::user { 'opensearch-dashboards-deploy-phatality':
        user       => 'deploy-service',
        privileges => [
            "ALL = (opensearch-dashboards) NOPASSWD: ${plugincmd} install file\\://${deploydir}/*",
            "ALL = (opensearch-dashboards) NOPASSWD: ${plugincmd} remove *",
            'ALL = (root) NOPASSWD: /usr/bin/systemctl restart opensearch-dashboards',
        ]
    }

    # All files in /usr/share/opensearch-dashboards are owned by root, but `opensearch-dashboards-plugin install`
    # recommends it not be run as root.
    # Here we will change ownership of the plugins directory to opensearch-dashboards so that plugin installation
    # can be run as the opensearch-dashboards user.
    file { '/usr/share/opensearch-dashboards/plugins':
      owner   => 'opensearch-dashboards',
      group   => 'opensearch-dashboards',
      require => Package['opensearch-dashboards']
    }

    file { '/usr/share/opensearch-dashboards/bin/upgrade-phatality.sh':
        ensure => 'file',
        mode   => '0555',
        source => 'puppet:///modules/opensearch_dashboards/upgrade-phatality.sh',
    }
}
