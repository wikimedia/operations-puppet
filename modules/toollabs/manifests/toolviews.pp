# == Class: toollabs::toolviews
# Process dynamicproxy access logs to compute usage data for Toolforge tools.
class toollabs::toolviews (
    $mysql_host,
    $mysql_db,
    $mysql_user,
    $mysql_password,
) {
    require_package(
        'python3-ldap3',
        'python3-pymysql',
        'python3-yaml',
    )

    file { '/etc/toolviews.yaml':
        ensure  => file,
        content => template('toollabs/toolviews.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
    }

    file { '/usr/local/bin/toolviews.py':
        ensure  => file,
        source  => 'puppet:///modules/toollabs/toolviews.py',
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
        ensure  => file,
        source  => 'puppet:///modules/toollabs/toolviews.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        require => File['/usr/local/bin/toolviews.py'],
    }
}
