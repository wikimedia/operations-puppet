class mediawiki::web::portals (
    $portal_dir,
) {

    $rewrite_portal = $portal_dir != 'portal'

    $additional_portals = {
        'wikibooks'   => { },
        'wikinews'    => { },
        'wikiquote'   => { },
        'wikiversity' => { },
        'wikivoyage'  => {
            'additional_config' => template('mediawiki/apache/sites/wikivoyage-additional.conf.erb')
        },
        'wiktionary'  => { },
    }

    apache::site { 'wwwportals':
        content  => template('mediawiki/apache/sites/wwwportals.conf.erb'),
        priority => 1,
    }

}