# Class to help building our own version of kubernetes
class toollabs::kubebuilder(
    $tag='v1.2.0wmf1',
) {
    require ::docker::engine

    file { '/srv/build':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    git::clone { 'operations/software/kubernetes':
        ensure    => latest,
        branch    => $tag,
        directory => '/srv/build/kubernetes',
        require   => File['/srv/build'],
    }

    file { '/usr/local/bin/build-kubernetes':
        content => template('toollabs/build-kubernetes.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
    }
}
