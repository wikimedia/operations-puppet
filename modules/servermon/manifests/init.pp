class servermon(
    $directory,
    $secret_key,
    $db_name,
    $db_engine='sqlite3',
    $db_user='',
    $db_password='',
    $db_host='',
    $db_port='',
    $port=8090,
    $admins=undef,
    $ensure='present',
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

    file { "$directory/settings.py":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('servermon/settings.py.erb'),
    }

    file { "$directory/urls.py":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/servermon/urls.py',
    }

    file { '/etc/gunicorn.d/servermon':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('servermon/gunicorn.erb'),
        require => Package['gunicorn'],
    }
}
