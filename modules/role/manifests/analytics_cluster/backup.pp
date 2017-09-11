# == Class role::analytics_cluster::backup
# Simple wrapper class to create and manage /srv/backup
class role::analytics_cluster::backup {
    file { '/srv/backup':
        ensure => 'directory',
        owner  => 'root',
        group  => 'analytics-admins',
        mode   => '0750',
    }
}
