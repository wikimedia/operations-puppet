# @summary profile to install a vhost for external monitoring
# @param vhost the vhost to listen on
# @param htpasswd_salt the salt to use in the httpd auth file
# @param auth_users the salt to use in the httpd auth file
class profile::icinga::external_monitoring (
    String               $htpasswd_salt    = lookup('profile::icinga::external_monitoring::htpasswd_salt'),
    Array[Stdlib::Host]  $monitoring_hosts = lookup('profile::icinga::external_monitoring::monitoring_hosts'),

    Hash[String, String] $auth_users       = lookup('profile::icinga::external_monitoring::auth_users'),
    Stdlib::Host         $vhost            = lookup('profile::icinga::external_monitoring::vhost'),

) {
    $auth_user_file = '/etc/icinga/apache2_ext_auth_user_file'
    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    $allow_from = $monitoring_hosts.map |Stdlib::Host $host| {
        [$host.ipresolve(4), $host.ipresolve(6)].filter |$val| { $val =~ NotUndef }
    }.flatten
    $apache_auth_content = $auth_users.map |String $user, String $password| {
        $password_hash = $password.htpasswd($htpasswd_salt)
        "${user}:${password_hash}"
    }
    file {$auth_user_file:
        ensure  => file,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
        content => $apache_auth_content.join("\n")
    }
    httpd::site {$vhost:
        priority => 99,
        content  => template('profile/icinga/external_monitoring.conf.erb'),
    }
    monitoring::service {"https-${vhost}-unauthorized":
        description   => "${vhost} requires authentication",
        check_command => "check_https_unauthorized!${vhost}!/cgi-bin/icinga/extinfo.cgi?type=0!403",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Monitoring/https_unauthorized',
    }
    monitoring::service {"https-${vhost}-expiry":
        description   => "${vhost} SSL Expiry",
        check_command => "check_https_expiry!${vhost}!443",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Monitoring/https_unauthorized',
    }
}
