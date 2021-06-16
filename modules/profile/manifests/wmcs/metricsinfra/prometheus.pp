class profile::wmcs::metricsinfra::prometheus(
    Array[Hash]  $projects          = lookup('profile::wmcs::metricsinfra::monitored_projects'),
    Stdlib::Fqdn $ext_fqdn          = lookup('profile::wmcs::metricsinfra::prometheus::ext_fqdn'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String       $observer_password = lookup('profile::openstack::eqiad1::observer_password'),
    String       $observer_user     = lookup('profile::openstack::base::observer_user'),
    String       $region            = lookup('profile::openstack::eqiad1::region'),
) {
    # Base Prometheus data and configuration path
    $base_path = '/srv/prometheus/cloud'

    # This is mostly just to deal with the installation and systemd parts.
    # prometheus-configurator will deal with the configuration
    prometheus::server { 'cloud':
        # Localhost is being used here to pass prometheus module input validation
        alertmanagers        => [ 'localhost:9093', ],
        external_url         => "https://${$ext_fqdn}/cloud",
        listen_address       => '127.0.0.1:9900',
        scrape_configs_extra => [],
    }

    # Let the configurator user (in the prometheus group) see necesary files
    File <| title == $base_path |> {
        group => 'prometheus',
    }

    # Let the configurator user manage the config file:
    # change ownership, add write access, do not overwrite
    File <| title == "${base_path}/prometheus.yml" |> {
        owner   => 'prometheus',
        group   => 'prometheus',
        mode    => '0664',
        replace => false,
    }

    # Let the configurator user fully manage alert rules
    File <| title == "${base_path}/rules" |> {
        owner   => 'prometheus',
        group   => 'prometheus',
        mode    => '0775',
    }

    # Apache config
    # TODO: once prometheus01.metricsinfra. no longer has
    # alertmanager running on it too, remove this defined check
    if !defined(Class['Httpd']) {
        class { '::httpd':
            modules => [
                'proxy',
                'proxy_http',
                'rewrite',
                'headers',
                'allowmethods',
            ],
        }
    }

    httpd::site { 'prometheus':
        priority => 10,
        content  => template('profile/wmcs/metricsinfra/prometheus-apache.erb'),
    }

    prometheus::web { 'cloud':
        proxy_pass => 'http://localhost:9900/cloud',
        require    => Httpd::Site['prometheus'],
    }

    profile::wmcs::metricsinfra::prometheus_configurator::output { 'prometheus':
        kind    => 'prometheus',
        options => {
            base_directory  => $base_path,
            units_to_reload => [
                'prometheus@cloud.service',
            ]
        },
    }
}
