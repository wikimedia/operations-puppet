# SPDX-License-Identifier: Apache-2.0
# Process access logs to compute usage data for Toolforge tools.
class toolforge::toolviews (
    Stdlib::Host $mysql_host,
    String[1]    $mysql_db,
    String[1]    $mysql_user,
    String[1]    $mysql_password,
    String[1]    $hash_salt,
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
