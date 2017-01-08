# Class to help building our own version of kubernetes

class toollabs::kubebuilder(
    $tag='v1.3.3wmf1',
) {
    require ::docker::engine

    # Simple file server for simple file serving!
    # FIXME: Replace with whatever file server scap3 ends up using
    require_package('nginx')
    $output_base_path = '/var/www/html'

    file { '/srv/build':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/srv/www':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0555',
    }

    file { '/usr/local/bin/build-kubernetes':
        content => template('toollabs/build-kubernetes.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
    }

    file { '/usr/local/bin/check-pause-container':
        source => 'puppet:///modules/toollabs/check-pause-container',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }

    git::clone { 'operations/software/kubernetes':
        ensure    => present,
        directory => '/srv/build/kubernetes',
        require   => File['/srv/build'],
    }
}
