# == Class role::analytics::oozie::client
#
class role::analytics::oozie::client {
    # Need hadoop client before oozie client.
    Class['role::analytics::hadoop::client'] -> Class['role::analytics::oozie::client']

    $oozie_host = $::realm ? {
        'production' => 'analytics1027.eqiad.wmnet',
        'labs'       => $role::analytics::hadoop::labs::namenode_hosts[0],
    }

    class { 'cdh4::oozie':
        oozie_host => $oozie_host,
    }
}

class role::analytics::oozie::server inherits role::analytics::oozie::client {
    if (!defined(Package['mysql-server'])) {
        package { 'mysql-server':
            ensure => 'installed',
        }
    }
    # make sure mysql-server is installed before
    # we apply our MySQL Oozie database class.
    Package['mysql-server'] -> Class['::cdh4::oozie::database::mysql']

    $jdbc_password = $::realm ? {
        'production' => $passwords::analytics::oozie_jdbc_password,
        'labs'       => 'oozie',
    }

    class { 'cdh4::oozie::server':
        jdbc_password   => $jdbc_password,
        # TODO:  infer smtp_host from some other puppet manifest.
        smtp_host       => 'mchenry.wikimedia.org',
        smtp_from_email => "oozie@$::fqdn",
    }
}
