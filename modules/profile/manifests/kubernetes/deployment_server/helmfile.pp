# Installs helmfile and helmfile-diff, plus
# all the puppet-provided defaults and secrets for each service.
#
class profile::kubernetes::deployment_server::helmfile(
    Hash[String, String] $clusters = lookup('kubernetes_clusters'),
    Hash[String, Any] $services=lookup('profile::kubernetes::deployment_server::services', {'default_value' => {}}),
    Hash[String, Any] $services_secrets=lookup('profile::kubernetes::deployment_server_secrets::services', {'default_value' => {}}),
    Hash[String, Any] $default_secrets=lookup('profile::kubernetes::deployment_server_secrets::defaults', {'default_value' => {}}),

){
    require ::profile::kubernetes::deployment_server::global_config
    ensure_packages(['helmfile', 'helm-diff'])

    $general_private_dir = "${::profile::kubernetes::deployment_server::global_config::general_dir}/private"
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

    $clusters.each |String $environment, String $dc| {
        $merged_services.map |String $svcname, Hash $data| {
            $raw_data = deep_merge($default_secrets[$environment], $data[$environment])
            # write private section only if there is any secret defined.
            unless $raw_data.empty {
                # Substitute the value of any key in the form <somekey>: secret__<somevalue>
                # with <somekey>: secret(<somevalue>)
                # This allows to avoid having to copy/paste certs inside of yaml files directly,
                # for example.
                $secret_data = wmflib::inject_secret($raw_data)

                file { "${general_private_dir}/${svcname}/${environment}.yaml":
                    owner   => $data['owner'],
                    group   => $data['group'],
                    mode    => $data['mode'],
                    content => ordered_yaml($secret_data),
                    require => "File[${general_private_dir}/${svcname}]"
                }
            }
        }
    } # end clusters
}
