function admin::kerberos_users(Hash $data) >> Array[String] {
  $data['users'].filter |$user, $config| {
    $config['ensure'] == 'present' and $config['krb'] == 'present' and !pick($config['system'], false)
    }.keys.flatten
}
