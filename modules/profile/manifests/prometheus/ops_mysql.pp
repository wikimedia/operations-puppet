# SPDX-License-Identifier: Apache-2.0
# Uses addendum to prometheus::ops to add the mysql specific configuration
class profile::prometheus::ops_mysql (
    $targets_path = lookup('prometheus::server::target_path', String, 'first', '/srv/prometheus/ops/targets'),
    $mysql_host = lookup('prometheus::server::mysqld_exporter::mysql::host', String, 'first', 'UNDEFINED'),
    $mysql_port = lookup('prometheus::server::mysqld_exporter::mysql::port', Integer, 'first', 3306),
    $mysql_database = lookup('prometheus::server::mysqld_exporter::mysql::database', String, 'first', ''),
    $mysql_user = lookup('prometheus::server::mysqld_exporter::mysql::user', String, 'first', ''),
    $mysql_password = lookup('prometheus::server::mysqld_exporter::mysql::password', String, 'first', ''),
) {
    # Generate configuration files for mysql jobs by querying zarcillo
    # Do not apply it on pops (role != prometheus), as they are outdated and do not hold
    # any production database
    if $mysql_host != 'UNDEFINED' {
        ensure_packages ([
            'python3-pymysql',
            'python3-yaml',
        ])
        file { '/etc/prometheus/zarcillo.cnf':
            content   => template('profile/prometheus/zarcillo.cnf.erb'),
            mode      => '0400',
            show_diff => false,
        }
        file { '/usr/local/sbin/mysqld_exporter_config.py':
            source => 'puppet:///modules/profile/prometheus/mysqld_exporter_config.py',
            mode   => '0555',
        }
        systemd::timer::job{'generate-mysqld-exporter-config':
            ensure      => 'present',
            description => 'generates prometheus-mysqld-exporter targets from zarcillo',
            user        => 'root',
            command     => "/usr/local/sbin/mysqld_exporter_config.py ${::site} '${targets_path}'",
            interval    => {
                'start'    => 'OnCalendar',
                'interval' => '*-*-* *:00/30:00', # every 30 min
            },
            require     => [
                File['/etc/prometheus/zarcillo.cnf', '/usr/local/sbin/mysqld_exporter_config.py'],
                Package['python3-pymysql', 'python3-yaml'],
            ],
        }
    }

}
