# == Class mailman3::web
#
# Installs the Django web app serving mailman3 to users
# https://mailman-web.readthedocs.io/en/latest/index.html
#
# The mailman3-web package wraps various web components:
# * django-mailman: User profile management
# * postorius: List administration
# * hyperkitty: List archives
class mailman3::web (
    Stdlib::Fqdn $host,
    Stdlib::Fqdn $db_host,
    String $db_name,
    String $db_user,
    String $db_password,
    String $api_password,
    String $secret,
    String $archiver_key,
    String $service_ensure = 'running',
) {

    ensure_packages([
        'python3-mysqldb',
        'python3-xapian-haystack',
    ])

    apt::package_from_component { 'mailman3-web':
        component => 'component/mailman3',
        packages  => [
            'mailman3-web',
            'python3-django-mailman3',
            'python3-django-hyperkitty',
            'python3-django-postorius',
            'python3-flufl.lock',
            'python3-mailmanclient',
        ],
        require   => Package['dbconfig-no-thanks'],
    }

    package { 'mailman3-web':
        ensure  => present,
        require => Package['dbconfig-no-thanks'],
    }

    file { '/etc/mailman3/mailman-web.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mailman3/mailman-web.py.erb'),
    }

    file { '/etc/mailman3/mailman-hyperkitty.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mailman3/mailman-hyperkitty.cfg.erb'),
    }

    service { 'mailman3-web':
        ensure    => $service_ensure,
        hasstatus => false,
        pattern   => 'mailmanctl',
        subscribe => File['/etc/mailman3/mailman-web.py'],
    }

    file { '/var/lib/mailman3/redirects/':
        ensure => directory,
        owner  => 'root',
        group  => 'list',
        mode   => '0555',
    }

    # Create an empty dbm file so Apache doesn't complain
    exec { '/usr/sbin/httxt2dbm -i /dev/null -o /var/lib/mailman3/redirects/redirects.dbm':
        user    => 'root',
        creates => '/var/lib/mailman3/redirects/redirects.dbm',
        require => File['/var/lib/mailman3/redirects/'],
    }
}
