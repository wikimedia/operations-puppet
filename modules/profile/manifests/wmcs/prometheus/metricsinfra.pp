class profile::wmcs::prometheus::metricsinfra(
    Array[String] $projects          = lookup('profile::wmcs::prometheus::metricsinfra::projects'),
    Stdlib::Fqdn  $keystone_host     = lookup('profile::openstack::eqiad1::keystone_host'),
    String        $observer_password = lookup('profile::openstack::eqiad1::observer_password'),
    String        $observer_user     = lookup('profile::openstack::base::observer_user'),
    String        $region            = lookup('profile::openstack::eqiad1::region'),
) {
    # Project node-exporter scrape configuration
    $project_configs = $projects.map |String $project| {
        {
            'job_name'             => "${project}_node",
            'openstack_sd_configs' => [
                {
                    'role'              => 'instance',
                    'region'            => $region,
                    'identity_endpoint' => "http://${keystone_host}:5000/v3",
                    'username'          => $observer_user,
                    'password'          => $observer_password,
                    'domain_name'       => 'default',
                    'project_name'      => $project,
                    'all_tenants'       => false,
                    'refresh_interval'  => '5m',
                    'port'              => 9100,
                }
            ],
            'relabel_configs'      => [
                {
                    'source_labels' => ['__meta_openstack_instance_name'],
                    'target_label'  => 'instance',
                },
                {
                    'source_labels' => ['__meta_openstack_instance_status'],
                    'action'        => 'keep',
                    'regex'         => 'ACTIVE',
                }
            ]
        }
    }

    prometheus::server { 'cloud':
        listen_address       => '127.0.0.1:9900',
        scrape_configs_extra => $project_configs,
    }

    # Prometheus alert manager setup and config
    package { 'prometheus-alertmanager':
        ensure => present,
    }

    file { '/srv/prometheus/cloud/rules/alerts_projects.yml':
        ensure  => file,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/profile/wmcs/prometheus/metricsinfra/alerts_projects.yml',
        notify  => Exec['prometheus@cloud-reload'],
        require => Class['prometheus'],
    }

    # Apache config
    class { '::httpd':
        modules => ['proxy', 'proxy_http', 'rewrite', 'headers'],
    }

    httpd::site{ 'prometheus':
        priority => 10,
        content  => template('profile/wmcs/prometheus/prometheus-apache.erb'),
    }

    prometheus::web { 'cloud':
        proxy_pass => 'http://localhost:9900/cloud',
        require    => Httpd::Site['prometheus'],
    }

    ferm::service { 'prometheus-web':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }
}
