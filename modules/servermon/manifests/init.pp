class servermon(
    $ensure='present',
    $directory
) {

    package { [
        'python-django',
        'python-django-south',
        'python-whoosh',
        'python-ldap',
        'python-ipy',
        'gunicorn',
    ]:
        ensure => $ensure,
    }

    $service_ensure = $ensure ? {
        present => 'running',
        absent  => 'stopped',
        default => 'running',
    }

    service { 'gunicorn':
        ensure => $service_ensure,
    }

    file { '/etc/gunicorn.d/servermon':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('servermon/gunicorn.erb'),
    }
}
