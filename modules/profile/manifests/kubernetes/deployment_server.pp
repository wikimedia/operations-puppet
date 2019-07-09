# Class makes sure we got a deployment server ready
class profile::kubernetes::deployment_server(
    Hash[String, Any] $services=hiera('profile::kubernetes::deployment_server::services', {}),
    Hash[String, Any] $services_secrets=hiera('profile::kubernetes::deployment_server_secrets::services', {}),
    Hash[String, Any] $tokens=hiera('profile::kubernetes::deployment_server::tokens', {}),
    String $git_owner=hiera('profile::kubernetes::deployment_server::git_owner'),
    String $git_group=hiera('profile::kubernetes::deployment_server::git_group'),
){
    class { '::helm': }

    # The deployment script
    # TODO: remove this when helmfile is used in production
    file { '/usr/local/bin/scap-helm':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/kubernetes/scap-helm.sh',
    }

    require_package('helmfile')
    require_package('helm-diff')

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
        $merged_services.map |String $svcname, Hash $data| {
          # This is a temporary workaround for hemlfile checkout T212130 for context
          if $svcname != 'admin' and size($svcname) > 1 {
              $hfenv="/srv/deployment-charts/helmfile.d/services/${environment}/${svcname}/.hfenv"
              $hfdir="/srv/deployment-charts/helmfile.d/services/${environment}/${svcname}"
          }elsif $svcname == 'admin' {
              $hfenv="/srv/deployment-charts/helmfile.d/admin/${environment}/.hfenv"
              $hfdir="/srv/deployment-charts/helmfile.d/admin/${environment}"
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
          # write private section only if there is any secret defined.
          if $data[$environment] {
            file { "/srv/deployment-charts/helmfile.d/services/${environment}/${svcname}/private":
                ensure  => directory,
                owner   => $data['owner'],
                group   => $data['group'],
                require => Git::Clone['operations/deployment-charts'],
            }
            file { "/srv/deployment-charts/helmfile.d/services/${environment}/${svcname}/private/secrets.yaml":
                owner   => $data['owner'],
                group   => $data['group'],
                mode    => $data['mode'],
                content => ordered_yaml($data[$environment]),
                require => [ Git::Clone['operations/deployment-charts'], File["/srv/deployment-charts/helmfile.d/services/${environment}/${svcname}/private"], ]
            }
          }
        }
    }

    # logging script needed for sal on helmfile
    file { '/usr/local/bin/helmfile_log_sal':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/kubernetes/helmfile_log_sal.sh',
    }


    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    $envs = {
        'eqiad' => 'kubemaster.svc.eqiad.wmnet',
        'codfw' => 'kubemaster.svc.codfw.wmnet',
        'staging' => 'neon.eqiad.wmnet',
    }

    $real_services = deep_merge($services, $tokens)

    # Now populate the /etc/kubernetes/ kubeconfig resources
    $envs.each |String $env, String $master_host| {
        $real_services.each |String $service, Hash $data| {
            # lint:ignore:variable_scope
            k8s::kubeconfig { "/etc/kubernetes/${service}-${env}.config":
                master_host => $master_host,
                username    => $data['username'],
                token       => $data['token'],
                group       => $data['group'],
                mode        => $data['mode'],
                namespace   => $data['namespace'],
            }
            # lint:endignore
        }
    }
}
