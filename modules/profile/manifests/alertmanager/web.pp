# SPDX-License-Identifier: Apache-2.0
# enable_sso is used to disable sso in cloud

class profile::alertmanager::web (
    # lint:ignore:wmf_styleguide - T260574
    String $vhost  = lookup('profile::alertmanager::web::vhost', {'default_value' => "alerts.${facts['domain']}"}),
    # lint:endignore
    Boolean $enable_sso  = lookup('profile::alertmanager::web::enable_sso', {'default_value' => true}),
    Boolean $readonly  = lookup('profile::alertmanager::web::readonly', {'default_value' => false}),
    Optional[String[1]] $metricsinfra_username = lookup('profile::alertmanager::web::metricsinfra_username', {'default_value' => undef}),
    Optional[String[1]] $metricsinfra_password = lookup('profile::alertmanager::web::metricsinfra_password', {'default_value' => undef}),
    Hash[String, String] $ldap_config = lookup('ldap', {'merge' => 'hash'}),
) {
    $auth_header = $enable_sso ? {
        true  => 'X-CAS-uid',
        false => undef,
    }

    class { 'alertmanager::karma':
        vhost                 => $vhost,
        listen_address        => '0.0.0.0',
        listen_port           => 19194,
        auth_header           => $auth_header,
        metricsinfra_username => $metricsinfra_username,
        metricsinfra_password => $metricsinfra_password,
    }

    if $enable_sso {
        profile::idp::client::httpd::site { $vhost:
            document_root   => '/var/www/html',
            #acme_chief_cert => 'icinga',
            vhost_content   => 'profile/idp/client/httpd-karma.erb',
            vhost_settings  => { 'readonly' => $readonly },
            required_groups => [
                "cn=wmf,${ldap_config['groups_cn']},${ldap_config['base-dn']}",
                "cn=nda,${ldap_config['groups_cn']},${ldap_config['base-dn']}",
            ],
        }
    } else {
        httpd::site { $vhost:
            content => template('profile/alertmanager/web.apache.erb'),
        }
    }
}
