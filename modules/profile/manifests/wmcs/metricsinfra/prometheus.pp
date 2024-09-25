# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::metricsinfra::prometheus(
    Stdlib::Fqdn $ext_fqdn          = lookup('profile::wmcs::metricsinfra::prometheus::ext_fqdn'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String       $observer_password = lookup('profile::openstack::eqiad1::observer_password'),
    String       $observer_user     = lookup('profile::openstack::base::observer_user'),
    String       $region            = lookup('profile::openstack::eqiad1::region'),
) {
    if debian::codename::ge('bullseye') {
        include ::profile::labs::cindermount::srv
    } else {
        include ::profile::labs::lvm::srv
    }

    class { '::prometheus': }

    # Base Prometheus data and configuration path
    $base_path = '/srv/prometheus/cloud'

    $metrics_path = "${base_path}/metrics"
    $targets_path = "${base_path}/targets"
    $rules_path = "${base_path}/rules"

    $listen_address = '127.0.0.1:9900'
    $external_url = "https://${$ext_fqdn}"

    $storage_retention = '730h'
    $min_block_duration = '2h'
    # TODO: check this is good when adding aggregation tools (Thanos or similar)
    $max_block_duration = '24h'

    $service_name = 'prometheus@cloud'

    ensure_packages('prometheus')

    # The default server instance must be stopped and masked to avoid conflicts.
    systemd::mask { 'prometheus.service': }
    service { 'prometheus':
        ensure => stopped,
    }

    # Note how the "prometheus" group is also granted access:
    # This allows the configurator user to access
    file { [$base_path, $metrics_path, $targets_path, $rules_path]:
        ensure => directory,
        mode   => '0770',
        owner  => 'prometheus',
        group  => 'prometheus',
    }

    systemd::service { $service_name:
        ensure         => present,
        restart        => true,
        content        => systemd_template('wmcs/metricsinfra/prometheus@'),
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }

    # Apache config
    class { '::httpd':
        modules => [
            'proxy',
            'proxy_http',
            'rewrite',
            'headers',
            'allowmethods',
        ],
    }

    httpd::site { 'prometheus':
        priority => 10,
        content  => epp(
          'profile/wmcs/metricsinfra/prometheus-apache.epp',
          { 'server_name' => $facts['fqdn'] }
        ),
    }

    prometheus::web { 'cloud':
        proxy_pass   => 'http://localhost:9900/',
        require      => Httpd::Site['prometheus'],
        redirect_url => '',
    }

    profile::wmcs::metricsinfra::prometheus_configurator::output_config { 'prometheus':
        kind    => 'prometheus',
        options => {
            base_directory   => $base_path,
            units_to_reload  => ['prometheus@cloud.service', 'prometheus-blackbox-exporter.service'],
            blackbox_address => 'localhost:9115',
            blackbox_dir     => '/etc/prometheus/blackbox.yml.d',
            blackbox_reload  => '/usr/local/bin/prometheus-assemble-config blackbox',
        },
    }

    thanos::sidecar { 'metricsinfra':
        prometheus_port     => 9900,
        prometheus_instance => 'cloud',
        http_port           => 19900,
        grpc_port           => 29900,
        base_path           => '',
    }

    class { 'prometheus::blackbox_exporter':
        manage_config     => false,
        default_modules   => 'absent',
        directory_group   => 'prometheus-configurator',
        with_gnmi_connect => false,
    }
}
