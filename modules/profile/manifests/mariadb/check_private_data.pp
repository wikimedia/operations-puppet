# Deploy script and dependencies needed to check no private data
# persists on the database
class profile::mariadb::check_private_data {

    file { '/etc/mysql/private_tables.txt':
        ensure  => file,
        content => template('role/mariadb/private_tables.txt.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file { '/etc/mysql/filtered_tables.txt':
        ensure => file,
        source => 'puppet:///modules/role/mariadb/filtered_tables.txt',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/usr/local/sbin/check_private_data.py':
        ensure  => file,
        source  => 'puppet:///modules/role/mariadb/check_private_data.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        require => [Package['python3-yaml', 'python3-pymysql'],
                    Git::Clone['operations/mediawiki-config'],
                    File['/etc/mysql/filtered_tables.txt'],
                    File['/etc/mysql/private_tables.txt'],
        ],
    }

    file { '/usr/local/sbin/check_private_data_report':
        ensure => file,
        source => 'puppet:///modules/role/mariadb/check_private_data_report',
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
    }

    systemd::timer::job { 'check-private-data':
        ensure             => present,
        description        => 'Regular jobs for checking and reporting private data',
        user               => 'root',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => '/usr/local/sbin/check_private_data_report',
        interval           => {'start' => 'OnCalendar', 'interval' => 'Mon *-*-* 05:00:00'},
        require            => [
            File['/usr/local/sbin/check_private_data_report'],
            File['/usr/local/sbin/check_private_data.py'],
        ],
    }

    file { '/usr/local/sbin/redact_sanitarium.sh':
        ensure  => file,
        source  => 'puppet:///modules/role/mariadb/redact_sanitarium.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        require => File['/etc/mysql/filtered_tables.txt'],
    }

}
