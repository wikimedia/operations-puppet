# SPDX-License-Identifier: Apache-2.0
# the update scripts fetching data (input) for wikistats
# and writing it to local mariadb
class wikistats::updates (
    String $db_pass,
    Wmflib::Ensure $ensure,
    Wmflib::Php_version $php_version,
){

    stdlib::ensure_packages("php${php_version}-cli")

    file { '/var/log/wikistats':
        ensure => directory,
        mode   => '0775',
        owner  => 'wikistatsuser',
        group  => 'wikistatsuser',
    }

    # db pass for [client] for dumps
    file { '/usr/lib/wikistats/.my.cnf':
        ensure  => present,
        mode    => '0400',
        owner   => 'wikistatsuser',
        group   => 'wikistatsuser',
        content => "[client]\npassword=${db_pass}\n"
    }

    # fetch new wiki data
    wikistats::job::update {
        'wp' : ensure => $ensure, hour => 0;                # Wikipedias
        'si' : ensure => $ensure, hour => 7;                # Wikisite
        'wt' : ensure => $ensure, hour => 1;                # Wiktionaries
        'ws' : ensure => $ensure, hour => 2;                # Wikisources
        'wn' : ensure => $ensure, hour => 3;                # Wikinews
        'wb' : ensure => $ensure, hour => 4;                # Wikibooks
        'wq' : ensure => $ensure, hour => 5;                # Wikiquotes
        'os' : ensure => $ensure, hour => 7;                # OpenSUSE
        'sf' : ensure => $ensure, hour => 8;                # Sourceforge
        'an' : ensure => $ensure, hour => 9;                # Anarchopedias
        'wf' : ensure => $ensure, hour => 10;               # Wikifur
        'wy' : ensure => $ensure, hour => 6;                # Wikivoyage
        'wv' : ensure => $ensure, hour => 11;               # Wikiversities
        'wi' : ensure => $ensure, hour => 11, day => 'Mon'; # Wikia
        'sc' : ensure => $ensure, hour => 12;               # Scoutwikis
        'ne' : ensure => $ensure, hour => 13;               # Neoseeker
        'wr' : ensure => $ensure, hour => 14;               # Wikitravel
        'et' : ensure => $ensure, hour => 15;               # EditThis
        'mt' : ensure => $ensure, hour => 16;               # Metapedias
        'un' : ensure => $ensure, hour => 17;               # Uncyclomedias
        'wx' : ensure => $ensure, hour => 18;               # Wikimedia Special
        'mh' : ensure => $ensure, hour => 18;               # Miraheze
        'mw' : ensure => $ensure, hour => 19;               # MediaWikis
        'sw' : ensure => $ensure, hour => 20;               # Shoutwikis
        'ro' : ensure => $ensure, hour => 21;               # Rodovid
        'ga' : ensure => $ensure, hour => 22;               # Gamepedias
        'gp' : ensure => $ensure, hour => 23;               # Gyaanipedias
        'w3' : ensure => $ensure, hour => 23;               # W3C
    }

    # dump xml data
    wikistats::job::xmldump {
        'wp' : ensure => $ensure, table => 'wikipedias',    minute => 3;
        'wt' : ensure => $ensure, table => 'wiktionaries',  minute => 5;
        'wq' : ensure => $ensure, table => 'wikiquotes',    minute => 7;
        'wb' : ensure => $ensure, table => 'wikibooks',     minute => 9;
        'wn' : ensure => $ensure, table => 'wikinews',      minute => 11;
        'ws' : ensure => $ensure, table => 'wikisources',   minute => 13;
        'wy' : ensure => $ensure, table => 'wikivoyage',    minute => 15;
        'wx' : ensure => $ensure, table => 'wmspecials',    minute => 1;
        'et' : ensure => $ensure, table => 'editthis',      minute => 23;
        'wr' : ensure => $ensure, table => 'wikitravel',    minute => 25;
        'mw' : ensure => $ensure, table => 'mediawikis',    minute => 32;
        'mt' : ensure => $ensure, table => 'metapedias',    minute => 37;
        'sc' : ensure => $ensure, table => 'scoutwiki',     minute => 39;
        'os' : ensure => $ensure, table => 'opensuse',      minute => 41;
        'un' : ensure => $ensure, table => 'uncyclomedia',  minute => 43;
        'wf' : ensure => $ensure, table => 'wikifur',       minute => 45;
        'an' : ensure => $ensure, table => 'anarchopedias', minute => 47;
        'si' : ensure => $ensure, table => 'wikisite',      minute => 51;
        'ne' : ensure => $ensure, table => 'neoseeker',     minute => 53;
        'wv' : ensure => $ensure, table => 'wikiversity',   minute => 34;
        'ro' : ensure => $ensure, table => 'rodovid',       minute => 1;
        'sw' : ensure => $ensure, table => 'shoutwiki',     minute => 36;
        'w3' : ensure => $ensure, table => 'w3cwikis',      minute => 27;
        'ga' : ensure => $ensure, table => 'gamepedias',    minute => 29;
        'sf' : ensure => $ensure, table => 'sourceforge',   minute => 24;
        'mh' : ensure => $ensure, table => 'miraheze',      minute => 6;
    }

    # imports (fetching lists of wikis itself)
    wikistats::job::import {
        'miraheze':  ensure => $ensure, weekday => 'Friday'; # https://phabricator.wikimedia.org/T153930
        'neoseeker': ensure => $ensure, weekday => 'Sunday'; # https://phabricator.wikimedia.org/T262113
    }
}
