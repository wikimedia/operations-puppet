class profile::mailman3 (
    String $db_host      = lookup('profile::mailman3::db_host'),
    String $db_password  = lookup('profile::mailman3::db_password'),
    String $api_password = lookup('profile::mailman3::api_password'),
) {
    class { '::mailman3':
        db_host      => $db_host,
        db_password  => $db_password,
        api_password => $api_password
    }
}
