# == Class mailman3::listserve
#
# This class provisions all the resources necessary to
# run the core Mailman service.
#
# https://docs.mailman3.org/projects/mailman/en/latest/README.html
#
class mailman3::listserve (
    Stdlib::Fqdn $db_host,
    String $db_name,
    String $db_user,
    String $db_password,
    String $api_password,
    String $service_ensure = 'running',
) {

    ensure_packages([
        'python3-pymysql',
    ])

    package { 'mailman3':
        ensure  => present,
        require => Package['dbconfig-no-thanks'],
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
}
