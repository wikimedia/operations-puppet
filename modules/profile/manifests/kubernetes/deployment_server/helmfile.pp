class profile::kubernetes::deployment_server::helmfile(
    Hash[String, Any] $services=hiera('profile::kubernetes::deployment_server::services', {}),
    Hash[String, Any] $services_secrets=hiera('profile::kubernetes::deployment_server_secrets::services', {}),
    Hash[String, Any] $admin_services_secrets=hiera('profile::kubernetes::deployment_server_secrets::admin_services', {}),
    Hash[String, Any] $general_values=lookup('profile::kubernetes::deployment_server::general', {'default_value' => {}}),
    Hash[String, Any] $default_secrets=lookup('profile::kubernetes::deployment_server_secrets::defaults', {'default_value' => {}}),
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_all_nodes'),
    Array[Profile::Service_listener] $service_listeners = lookup('profile::services_proxy::envoy::listeners', {'default_value' => []}),
){

    require_package('helmfile')
    require_package('helm-diff')

    # logging script needed for sal on helmfile
    file { '/usr/local/bin/helmfile_log_sal':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/kubernetes/helmfile_log_sal.sh',
    }

    git::clone { 'operations/deployment-charts':
        ensure    => 'present',
        directory => '/srv/deployment-charts',
    }

    systemd::timer::job { 'git_pull_charts':
        ensure          => present,
        description     => 'Pull changes on deployment-charts repo',
        command         => '/bin/bash -c "cd /srv/deployment-charts && /usr/bin/git pull >/dev/null 2>&1"',
        interval        => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:*:00', # every minute
        },
        logging_enabled => false,
        user            => 'root',
    }

    # General directory holding all configurations managed by puppet
    # that are used in helmfiles
    $general_dir = '/etc/helmfile-defaults'
    file { $general_dir:
        ensure => directory
    }

    # directory holding private data for services
    # This is only writable by root, and readable by group wikidev
    $general_private_dir = "${general_dir}/private"
    file { $general_private_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0750'
    }

    $merged_services = deep_merge($services, $services_secrets)

    # New-style private directories are one per service, not per cluster too.
    $merged_services.each |String $svcname, Hash $data| {
        if $svcname != 'admin' {
            file { "${general_private_dir}/${svcname}":
                ensure => directory,
                owner  => $data['owner'],
                group  => $data['group'],
                mode   => '0750',
            }
        }
    }

    # Global data defining the services proxy upstreams
    # Services proxy list of definitions to use by our helm charts.
    # They come from two hiera data structures:
    # - profile::services_proxy::envoy::listeners
    # - service::catalog
    $services_proxy = wmflib::service::fetch()
    $proxies = $service_listeners.map |$listener| {
        $address = $listener['upstream'] ? {
            undef   => "${listener['service']}.discovery.wmnet",
            default => $listener['upstream'],
        }
        $svc = $services_proxy[$listener['service']]
        $upstream_port = $svc['port']
        $encryption = $svc['encryption']
        $retval = {
            $listener['name'] => {
                'keepalive' => $listener['keepalive'],
                'port' => $listener['port'],
                'http_host' => $listener['http_host'],
                'timeout'   => $listener['timeout'],
                'retry_policy' => $listener['retry'],
                'xfp' => $listener['xfp'],
                'upstream' => {
                    'address' => $address,
                    'port' => $upstream_port,
                    'encryption' => $encryption,
                }
            }.filter |$key, $val| { $val =~ NotUndef }
        }
    }.reduce({}) |$mem, $val| { $mem.merge($val) }
    # TODO: remove this
    file { '/etc/helmfile-defaults/service-proxy.yaml':
        ensure  => present,
        content => to_yaml({'services_proxy' => $proxies}),
    }

    $clusters = ['staging', 'eqiad', 'codfw']
    $clusters.each |String $environment| {
        if $environment == 'staging' {
            $dc = 'eqiad'
        }
        else {
            $dc = $environment
        }

        $puppet_ca_data = file($facts['puppet_config']['localcacert'])

        $filtered_prometheus_nodes = $prometheus_nodes.filter |$node| { "${dc}.wmnet" in $node }.map |$node| { ipresolve($node) }

        unless empty($filtered_prometheus_nodes) {
            $deployment_config_opts = {
                'tls' => {
                    'telemetry' => {
                        'prometheus_nodes' => $filtered_prometheus_nodes
                    }
                },
                'puppet_ca_crt' => $puppet_ca_data,
            }
        } else {
            $deployment_config_opts = {
                'puppet_ca_crt' => $puppet_ca_data
            }
        }
        # Merge default and environment specific general values with deployment config and service proxies
        $opts = deep_merge($general_values['default'], $general_values[$environment], $deployment_config_opts, {'services_proxy' => $proxies})
        file { "${general_dir}/general-${environment}.yaml":
            content => to_yaml($opts),
            mode    => '0444'
        }

        # populate .hfenv is a temporary workaround for hemlfile checkout T212130 for context
        $merged_services.map |String $svcname, Hash $data| {
          if $svcname == 'admin' {
              $hfenv="/srv/deployment-charts/helmfile.d/admin/${environment}/.hfenv"
              $hfdir="/srv/deployment-charts/helmfile.d/admin/${environment}"
          }elsif $svcname != 'admin' and size($svcname) > 1 {
              $hfenv="/srv/deployment-charts/helmfile.d/services/${environment}/${svcname}/.hfenv"
              $hfdir="/srv/deployment-charts/helmfile.d/services/${environment}/${svcname}"
          }else {
              fail("unexpected servicename ${svcname}")
          }
          file { $hfdir:
              ensure => directory,
              owner  => $data['owner'],
              group  => $data['group'],
          }
          file { $hfenv:
              ensure  => present,
              owner   => $data['owner'],
              group   => $data['group'],
              mode    => $data['mode'],
              content => "kube_env \"${svcname}\" \"${environment}\"",
              require => File[$hfdir]
          }
        }
        $merged_services.map |String $svcname, Hash $data| {
            unless $svcname == 'admin' {
                $secrets_dir="/srv/deployment-charts/helmfile.d/services/${environment}/${svcname}/private"
                file { $secrets_dir:
                    ensure  => directory,
                    owner   => $data['owner'],
                    group   => $data['group'],
                    require => Git::Clone['operations/deployment-charts'],
                }

                # Add here values provided by puppet, like the IPs of the prometheus nodes.
                file { "${secrets_dir}/general.yaml":
                    ensure  => present,
                    owner   => $data['owner'],
                    group   => $data['group'],
                    mode    => $data['mode'],
                    content => to_yaml($deployment_config_opts)
                }

                $raw_data = deep_merge($default_secrets[$environment], $data[$environment])
                # write private section only if there is any secret defined.
                unless $raw_data.empty {
                    # Substitute the value of any key in the form <somekey>: secret__<somevalue>
                    # with <somekey>: secret(<somevalue>)
                    # This allows to avoid having to copy/paste certs inside of yaml files directly,
                    # for example.
                    $secret_data = wmflib::inject_secret($raw_data)

                    file {
                        default:
                            owner   => $data['owner'],
                            group   => $data['group'],
                            mode    => $data['mode'],
                            content => ordered_yaml($secret_data),
                            ;
                        "${secrets_dir}/secrets.yaml": # Legacy secrets position
                            require => [ Git::Clone['operations/deployment-charts'], File[$secrets_dir], ]
                            ;
                        "${general_private_dir}/${svcname}/${environment}.yaml": # new secrets position
                            require => "File[${general_private_dir}/${svcname}]"
                            ;
                    }
                }
            }
        }
        $admin_services_secrets.map |String $svcname, Hash $data| {
          if $data[$environment] {
            $secrets_dir="/srv/deployment-charts/helmfile.d/admin/${environment}/${svcname}"
            file { $secrets_dir:
                ensure  => directory,
                owner   => $data['owner'],
                group   => $data['group'],
                require => Git::Clone['operations/deployment-charts'],
            }
            file { "${secrets_dir}/private":
                ensure  => directory,
                owner   => $data['owner'],
                group   => $data['group'],
                require => Git::Clone['operations/deployment-charts'],
            }
            file { "${secrets_dir}/private/secrets.yaml":
                owner   => $data['owner'],
                group   => $data['group'],
                mode    => $data['mode'],
                content => ordered_yaml($data[$environment]),
                require => [ Git::Clone['operations/deployment-charts'], File[$secrets_dir], File["${secrets_dir}/private"] ]
            }
          }
        }
    } # end clusters

}
