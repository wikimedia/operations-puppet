class profile::toolforge::k8s::client (
) {
    class { '::profile::wmcs::kubeadm::client': }
    contain '::profile::wmcs::kubeadm::client'

    package { 'toolforge-webservice':
        ensure => latest,
    }

    $extra_links = ['/usr/local/bin/toolforge-webservice']

    # Legacy locations for the entry point script from webservice
    # that are probably still hardcoded in some Tools.
    $legacy_links = debian::codename::le('buster') ? {
        true =>  [
            '/usr/local/bin/webservice2',
            '/usr/local/bin/webservice',
        ],
        false => [],
    }

    file { $extra_links + $legacy_links:
        ensure => link,
        target => '/usr/bin/webservice',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
