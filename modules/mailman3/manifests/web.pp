# SPDX-License-Identifier: Apache-2.0
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
    Integer $uwsgi_processes,
    Stdlib::Ensure::Service $service_ensure = 'running',
    Optional[String] $memcached,
    Stdlib::Unixpath $mailman_root = '/var/lib/mailman3',
) {

    ensure_packages([
        'python3-mysqldb',
        'python3-pymemcache',
        'python3-xapian-haystack',
        'apache2-utils',  # Need httxt2dbm
    ])

    $mailman3_web_debs = [
        'mailman3-web',
        'python3-django-mailman3',
        'python3-django-hyperkitty',
        'python3-django-postorius',
        'python3-flufl.lock',
        'python3-mailmanclient',
    ]

    # Use stock mailman3 in bookworm and newer
    if debian::codename::ge('bookworm') {
        ensure_packages($mailman3_web_debs)
    } else {
        apt::package_from_component { 'mailman3-web':
            component => 'component/mailman3',
            packages  => $mailman3_web_debs,
        }
    }
    Package['dbconfig-no-thanks'] ~> Package['mailman3-web']

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

    file { '/etc/mailman3/uwsgi.ini':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => epp(
            'mailman3/uwsgi.ini.epp',
            { processes => $uwsgi_processes },
        ),
    }

    service { 'mailman3-web':
        ensure    => $service_ensure,
        hasstatus => false,
        pattern   => 'mailmanctl',
        subscribe => [
            File['/etc/mailman3/mailman-web.py'],
            File['/etc/mailman3/uwsgi.ini'],
        ]
    }

    file { '/etc/logrotate.d/mailman3-web':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/mailman3/web-logrotate.conf',
        require => Package['mailman3-web'],
    }

    file { "${mailman_root}/redirects/":
        ensure => directory,
        owner  => 'root',
        group  => 'list',
        mode   => '0555',
    }

    file { '/usr/local/sbin/pipermail_redirects':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman3/scripts/pipermail_redirects.py',
    }

    # Create an empty dbm file so Apache doesn't complain
    exec { "/usr/sbin/httxt2dbm -i /dev/null -o ${$mailman_root}/redirects/redirects.dbm":
        user    => 'root',
        creates => "${$mailman_root}/redirects/redirects.dbm",
        require => File["${$mailman_root}/redirects/"],
    }

    ferm::service { 'mailman-http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'mailman-https':
        proto => 'tcp',
        port  => '443',
    }
}
