class profile::toolforge::k8s::client(
    $master_host = hiera('k8s::master_host'),
    $etcd_hosts = hiera('flannel::etcd_hosts', [$master_host]),
){
    class {'::toolforge::k8s::kubeadmrepo': }

    package {'kubernetes-client':
        ensure => absent,
    }

    package { 'kubectl':
        ensure => 'latest',
    }

    package { 'toollabs-webservice':
        ensure => latest,
    }

    # Legacy locations for the entry point script from toollabs-webservice
    # that are probably still hardcoded in some Tools.
    file { [
        '/usr/local/bin/webservice2',
        '/usr/local/bin/webservice',
    ]:
        ensure => link,
        target => '/usr/bin/webservice',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
