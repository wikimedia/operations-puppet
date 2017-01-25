define profile::etcd::htpasswd_file ($acls, $users, $salt) {
    $file_location = regsubst($title, '/', '_', 'G')
    $file_name = "/etc/nginx/auth/${file_location}.htpasswd"

    file { $file_name:
        content => template('profile/etcd/htpasswd.erb'),
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0444',
    }
}
