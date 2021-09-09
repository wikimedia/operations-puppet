# @summary class to install a script for validating user email addresses
# @param super_admin the support admin account to impersonate
# @param service_file_source the location in the secret module of the service account json file
# @param proxy_server the proxy server to use
class profile::sre::check_user (
    String          $super_admin         = lookup('profile::sre::check_user::super_admin'),
    String          $service_file_source = lookup('profile::sre::check_user::service_file'),
    Stdlib::HTTPUrl $proxy_server        = lookup('profile::sre::check_user::proxy_server'),
) {
    # python3-google-auth-httplib2 is also required
    # https://github.com/googleapis/google-auth-library-python/issues/190#issuecomment-322837328
    $packages = ['python3-googleapi', 'python3-google-auth', 'python3-google-auth-httplib2']
    # need at least version 1.6.0
    # https://github.com/googleapis/google-auth-library-python/issues/190#issuecomment-322640637
    apt::pin {'python3-googleapi':
        pin      => 'release a=buster-backports',
        priority => 1001,
    }
    ensure_packages($packages)

    $service_file_path = '/etc/ssl/private/gsuite_service.json'
    $config = @("CONFIG")
    [DEFAULT]
    impersonate: ${super_admin}
    key_file: ${service_file_path}
    proxy_host: ${proxy_server}
    | CONFIG
    file{
        default:
            ensure => file,
            owner  => 'root',
            group  => 'root',
            mode   => '0440';
        $service_file_path:
            content => secret($service_file_source);
        '/etc/check_user.conf':
            content => $config;
        '/usr/local/sbin/check_user':
            mode   => '0550',
            source => 'puppet:///modules/profile/sre/check_user.py';
    }
}
