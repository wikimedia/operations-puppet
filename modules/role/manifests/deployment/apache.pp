class role::deployment::apache(
    $apache_fqdn = $::fqdn,
) {
    apache::site { 'deployment':
        content => template('role/deployment/apache-vhost.erb'),
        require => File['/srv/deployment'],
    }
}