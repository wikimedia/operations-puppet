# Class makes sure we got a deployment server ready
class profile::kubernetes::deployment_server(
    $services=hiera('profile::kubernetes::deployment_server::services', {}),
    $tokens=hiera('profile::kubernetes::deployment_server::tokens', {}),
    $git_owner=hiera('profile::kubernetes::deployment_server::git_owner'),
    $git_group=hiera('profile::kubernetes::deployment_server::git_group'),
){
    class { '::helm': }

    # The deployment script
    file { '/usr/local/bin/scap-helm':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/kubernetes/scap-helm.sh',
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
