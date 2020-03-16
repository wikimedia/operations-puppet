class profile::toolforge::k8s::client(
){
    class {'::toolforge::k8s::kubeadmrepo': }

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
