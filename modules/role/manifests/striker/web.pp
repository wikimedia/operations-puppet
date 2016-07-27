# == Class: role::striker::web
#
# Striker is a Django application for managing data related to Tool Labs
# tools.
#
class role::striker::web {
    $novaconfig = hiera_hash('novaconfig', {})

    class { '::striker::uwsgi':
        # It would be cleaner do this all in private hiera, but several of the
        # passwords we need are in the old style "passwords::*" classes and
        # that makes interpolating them into hiera a challenge.
        # FIXME: Is this really true? Seems that maybe only the ldap pass is
        # current content and we could just copy-n-paste that really since it
        # seems to be scattered already.
        secret_config => {
            'secrets'     => {
                'SECRET_KEY' => '',
            },
            'ldap'        => {
                'BIND_PASSWORD' => $novaconfig['ldap_user_pass'],
            },
            'oauth'       => {
                'CONSUMER_SECRET' => '',
            },
            'phabricator' => {
                'TOKEN' => '',
            },
            'db'          => {
                'PASSWORD' => '',
            },
            'xff'         => {
                # Can we get this from some existing network list? It needs to
                # end up being a space delimited list of ip addrs and/or ip
                # address prefixes (not CIDR, but x.y.x matched via substr)
                'TRUSTED_PROXY_LIST' => '',
            },
        },
    }
    # TODO add nginx vhost (::striker::nginx)
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
