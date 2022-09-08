# Create a list of static web-proxy mappings, using key, value pairs in $proxy_mappings
#
# By default we block two user agents:
#
#   TweetmemeBot T73120
#   OruxMaps     T97841
#
#
class profile::wmcs::proxy::static(
    Hash   $proxy_mappings           = lookup('profile::wmcs::proxy::static::proxy_mappings'),
    Array  $banned_ips               = lookup('profile::wmcs::proxy::static::banned_ips',          {default_value => []}),
    Array  $acme_chief_certs         = lookup('profile::wmcs::proxy::static::acme_chief_certs',    {default_value => []}),
    String $blocked_user_agent_regex = lookup('profile::wmcs::proxy::static::blocked_user_agents', {default_value => '(TweetmemeBot|OruxMaps.*)'}),
    String $blocked_referer_regex    = lookup('profile::wmcs::proxy::static::blocked_referers',    {default_value => ''}),
) {
    $ssl_settings  = ssl_ciphersuite('nginx', 'compat')

    class { '::nginx':
        variant => 'extras',
    }
    nginx::site { 'proxies':
        content => template('profile/wmcs/proxy/static.conf.erb'),
    }

    class { '::sslcert::dhparam': }
    $acme_chief_certs.each |String $certname| {
        acme_chief::cert { $certname:
            puppet_rsc => Exec['nginx-reload'],
        }
    }

    class { 'prometheus::nginx_exporter': }
}
