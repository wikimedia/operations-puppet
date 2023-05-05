class profile::toolforge::k8s::client (
    Stdlib::Fqdn $buildservice_repository = lookup('profile::toolforge::k8s::client::buildservice_repository'),
) {
    class { '::profile::wmcs::kubeadm::client': }
    contain '::profile::wmcs::kubeadm::client'

    package { 'toolforge-webservice':
        ensure => latest,
    }

    # Legacy locations for the entry point script from webservice
    # that are probably still hardcoded in some Tools.
    if debian::codename::le('buster') {
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

    file { '/usr/local/bin/toolforge-webservice':
        ensure => absent,
    }

    file { '/etc/toolforge':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/etc/toolforge/webservice.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => {'buildservice_repository' => $buildservice_repository}.to_yaml,
    }
}
