# Class makes sure we got a deployment server ready
class profile::kubernetes::deployment_server(
    $services=hiera('profile::kubernetes::deployment_server::services', {}),
){
    package { 'helm':
        ensure => installed,
    }

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

    # Now populate the /etc/kubernetes/ kubeconfig resources
    $envs.each |String $env, String $master_host| {
        $services.each |String $service, Hash $data| {
            # lint:ignore:variable_scope
            k8s::kubeconfig { "/etc/kubernetes/${service}-${env}.config":
                master_host => $master_host,
                username    => $data['username'],
                token       => $data['token'],
                group       => $data['group'],
                mode        => $data['mode'],
            }
            # lint:endignore
        }
    }

}
