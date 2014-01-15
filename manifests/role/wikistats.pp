# wikistats host role class
# this is labs only! - wikistats.wmflabs.org (dzahn)
# NOT stats.wikimedia.org (analytics/ezachte)
# realm case is just here for compatibility
class role::wikistats {

    system_role { 'wikistats': description => 'wikistats instance' }

    # config - labs vs. production
    case $::realm {
        'labs': {
            $wikistats_host = 'wikistats.wmflabs.org'
            $wikistats_ssl_cert = '/etc/ssl/certs/star.wmflabs.org.pem'
            $wikistats_ssl_key = '/etc/ssl/private/star.wmflabs.org.key'
        }
        'production': {
            $wikistats_host = 'wikistats.wikimedia.org'
            $wikistats_ssl_cert = '/etc/ssl/certs/star.wikimedia.org.pem'
            $wikistats_ssl_key = '/etc/ssl/private/star.wikimedia.org.key'
        }
        'default': {
            fail('unknown realm, should be labs or production')
        }
    }

    # main
    class { '::wikistats':
        wikistats_host     => $wikistats_host,
        wikistats_ssl_cert => $wikistats_ssl_cert,
        wikistats_ssl_key  => $wikistats_ssl_key
    }

}

