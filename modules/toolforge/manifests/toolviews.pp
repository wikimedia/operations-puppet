# SPDX-License-Identifier: Apache-2.0
# Process dynamicproxy access logs to compute usage data for Toolforge tools.
class toolforge::toolviews (
    Boolean $enabled,
    Stdlib::Host $mysql_host,
    String $mysql_db,
    String $mysql_user,
    String $mysql_password,
) {
    ensure_packages([
        'python3-ldap3',
        'python3-pymysql',
        'python3-yaml',
    ])

    file { '/etc/toolviews.yaml':
        ensure  => file,
        content => template('toolforge/toolviews.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
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

    # See the custom nginx logrotate config in ::dynamicproxy for how this is
    # triggered.
    file { '/etc/logrotate.d/nginx-postrotate':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/etc/logrotate.d/nginx-postrotate/toolviews':
        ensure  => $enabled.bool2str('file', 'absent'),
        source  => 'puppet:///modules/toolforge/toolviews.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        require => File['/usr/local/bin/toolviews.py'],
    }
}
