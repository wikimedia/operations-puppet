# toolforge specific config for our kubeadm-based k8s deployment
class toolforge::k8s::config (
    Optional[String]    $encryption_key = undef,
) {
    # make sure you declare ::kueadm::core somewhere in the calling profile
    # because /etc/kubernetes

    file { '/etc/kubernetes/toolforge-tool-roles.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/toolforge-tool-roles.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/admission':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/admission/admission.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/admission.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/etc/kubernetes/admission'],
    }

    file { '/etc/kubernetes/admission/eventconfig.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/eventconfig.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/etc/kubernetes/admission'],
    }

    # This should never be set in the public repo for hiera. Keep it in a
    # private repo on a standalone puppetmaster since it is a simple shared key.
    if $encryption_key {
        file { '/etc/kubernetes/admission/encryption-conf.yaml':
            ensure    => present,
            content   => template('toolforge/k8s/encryption-conf.yaml.erb'),
            owner     => 'root',
            group     => 'root',
            mode      => '0400',
            require   => File['/etc/kubernetes/admission'],
            show_diff => false,
        }
    }
}
