class profile::docker::registry::swift (
    $config = hiera('profile::docker::registry::config', {}),
    $swift_accounts = hiera('swift::params::accounts'),
    $swift_auth_url = hiera('profile::docker::registry::swift_auth_url'),
    # By default, the password will be extracted from swift, but can be overridden
    $swift_account_keys = hiera('swift::params::account_keys'),
    $swift_container = hiera('profile::docker::registry::swift_container', 'docker_registry'),
    $swift_password = hiera('profile::docker::registry::swift_password', undef),
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
