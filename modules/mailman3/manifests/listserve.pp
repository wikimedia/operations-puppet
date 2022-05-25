# SPDX-License-Identifier: Apache-2.0
# == Class mailman3::listserve
#
# This class provisions all the resources necessary to
# run the core Mailman service.
#
# https://docs.mailman3.org/projects/mailman/en/latest/README.html
#
class mailman3::listserve (
    Stdlib::Fqdn $host,
    Stdlib::Fqdn $db_host,
    String $db_name,
    String $db_user,
    String $db_password,
    String $api_password,
    String $service_ensure = 'running',
) {

    ensure_packages([
        'python3-pymysql',
        'python3-mailman-hyperkitty',
    ])

    apt::package_from_component { 'mailman3':
        component => 'component/mailman3',
        packages  => [
            'mailman3',
            'python3-authheaders',
            'python3-falcon',
            'python3-flufl.bounce',
            'python3-flufl.lock',
            'python3-importlib-resources',
            'python3-zope.interface',
        ],
        require   => Package['dbconfig-no-thanks'],
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

    file { '/etc/logrotate.d/mailman3':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/mailman3/logrotate.conf',
        require => Package['mailman3'],
    }

    # Helper scripts
    file { '/usr/local/sbin/remove_from_lists':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman3/scripts/remove_from_lists.py',
    }

    file { '/usr/local/sbin/discard_held_messages':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman3/scripts/discard_held_messages.py',
    }

    systemd::timer::job { 'discard_held_messages':
        ensure      => 'present',
        user        => 'root',
        description => 'discard un-moderated held messages after 90 days (T109838)',
        command     => '/usr/local/sbin/discard_held_messages 90',
        interval    => {'start' => 'OnCalendar', 'interval' => 'daily'},
    }

    file { '/usr/local/sbin/migrate_to_mailman3':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman3/scripts/migrate_to_mailman3.py',
    }

    file { '/var/lib/mailman3/templates/domains/':
        ensure => directory,
        owner  => 'root',
        group  => 'list',
        mode   => '0555',
    }

    file { "/var/lib/mailman3/templates/domains/${host}/":
        ensure  => directory,
        owner   => 'root',
        group   => 'list',
        mode    => '0555',
        require => File['/var/lib/mailman3/templates/domains/'],
    }

    file { "/var/lib/mailman3/templates/domains/${host}/en/":
        ensure  => directory,
        source  => 'puppet:///modules/mailman3/templates/',
        owner   => 'root',
        group   => 'list',
        mode    => '0555',
        recurse => 'remote',
        require => File["/var/lib/mailman3/templates/domains/${host}/"],
    }
}
