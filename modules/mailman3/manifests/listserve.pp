# == Class mailman3::listserve
#
# This class provisions all the resources necessary to
# run the core Mailman service.
#
# https://docs.mailman3.org/projects/mailman/en/latest/README.html
#
class mailman3::listserve (
    String $db_host,
    String $db_name,
    String $db_user,
    String $db_password,
    String $api_password,
    String $service_ensure = 'running',
) {

    ensure_packages([
        'python3-pymysql',
        'dbconfig-mysql',
    ])

    package { 'mailman3':
        ensure => present,
    }

    file { '/etc/mailman3/mailman.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mailman3/mailman.cfg.erb'),
    }

    service { 'mailman3':
        ensure    => $service_ensure,
        hasstatus => false,
        pattern   => 'mailmanctl',
        subscribe => File['/etc/mailman3/mailman.cfg'],
    }
}
