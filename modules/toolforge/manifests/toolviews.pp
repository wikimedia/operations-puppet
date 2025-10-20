# SPDX-License-Identifier: Apache-2.0
# Process access logs to compute usage data for Toolforge tools.
class toolforge::toolviews (
    Stdlib::Host $mysql_host,
    String $mysql_db,
    String $mysql_user,
    String $mysql_password,
    String $hash_salt,
) {
    ensure_packages([
        'python3-ldap3',
        'python3-pymysql',
        'python3-yaml',
    ])

    file { '/etc/toolviews.yaml':
        ensure    => file,
        content   => template('toolforge/toolviews.yaml.erb'),
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        show_diff => false,
    }

    file { '/usr/local/bin/toolviews.py':
        ensure  => file,
        source  => 'puppet:///modules/toolforge/toolviews.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        require => Package[
            'python3-ldap3',
            'python3-pymysql',
            'python3-yaml',
        ],
    }
}
