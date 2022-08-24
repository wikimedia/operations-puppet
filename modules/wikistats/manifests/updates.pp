# SPDX-License-Identifier: Apache-2.0
# the update scripts fetching data (input) for wikistats
# and writing it to local mariadb
class wikistats::updates (
    String $db_pass,
    Wmflib::Ensure $ensure,
    Wmflib::Php_version $php_version,
){

    ensure_packages("php${php_version}-cli")

    file { '/var/log/wikistats':
        ensure => directory,
        mode   => '0664',
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
        'wp' : ensure => $ensure, hour => 0;  # Wikipedias
        'lx' : ensure => $ensure, hour => 7;  # LXDE
        'si' : ensure => $ensure, hour => 7;  # Wikisite
        'wt' : ensure => $ensure, hour => 1;  # Wiktionaries
        'ws' : ensure => $ensure, hour => 2;  # Wikisources
        'wn' : ensure => $ensure, hour => 3;  # Wikinews
        'wb' : ensure => $ensure, hour => 4;  # Wikibooks
        'wq' : ensure => $ensure, hour => 5;  # Wikiquotes
        'os' : ensure => $ensure, hour => 7;  # OpenSUSE
        'gt' : ensure => $ensure, hour => 8;  # Gentoo
        'sf' : ensure => $ensure, hour => 8;  # Sourceforge
        'an' : ensure => $ensure, hour => 9;  # Anarchopedias
        'wf' : ensure => $ensure, hour => 10; # Wikifur
        'wy' : ensure => $ensure, hour => 6; # Wikivoyage
        'wv' : ensure => $ensure, hour => 11; # Wikiversities
        'wi' : ensure => $ensure, hour => 11; # Wikia
        'sc' : ensure => $ensure, hour => 12; # Scoutwikis
        'ne' : ensure => $ensure, hour => 13; # Neoseeker
        'wr' : ensure => $ensure, hour => 14; # Wikitravel
        'et' : ensure => $ensure, hour => 15; # EditThis
        'mt' : ensure => $ensure, hour => 16; # Metapedias
        'un' : ensure => $ensure, hour => 17; # Uncylomedias
        'wx' : ensure => $ensure, hour => 18; # Wikimedia Special
        'mh' : ensure => $ensure, hour => 18; # Miraheze
        'mw' : ensure => $ensure, hour => 19; # MediaWikis
        'sw' : ensure => $ensure, hour => 20; # Shoutwikis
        'ro' : ensure => $ensure, hour => 21; # Rodovid
        'wk' : ensure => $ensure, hour => 21; # Wikkii
        're' : ensure => $ensure, hour => 22; # Referata
        'ga' : ensure => $ensure, hour => 22; # Gamepedias
        'w3' : ensure => $ensure, hour => 23; # W3C
      }

    # dump xml data
    wikistats::job::xmldump {
        'wp' : ensure => $ensure, db_pass => $db_pass, table => 'wikipedias',   minute => 3;
        'wt' : ensure => $ensure, db_pass => $db_pass, table => 'wiktionaries', minute => 5;
        'wq' : ensure => $ensure, db_pass => $db_pass, table => 'wikiquotes',   minute => 7;
        'wb' : ensure => $ensure, db_pass => $db_pass, table => 'wikibooks',    minute => 9;
        'wn' : ensure => $ensure, db_pass => $db_pass, table => 'wikinews',     minute => 11;
        'ws' : ensure => $ensure, db_pass => $db_pass, table => 'wikisources',  minute => 13;
        'wy' : ensure => $ensure, db_pass => $db_pass, table => 'wikivoyage',   minute => 15;
        'wx' : ensure => $ensure, db_pass => $db_pass, table => 'wmspecials',   minute => 1;
        'et' : ensure => $ensure, db_pass => $db_pass, table => 'editthis',     minute => 23;
        'wr' : ensure => $ensure, db_pass => $db_pass, table => 'wikitravel',   minute => 25;
        'mw' : ensure => $ensure, db_pass => $db_pass, table => 'mediawikis',   minute => 32;
        'mt' : ensure => $ensure, db_pass => $db_pass, table => 'metapedias',   minute => 37;
        'sc' : ensure => $ensure, db_pass => $db_pass, table => 'scoutwiki',    minute => 39;
        'os' : ensure => $ensure, db_pass => $db_pass, table => 'opensuse',     minute => 41;
        'un' : ensure => $ensure, db_pass => $db_pass, table => 'uncyclomedia', minute => 43;
        'wf' : ensure => $ensure, db_pass => $db_pass, table => 'wikifur',      minute => 45;
        'an' : ensure => $ensure, db_pass => $db_pass, table => 'anarchopedias',minute => 47;
        'si' : ensure => $ensure, db_pass => $db_pass, table => 'wikisite',     minute => 51;
        'ne' : ensure => $ensure, db_pass => $db_pass, table => 'neoseeker',    minute => 53;
        'wv' : ensure => $ensure, db_pass => $db_pass, table => 'wikiversity',  minute => 34;
        're' : ensure => $ensure, db_pass => $db_pass, table => 'referata',     minute => 57;
        'ro' : ensure => $ensure, db_pass => $db_pass, table => 'rodovid',      minute => 1;
        'lx' : ensure => $ensure, db_pass => $db_pass, table => 'lxde',         minute => 59;
        'sw' : ensure => $ensure, db_pass => $db_pass, table => 'shoutwiki',    minute => 36;
        'w3' : ensure => $ensure, db_pass => $db_pass, table => 'w3cwikis',     minute => 27;
        'ga' : ensure => $ensure, db_pass => $db_pass, table => 'gamepedias',   minute => 29;
        'sf' : ensure => $ensure, db_pass => $db_pass, table => 'sourceforge',  minute => 24;
        'mh' : ensure => $ensure, db_pass => $db_pass, table => 'miraheze',     minute => 6;
    }

    # imports (fetching lists of wikis itself)
    wikistats::job::import {
        'miraheze':  ensure => $ensure, weekday => 'Friday' ; # https://phabricator.wikimedia.org/T153930
        'neoseeker': ensure => $ensure, weekday => 'Sunday' ; # https://phabricator.wikimedia.org/T1262113
    }
}
