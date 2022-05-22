# Set up metricsinfra-specific configuration for the karma Dashboard
class profile::wmcs::metricsinfra::alertmanager::karma (
    String              $vhost                         = lookup('profile::wmcs::metricsinfra::alertmanager::karma::vhost', {'default_value' => 'prometheus-alerts.wmcloud.org'}),
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

    file { '/etc/karma-acl-silences.yaml':
        content => template('profile/wmcs/metricsinfra/alertmanager/karma-acls.yml.erb'),
        require => Package['karma'],
        notify  => Service['karma'],
    }
}
