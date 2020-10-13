class profile::docker::registry::swift (
    Hash $config = lookup('profile::docker::registry::config', {default_value => {}}),
    Hash[String, Hash] $swift_accounts = lookup('profile::swift::accounts'),
    Stdlib::Httpsurl $swift_auth_url = lookup('profile::docker::registry::swift_auth_url'),
    # By default, the password will be extracted from swift, but can be overridden
    Hash[String, String] $swift_account_keys = lookup('profile::swift::accounts_keys'),
    String $swift_container = lookup('profile::docker::registry::swift_container', {default_value => 'docker_registry'}),
    Optional[String] $swift_password = lookup('profile::docker::registry::swift_password', {default_value => undef}),
) {
    $swift_account = $swift_accounts['docker_registry']
    if !$swift_password {
        $password = $swift_account_keys['docker_registry']
    }
    else {
        $password = $swift_password
    }
    class { '::docker::registry':
        config          => $config,
        storage_backend => 'swift',
        swift_user      => $swift_account['user'],
        swift_password  => $password,
        swift_url       => 'http://swift.svc.codfw.wmnet/auth/v1.0',
        swift_container => $swift_container,
    }

}
