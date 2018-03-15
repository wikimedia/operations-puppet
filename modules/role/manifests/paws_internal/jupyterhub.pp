# == Class role::paws_internal::jupyterhub
# Role for setting up PAWS Internal - Jupyterhub service running on analytics cluster
#
# See https://wikitech.wikimedia.org/wiki/PAWS/Internal for more info
# TODO: This class will be removed as part of https://phabricator.wikimedia.org/T183145
class role::paws_internal::jupyterhub {

    include ::base::firewall
    include ::statistics::packages

    class { '::jupyterhub_old':
        base_path   => '/srv/paws-internal',
        wheels_repo => 'operations/wheels/paws-internal',
    }

    class { '::jupyterhub_old::static':
        sitename    => 'paws-internal.wikimedia.org',
        static_path => '/srv/paws-internal/static',
        url_prefix  => '/public',
        ldap_groups => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
        ],
    }

}
