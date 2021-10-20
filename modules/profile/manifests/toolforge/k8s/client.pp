class profile::toolforge::k8s::client (
) {
    class { '::profile::wmcs::kubeadm::client': }
    contain '::profile::wmcs::kubeadm::client'

    package { 'toolforge-webservice':
        ensure => latest,
    }

    if debian::codename::le('buster') {
        # Legacy locations for the entry point script from webservice
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
}
