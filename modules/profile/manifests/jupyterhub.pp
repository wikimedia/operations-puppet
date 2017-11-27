# == Class profile::jupyterhub
#
# Setting up PAWS Internal - Jupyterhub service running on analytics cluster
#
# See https://wikitech.wikimedia.org/wiki/PAWS/Internal for more info
#
class profile::jupyterhub(
    $include_statistics_credentials = hiera('profile::jupyterhub::include_statistics_credentials'),
) {
    class { '::statistics::packages': }

    class { '::jupyterhub':
        base_path   => '/srv/paws-internal',
        wheels_repo => 'operations/wheels/paws-internal',
        web_proxy   => 'http://webproxy.eqiad.wmnet:8080',
    }

    class { '::jupyterhub::static':
        sitename    => 'paws-internal.wikimedia.org',
        static_path => '/srv/paws-internal/static',
        url_prefix  => '/public',
        ldap_groups => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
        ],
    }

    if $include_statistics_credentials {
        statistics::mysql_credentials { 'research':
            group => 'researchers',
        }
    }

}
