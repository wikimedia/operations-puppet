# prometheus instance for PAWS
class profile::wmcs::paws::prometheus (
    Optional[Stdlib::Datasize] $storage_retention_size = lookup('profile::wmcs::paws::prometheus::storage_retention_size',   {default_value => undef}),
    String                     $region                 = lookup('profile::openstack::eqiad1::region'),
    Stdlib::Fqdn               $keystone_api_fqdn      = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String                     $observer_user          = lookup('profile::openstack::base::observer_user'),
    String                     $observer_password      = lookup('profile::openstack::eqiad1::observer_password'),
) {
    include ::profile::labs::cindermount::srv

    class { '::httpd':
        modules => ['proxy', 'proxy_http'],
    }

    prometheus::server { 'paws':
        listen_address         => '127.0.0.1:9903',
        external_url           => 'https://prometheus.paws.wmcloud.org/paws',
        storage_retention_size => $storage_retention_size,
        scrape_configs_extra   => [
            {
                'job_name'             => 'node',
                'openstack_sd_configs' => [
                    {
                        'role'              => 'instance',
                        'region'            => $region,
                        'identity_endpoint' => "https://${keystone_api_fqdn}:25000/v3",
                        'username'          => $observer_user,
                        'password'          => $observer_password,
                        'domain_name'       => 'default',
                        'project_name'      => $::labsproject,
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
                    },
                ]
            },
            {
                'job_name'             => 'haproxy',
                'openstack_sd_configs' => [
                    {
                        'role'              => 'instance',
                        'region'            => $region,
                        'identity_endpoint' => "https://${keystone_api_fqdn}:25000/v3",
                        'username'          => $observer_user,
                        'password'          => $observer_password,
                        'domain_name'       => 'default',
                        'project_name'      => $::labsproject,
                        'all_tenants'       => false,
                        'refresh_interval'  => '5m',
                        'port'              => 9901,
                    }
                ],
                'relabel_configs'      => [
                    {
                        'source_labels' => ['__meta_openstack_instance_name'],
                        'target_label'  => 'instance',
                    },
                    {
                        'source_labels' => ['__meta_openstack_instance_name'],
                        'action'        => 'keep',
                        'regex'         => 'haproxy',
                    },
                    {
                        'source_labels' => ['__meta_openstack_instance_status'],
                        'action'        => 'keep',
                        'regex'         => 'ACTIVE',
                    },
                ]
            },
            {
                'job_name'             => 'prometheus',
                'openstack_sd_configs' => [
                    {
                        'role'              => 'instance',
                        'region'            => $region,
                        'identity_endpoint' => "https://${keystone_api_fqdn}:25000/v3",
                        'username'          => $observer_user,
                        'password'          => $observer_password,
                        'domain_name'       => 'default',
                        'project_name'      => $::labsproject,
                        'all_tenants'       => false,
                        'refresh_interval'  => '5m',
                        'port'              => 9903,
                    }
                ],
                'relabel_configs'      => [
                    {
                        'source_labels' => ['__meta_openstack_instance_name'],
                        'target_label'  => 'instance',
                    },
                    {
                        'source_labels' => ['__meta_openstack_instance_name'],
                        'action'        => 'keep',
                        'regex'         => 'prometheus',
                    },
                    {
                        'source_labels' => ['__meta_openstack_instance_status'],
                        'action'        => 'keep',
                        'regex'         => 'ACTIVE',
                    },
                ]
            },
            {
                'job_name'       => 'jupyterhub',
                'scheme'         => 'https',
                'metrics_path'   => '/hub/metrics',
                'static_configs' => [
                    {
                        'targets' => ['hub.paws.wmcloud.org'],
                    },
                ],
            },
        ],
    }

    prometheus::web { 'paws':
        proxy_pass => 'http://localhost:9903/paws',
    }
}
