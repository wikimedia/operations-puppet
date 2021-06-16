# Set up metricsinfra-specific configuration for the karma Dashboard
class profile::wmcs::metricsinfra::alertmanager::karma (
    String              $vhost                         = lookup('profile::wmcs::metricsinfra::alertmanager::karma::vhost', {'default_value' => 'prometheus-alerts.wmcloud.org'}),
    Array[String]       $sudo_projects                 = lookup('profile::wmcs::metricsinfra::alertmanager::karma::sudo_projects', {default_value => ['admin', 'metricsinfra', 'cloudinfra']}),
    Array[Stdlib::Fqdn] $prometheus_alertmanager_hosts = lookup('profile::wmcs::metricsinfra::prometheus_alertmanager_hosts'),
) {
    class { 'httpd':
        modules => [
            'proxy',
            'proxy_http',
            'rewrite',
            'headers',
            'allowmethods',
        ],
    }

    class { 'alertmanager::karma':
        vhost          => $vhost,
        config         => template('profile/wmcs/metricsinfra/alertmanager/karma.yml.erb'),
        listen_address => '0.0.0.0',
        listen_port    => 19194,
        auth_header    => 'X-CAS-uid',
    }

    profile::idp::client::httpd::site { $vhost:
        document_root    => '/var/www/html',
        vhost_content    => 'profile/idp/client/httpd-karma-cloud.erb',
        proxied_as_https => true,
    }

    # create this so Karma can start before the configurator runs
    file { '/etc/karma-acl-silences.yaml':
        ensure  => file,
        content => 'rules: []',
        owner   => 'prometheus-configurator',
        group   => 'prometheus-configurator',
        replace => false,
    }

    $main_config = {
        sudo_projects        => $sudo_projects,
        project_group_format => 'cn=project-{project},ou=groups,dc=wikimedia,dc=org',
    }

    file { '/etc/prometheus-configurator/config.d/karma_acls_config.yaml':
        content => to_yaml($main_config),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    profile::wmcs::metricsinfra::prometheus_configurator::output_config { 'karma_acls':
        kind    => 'karma_acl',
        options => {
            acl_file_path    => '/etc/karma-acl-silences.yaml',
            units_to_restart => [
                'karma.service',
            ]
        },
    }
}
