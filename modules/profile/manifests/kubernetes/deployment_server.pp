# Class makes sure we got a deployment server ready
class profile::kubernetes::deployment_server(
    $configs=hiera('profile::kubernetes::deployment_server::configs', {}),
){
    package { 'helm':
        ensure => installed,
    }
    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    create_resources(k8s::kubeconfig, $configs)

    # The deployment script
    file { '/usr/local/bin/scap-helm':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/kubernetes/scap-helm.sh',
    }
}
