# @summary class to install a script for validating user email addresses
# @param super_admin the support admin account to impersonate
# @param service_file_source the location in the secret module of the service account json file
class profile::sre::check_user (
    String $super_admin         = lookup('profile::sre::gsuite::super_admin'),
    String $service_file_source = lookup('profile::sre::gsuite::service_file'),
) {

    $service_file_path = '/etc/ssl/private/gsuite_service.json'
    $config = @("CONFIG")
    [DEFAULT]
    impersonate: ${super_admin}
    key_file: ${service_file_path}
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
            source => 'puppet:///modules/profile/mail/check_user.py';

    }
}
