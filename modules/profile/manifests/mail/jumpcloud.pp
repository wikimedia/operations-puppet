# @summary a class to install the jumpcloud scraping script and create the correct exim files
# @param api_uri the jumpcloud api uri endpoint
# @param api_key The jumpcloud API key
# @param managed_domain The domain name of the jumpcloud managed domain
# @param aliases_dir location of aliases directory
class profile::mail::jumpcloud (
    Stdlib::Host     $api_uri        = lookup('profile::mail::jumpcloud::api_uri'),
    String[40,40]    $api_key        = lookup('profile::mail::jumpcloud::api_key'),
    Stdlib::Host     $managed_domain = lookup('profile::mail::jumpcloud::managed_domain'),
    Stdlib::Unixpath $aliases_dir    = lookup('profile::mail::jumpcloud::aliases_dir')
) {
    $config = @(CONFIG)
    [DEFAULT]
    api_uri: ${api_uri}
    api_key: ${api_key}
    aliases_directory: ${aliases_dir}
    managed_domain: ${managed_domain}
    | CONFIG
    file {
        default:
            ensure => file,
            owner  => 'root',
            group  => 'root',
            mode   => '0550';
        '/usr/local/sbin/jumpcloud_aliases':
            content => file('profile/mail/jumpcloud_aliases.py');
        '/etc/jumpcloud.ini':
            mode    => '0440',
            content => $config;
    }
    systemd::timer::job {'generate jumpcloud aliases':
        ensure             => present,
        description        => 'Generte local mailparts from jumpcloud API',
        command            => '/usr/local/sbin/jumpcloud_aliases',
        interval           => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:15:00', # Every hour at minute 15
        },
        monitoring_enabled => true,
        user               => 'root',
    }
}
