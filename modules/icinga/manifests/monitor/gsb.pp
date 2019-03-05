# sets up monitoring for Google Safe Browsing
# https://phabricator.wikimedia.org/T30898
class icinga::monitor::gsb($client_id, $api_key){
    @monitoring::host { 'google':
        host_fqdn => 'google.com',
    }

    @monitoring::service { 'GSB_mediawiki':
        description   => 'check google safe browsing for mediawiki.org',
        check_command => "check_google_safebrowsing!${client_id}!${api_key}!https://mediawiki.org",
        host          => 'google',
        notes_url     => 'https://phabricator.wikimedia.org/T216985',
    }
    @monitoring::service { 'GSB_wikibooks':
        description   => 'check google safe browsing for wikibooks.org',
        check_command => "check_google_safebrowsing!${client_id}!${api_key}!https://wikibooks.org",
        host          => 'google',
        notes_url     => 'https://phabricator.wikimedia.org/T216985',
    }
    @monitoring::service { 'GSB_wikimedia':
        description   => 'check google safe browsing for wikimedia.org',
        check_command => "check_google_safebrowsing!${client_id}!${api_key}!https://wikimedia.org.org",
        host          => 'google',
        notes_url     => 'https://phabricator.wikimedia.org/T216985',
    }
    @monitoring::service { 'GSB_wikinews':
        description   => 'check google safe browsing for wikinews.org',
        check_command => "check_google_safebrowsing!${client_id}!${api_key}!https://wikinews.org",
        host          => 'google',
        notes_url     => 'https://phabricator.wikimedia.org/T216985',
    }
    @monitoring::service { 'GSB_wikipedia':
        description   => 'check google safe browsing for wikipedia.org',
        check_command => "check_google_safebrowsing!${client_id}!${api_key}!https://wikipedia.org",
        host          => 'google',
        notes_url     => 'https://phabricator.wikimedia.org/T216985',
    }
    @monitoring::service { 'GSB_wikiquote':
        description   => 'check google safe browsing for wikiquote.org',
        check_command => "check_google_safebrowsing!${client_id}!${api_key}!https://wikiquote.org",
        host          => 'google',
        notes_url     => 'https://phabricator.wikimedia.org/T216985',
    }
    @monitoring::service { 'GSB_wikisource':
        description   => 'check google safe browsing for wikisource.org',
        check_command => "check_google_safebrowsing!${client_id}!${api_key}!https://wikisource.org",
        host          => 'google',
        notes_url     => 'https://phabricator.wikimedia.org/T216985',
    }
    @monitoring::service { 'GSB_wikiversity':
        description   => 'check google safe browsing for wikiversity.org',
        check_command => "check_google_safebrowsing!${client_id}!${api_key}!https://wikiversity.org",
        host          => 'google',
        notes_url     => 'https://phabricator.wikimedia.org/T216985',
    }
    @monitoring::service { 'GSB_wiktionary':
        description   => 'check google safe browsing for wiktionary.org',
        check_command => "check_google_safebrowsing!${client_id}!${api_key}!https://wiktionary.org",
        host          => 'google',
        notes_url     => 'https://phabricator.wikimedia.org/T216985',
    }
}
