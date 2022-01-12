function admin::kerberos_users() >> Hash {
    include admin
    $admin::data['users'].filter |$user, $config| {
        $config['ensure'] == 'present' and $config['krb'] == 'present' and !pick($config['system'], false)
    }
}
