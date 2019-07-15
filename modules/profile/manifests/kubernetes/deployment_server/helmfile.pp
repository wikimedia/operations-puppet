class profile::kubernetes::deployment_server::helmfile(
    Hash[String, Any] $services=hiera('profile::kubernetes::deployment_server::services', {}),
    Hash[String, Any] $services_secrets=hiera('profile::kubernetes::deployment_server_secrets::services', {}),
    Hash[String, Any] $admin_services_secrets=hiera('profile::kubernetes::deployment_server_secrets::admin_services', {}),
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
        ensure                    => present,
        description               => 'Pull changes on deployment-charts repo',
        command                   => '/bin/bash -c "cd /srv/deployment-charts && /usr/bin/git pull >/dev/null 2>&1"',
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:*:00', # every minute
        },
        logging_enabled           => false,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'admins',
        user                      => 'root',
    }

    $merged_services = deep_merge($services, $services_secrets)
    $clusters = ['staging', 'eqiad', 'codfw']
    $clusters.each |String $environment| {
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
            content => template('profile/kubernetes/.hfenv.erb'),
            require => File[$hfdir]
          }
        }
        $merged_services.map |String $svcname, Hash $data| {
          # write private section only if there is any secret defined.
          if $data[$environment] {
            $secrets_dir="/srv/deployment-charts/helmfile.d/services/${environment}/${svcname}/private"
            file { $secrets_dir:
                ensure  => directory,
                owner   => $data['owner'],
                group   => $data['group'],
                require => Git::Clone['operations/deployment-charts'],
            }
            file { "${secrets_dir}/secrets.yaml":
                owner   => $data['owner'],
                group   => $data['group'],
                mode    => $data['mode'],
                content => ordered_yaml($data[$environment]),
                require => [ Git::Clone['operations/deployment-charts'], File[$secrets_dir], ]
            }
          }
        }
        $admin_services_secrets.map |String $svcname, Hash $data| {
          if $data[$environment] {
            $secrets_dir="/srv/deployment-charts/helmfile.d/admin/${environment}/${svcname}/private"
                file { $secrets_dir:
                ensure  => directory,
                owner   => $data['owner'],
                group   => $data['group'],
                require => Git::Clone['operations/deployment-charts'],
            }
            file { "${secrets_dir}/secrets.yaml":
                owner   => $data['owner'],
                group   => $data['group'],
                mode    => $data['mode'],
                content => ordered_yaml($data[$environment]),
                require => [ Git::Clone['operations/deployment-charts'], File[$secrets_dir], ]
            }
          }
        }
    } # end clusters

}
