# the update scripts fetching data (input) for wikistats
# and writing it to local mariadb
class wikistats::updates (
    String $db_pass,
) {

    require_package('php7.0-cli')

    # log dir for wikistats
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

    # update table data: usage: <project prefix>@<hour>
    wikistats::cronjob::update { [
                'wp@0',  # Wikipedias
                'lx@1',  # LXDE
                'si@1',  # Wikisite
                'wt@2',  # Wiktionaries
                'ws@3',  # Wikisources
                'wn@4',  # Wikinews
                'wb@5',  # Wikibooks
                'wq@6',  # Wikiquotes
                'os@7',  # OpenSUSE
                'gt@8',  # Gentoo
                'sf@8',  # Sourceforge
                'an@9',  # Anarchopedias
                'et@9',  # EdiThis
                'wf@10', # Wikifur
                'wy@10', # Wikivoyage
                'wv@11', # Wikiversities
                'wi@11', # Wikia
                'sc@12', # Scoutwikis
                'ne@13', # Neoseeker
                'wr@14', # Wikitravel
                'et@15', # EditThis
                'mt@16', # Metapedias
                'un@17', # Uncylomedias
                'wx@18', # Wikimedia Special
                'mh@18', # Miraheze
                'mw@19', # Mediawikis
                'sw@20', # Shoutwikis
                'ro@21', # Rodovid
                'wk@21', # Wikkii
                're@22', # Referata
                'ga@22', # Gamepedias
                'w3@23', # W3C
                ]: }

    # dump xml data: usage: <project prefix>@<hour>
    wikistats::cronjob::xmldump {
        'wp' : db_pass => $db_pass, table => 'wikipedias',   minute => '3';
        'wt' : db_pass => $db_pass, table => 'wiktionaries', minute => '5';
        'wq' : db_pass => $db_pass, table => 'wikiquotes', minute => '7';
        'wb' : db_pass => $db_pass, table => 'wikibooks', minute => '9';
        'wn' : db_pass => $db_pass, table => 'wikinews', minute => '11';
        'ws' : db_pass => $db_pass, table => 'wikisources', minute => '13';
        'wy' : db_pass => $db_pass, table => 'wikivoyage', minute => '15';
        'wx' : db_pass => $db_pass, table => 'wmspecials', minute => '17';
        'et' : db_pass => $db_pass, table => 'editthis', minute => '23';
        'wr' : db_pass => $db_pass, table => 'wikitravel', minute => '25';
        'mw' : db_pass => $db_pass, table => 'mediawikis', minute => '32';
        'mt' : db_pass => $db_pass, table => 'metapedias', minute => '37';
        'sc' : db_pass => $db_pass, table => 'scoutwiki', minute => '39';
        'os' : db_pass => $db_pass, table => 'opensuse', minute => '41';
        'un' : db_pass => $db_pass, table => 'uncyclomedia', minute => '43';
        'wf' : db_pass => $db_pass, table => 'wikifur', minute => '45';
        'an' : db_pass => $db_pass, table => 'anarchopedias', minute => '47';
        'si' : db_pass => $db_pass, table => 'wikisite', minute => '51';
        'ne' : db_pass => $db_pass, table => 'neoseeker', minute => '53';
        'wv' : db_pass => $db_pass, table => 'wikiversity', minute => '34';
        're' : db_pass => $db_pass, table => 'referata', minute => '57';
        'ro' : db_pass => $db_pass, table => 'rodovid', minute => '1';
        'lx' : db_pass => $db_pass, table => 'lxde', minute => '59';
        'sw' : db_pass => $db_pass, table => 'shoutwiki', minute => '36';
        'w3' : db_pass => $db_pass, table => 'w3cwikis', minute => '27';
        'ga' : db_pass => $db_pass, table => 'gamepedias', minute => '29';
        'sf' : db_pass => $db_pass, table => 'sourceforge', minute => '24';
        'mh' : db_pass => $db_pass, table => 'miraheze', minute => '6';
    }

    # imports (fetching lists of wikis itself) usage: <project name>@<weekday>
    wikistats::cronjob::import { [
        'miraheze@5', # https://phabricator.wikimedia.org/T153930
    ]: }

}
