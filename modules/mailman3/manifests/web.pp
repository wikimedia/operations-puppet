# == Class mailman3::web
#
# Installs the Django web app serving mailman3 to users
# https://mailman-web.readthedocs.io/en/latest/index.html
#
# The mailman-web package wraps various web components:
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
        # https://hyperkitty.readthedocs.io/en/latest/install.html#install-the-code
        'sassc',
        'python3-xapian-haystack',
    ])

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

    file { '/usr/local/bin/mailman-web':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/mailman3/mailman-web',
    }

    service { 'mailman3-web':
        ensure    => $service_ensure,
        hasstatus => false,
        pattern   => 'mailmanctl',
        subscribe => File['/etc/mailman3/mailman-web.py'],
    }
}
