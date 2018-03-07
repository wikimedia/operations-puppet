# Class makes sure we got a deployment server ready
class profile::kubernetes::deployment_server(
    $admin_token='TODO',
    $mathoid_token='TODO',
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

    # mathoid specifics
    # TODO: Do this better
    file { '/usr/local/bin/scap-helm':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('profile/kubernetes/scap-helm.erb'),
    }
}
