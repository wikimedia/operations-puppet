# vim: set ts=4 et sw=4:
# role/db.pp
# db::core for a few remaining m1 boxes
# or db::sanitarium or db::labsdb for the labsdb project

class role::db::core {
    $cluster = "mysql"

    system::role { "db::core": description => "Core Database server" }

    include standard,
        mysql_wmf
}


class role::db::sanitarium( $instances = {} ) {
## $instances must be a 2-level hash of the form:
## 'shard9001' => { port => NUMBER, innodb_log_file_size => "CORRECT_M", ram => "HELLA_G" },
## 'shard9002' => { port => NUMBER+1, innodb_log_file_size => "CORRECT_M", ram => "HELLA_G" },
    $cluster = "mysql"

    system::role {"role::db::sanitarium": description => "pre-labsdb dbs for Data Sanitization" }

    include standard,
        cpufrequtils,
        mysql_multi_instance

    class { mysql :
        package_name => 'mariadb-client-5.5'
    }

    ## for key in instances, make a mysql instance. need port, innodb_log_file_size, and amount of ram
    $instances_keys = keys($instances)
    mysql_multi_instance::instance { $instances_keys :
        instances => $instances
    }

    ## some per-node monitoring here
    $instances_count = size($instances_keys)

    file { "/usr/lib/nagios/plugins/percona":
        ensure => directory,
        recurse => true,
        owner => root,
        group => root,
        mode => 0555,
        source => "puppet:///modules/mysql_wmf/icinga/percona";
    }

    nrpe::monitor_service { "mysqld":
        description => "mysqld processes",
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c ${instances_count}:${instances_count} -C mysqld"
    }

}

class role::db::labsdb( $instances = {} ) {
## $instances must be a 2-level hash of the form:
## 'shard9001' => { port => NUMBER, innodb_log_file_size => "CORRECT_M", ram => "HELLA_G" },
## 'shard9002' => { port => NUMBER+1, innodb_log_file_size => "CORRECT_M", ram => "HELLA_G" },
    $cluster = "mysql"

    system::role {"role::db::labsdb": description => "labsdb dbs for labs use" }

    include standard,
        cpufrequtils,
        mysql_multi_instance

    class { mysql :
        package_name => 'mariadb-client-5.5'
    }

    ## for key in instances, make a mysql instance. need port, innodb_log_file_size, and amount of ram
    $instances_keys = keys($instances)
    mysql_multi_instance::instance { $instances_keys :
        instances => $instances
    }

    ## some per-node monitoring here
    $instances_count = size($instances_keys)

    file { "/usr/lib/nagios/plugins/percona":
        ensure => directory,
        recurse => true,
        owner => root,
        group => root,
        mode => 0555,
        source => "puppet:///modules/mysql_wmf/icinga/percona";
    }

    nrpe::monitor_service { "mysqld":
        description => "mysqld processes",
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c ${instances_count}:${instances_count} -C mysqld"
    }
}

class role::labsdb::client {
    system::role {"role::db::client": description => "LabsDB client" }

    # TODO: DRY; this list is (should) already be maintained somewhere.
    # TODO: Using static IP addresses for the LabsDB servers seems bad(TM).
    host { 's1.labsdb':
        ip => '192.168.99.1',
        host_aliases => [ 'enwiki.labsdb' ];
    }

    host { 's2.labsdb':
        ip => '192.168.99.2',

        host_aliases => [ 'bgwiki.labsdb', 'bgwiktionary.labsdb',
                          'cswiki.labsdb', 'enwikiquote.labsdb',
                          'enwiktionary.labsdb', 'eowiki.labsdb',
                          'fiwiki.labsdb', 'idwiki.labsdb',
                          'itwiki.labsdb', 'nlwiki.labsdb',
                          'nowiki.labsdb', 'plwiki.labsdb',
                          'ptwiki.labsdb', 'svwiki.labsdb',
                          'thwiki.labsdb', 'trwiki.labsdb',
                          'zhwiki.labsdb' ];
    }

    host { 's3.labsdb':
        ip => '192.168.99.3',
        host_aliases => [ 'aawiki.labsdb', 'aawikibooks.labsdb',
                          'aawiktionary.labsdb', 'abwiki.labsdb',
                          'abwiktionary.labsdb', 'acewiki.labsdb',
                          'advisorywiki.labsdb', 'afwiki.labsdb',
                          'afwikibooks.labsdb', 'afwikiquote.labsdb',
                          'afwiktionary.labsdb', 'akwiki.labsdb',
                          'akwikibooks.labsdb', 'akwiktionary.labsdb',
                          'alswiki.labsdb', 'alswikibooks.labsdb',
                          'alswikiquote.labsdb',
                          'alswiktionary.labsdb', 'amwiki.labsdb',
                          'amwikiquote.labsdb', 'amwiktionary.labsdb',
                          'angwiki.labsdb', 'angwikibooks.labsdb',
                          'angwikiquote.labsdb',
                          'angwikisource.labsdb',
                          'angwiktionary.labsdb', 'anwiki.labsdb',
                          'anwiktionary.labsdb', 'arcwiki.labsdb',
                          'arwikibooks.labsdb', 'arwikimedia.labsdb',
                          'arwikinews.labsdb', 'arwikiquote.labsdb',
                          'arwikisource.labsdb',
                          'arwikiversity.labsdb',
                          'arwiktionary.labsdb', 'arzwiki.labsdb',
                          'astwiki.labsdb', 'astwikibooks.labsdb',
                          'astwikiquote.labsdb',
                          'astwiktionary.labsdb', 'aswiki.labsdb',
                          'aswikibooks.labsdb', 'aswikisource.labsdb',
                          'aswiktionary.labsdb', 'avwiki.labsdb',
                          'avwiktionary.labsdb', 'aywiki.labsdb',
                          'aywikibooks.labsdb', 'aywiktionary.labsdb',
                          'azwiki.labsdb', 'azwikibooks.labsdb',
                          'azwikiquote.labsdb', 'azwikisource.labsdb',
                          'azwiktionary.labsdb', 'barwiki.labsdb',
                          'bat_smgwiki.labsdb', 'bawiki.labsdb',
                          'bawikibooks.labsdb', 'bclwiki.labsdb',
                          'bdwikimedia.labsdb', 'be_x_oldwiki.labsdb',
                          'betawikiversity.labsdb', 'bewiki.labsdb',
                          'bewikibooks.labsdb', 'bewikimedia.labsdb',
                          'bewikiquote.labsdb', 'bewikisource.labsdb',
                          'bewiktionary.labsdb', 'bgwikibooks.labsdb',
                          'bgwikinews.labsdb', 'bgwikiquote.labsdb',
                          'bgwikisource.labsdb', 'bhwiki.labsdb',
                          'bhwiktionary.labsdb', 'biwiki.labsdb',
                          'biwikibooks.labsdb', 'biwiktionary.labsdb',
                          'bjnwiki.labsdb', 'bmwiki.labsdb',
                          'bmwikibooks.labsdb', 'bmwikiquote.labsdb',
                          'bmwiktionary.labsdb', 'bnwiki.labsdb',
                          'bnwikibooks.labsdb', 'bnwikisource.labsdb',
                          'bnwiktionary.labsdb', 'bowiki.labsdb',
                          'bowikibooks.labsdb', 'bowiktionary.labsdb',
                          'bpywiki.labsdb', 'brwiki.labsdb',
                          'brwikimedia.labsdb', 'brwikiquote.labsdb',
                          'brwikisource.labsdb',
                          'brwiktionary.labsdb', 'bswiki.labsdb',
                          'bswikibooks.labsdb', 'bswikinews.labsdb',
                          'bswikiquote.labsdb', 'bswikisource.labsdb',
                          'bswiktionary.labsdb', 'bugwiki.labsdb',
                          'bxrwiki.labsdb', 'cawikibooks.labsdb',
                          'cawikinews.labsdb', 'cawikiquote.labsdb',
                          'cawikisource.labsdb',
                          'cawiktionary.labsdb', 'cbk_zamwiki.labsdb',
                          'cdowiki.labsdb', 'cebwiki.labsdb',
                          'cewiki.labsdb', 'chowiki.labsdb',
                          'chrwiki.labsdb', 'chrwiktionary.labsdb',
                          'chwiki.labsdb', 'chwikibooks.labsdb',
                          'chwiktionary.labsdb', 'chywiki.labsdb',
                          'ckbwiki.labsdb', 'cowiki.labsdb',
                          'cowikibooks.labsdb', 'cowikimedia.labsdb',
                          'cowikiquote.labsdb', 'cowiktionary.labsdb',
                          'crhwiki.labsdb', 'crwiki.labsdb',
                          'crwikiquote.labsdb', 'crwiktionary.labsdb',
                          'csbwiki.labsdb', 'csbwiktionary.labsdb',
                          'cswikibooks.labsdb', 'cswikinews.labsdb',
                          'cswikiquote.labsdb', 'cswikisource.labsdb',
                          'cswikiversity.labsdb',
                          'cswiktionary.labsdb', 'cuwiki.labsdb',
                          'cvwiki.labsdb', 'cvwikibooks.labsdb',
                          'cywiki.labsdb', 'cywikibooks.labsdb',
                          'cywikiquote.labsdb', 'cywikisource.labsdb',
                          'cywiktionary.labsdb', 'dawiki.labsdb',
                          'dawikibooks.labsdb', 'dawikiquote.labsdb',
                          'dawikisource.labsdb',
                          'dawiktionary.labsdb', 'dewikibooks.labsdb',
                          'dewikinews.labsdb', 'dewikiquote.labsdb',
                          'dewikisource.labsdb',
                          'dewikiversity.labsdb',
                          'dewikivoyage.labsdb',
                          'dewiktionary.labsdb', 'diqwiki.labsdb',
                          'dkwikimedia.labsdb', 'donatewiki.labsdb',
                          'dsbwiki.labsdb', 'dvwiki.labsdb',
                          'dvwiktionary.labsdb', 'dzwiki.labsdb',
                          'dzwiktionary.labsdb', 'eewiki.labsdb',
                          'elwiki.labsdb', 'elwikibooks.labsdb',
                          'elwikinews.labsdb', 'elwikiquote.labsdb',
                          'elwikisource.labsdb',
                          'elwikiversity.labsdb',
                          'elwikivoyage.labsdb',
                          'elwiktionary.labsdb', 'emlwiki.labsdb',
                          'enwikibooks.labsdb', 'enwikinews.labsdb',
                          'enwikisource.labsdb',
                          'enwikiversity.labsdb',
                          'enwikivoyage.labsdb', 'eowikibooks.labsdb',
                          'eowikinews.labsdb', 'eowikiquote.labsdb',
                          'eowikisource.labsdb',
                          'eowiktionary.labsdb', 'eswikibooks.labsdb',
                          'eswikinews.labsdb', 'eswikiquote.labsdb',
                          'eswikisource.labsdb',
                          'eswikiversity.labsdb',
                          'eswikivoyage.labsdb',
                          'eswiktionary.labsdb', 'etwiki.labsdb',
                          'etwikibooks.labsdb', 'etwikimedia.labsdb',
                          'etwikiquote.labsdb', 'etwikisource.labsdb',
                          'etwiktionary.labsdb', 'euwiki.labsdb',
                          'euwikibooks.labsdb', 'euwikiquote.labsdb',
                          'euwiktionary.labsdb', 'extwiki.labsdb',
                          'fawikibooks.labsdb', 'fawikinews.labsdb',
                          'fawikiquote.labsdb', 'fawikisource.labsdb',
                          'fawiktionary.labsdb', 'ffwiki.labsdb',
                          'fiu_vrowiki.labsdb', 'fiwikibooks.labsdb',
                          'fiwikimedia.labsdb', 'fiwikinews.labsdb',
                          'fiwikiquote.labsdb', 'fiwikisource.labsdb',
                          'fiwikiversity.labsdb',
                          'fiwiktionary.labsdb', 'fjwiki.labsdb',
                          'fjwiktionary.labsdb',
                          'foundationwiki.labsdb', 'fowiki.labsdb',
                          'fowikisource.labsdb',
                          'fowiktionary.labsdb', 'frpwiki.labsdb',
                          'frrwiki.labsdb', 'frwikibooks.labsdb',
                          'frwikinews.labsdb', 'frwikiquote.labsdb',
                          'frwikisource.labsdb',
                          'frwikiversity.labsdb',
                          'frwikivoyage.labsdb', 'furwiki.labsdb',
                          'fywiki.labsdb', 'fywikibooks.labsdb',
                          'fywiktionary.labsdb', 'gagwiki.labsdb',
                          'ganwiki.labsdb', 'gawiki.labsdb',
                          'gawikibooks.labsdb', 'gawikiquote.labsdb',
                          'gawiktionary.labsdb', 'gdwiki.labsdb',
                          'gdwiktionary.labsdb', 'glkwiki.labsdb',
                          'glwiki.labsdb', 'glwikibooks.labsdb',
                          'glwikiquote.labsdb', 'glwikisource.labsdb',
                          'glwiktionary.labsdb', 'gnwiki.labsdb',
                          'gnwikibooks.labsdb', 'gnwiktionary.labsdb',
                          'gotwiki.labsdb', 'gotwikibooks.labsdb',
                          'guwiki.labsdb', 'guwikibooks.labsdb',
                          'guwikiquote.labsdb', 'guwikisource.labsdb',
                          'guwiktionary.labsdb', 'gvwiki.labsdb',
                          'gvwiktionary.labsdb', 'hakwiki.labsdb',
                          'hawiki.labsdb', 'hawiktionary.labsdb',
                          'hawwiki.labsdb', 'hewikibooks.labsdb',
                          'hewikinews.labsdb', 'hewikiquote.labsdb',
                          'hewikisource.labsdb',
                          'hewikivoyage.labsdb',
                          'hewiktionary.labsdb', 'hifwiki.labsdb',
                          'hiwiki.labsdb', 'hiwikibooks.labsdb',
                          'hiwikiquote.labsdb', 'hiwiktionary.labsdb',
                          'howiki.labsdb', 'hrwiki.labsdb',
                          'hrwikibooks.labsdb', 'hrwikiquote.labsdb',
                          'hrwikisource.labsdb',
                          'hrwiktionary.labsdb', 'hsbwiki.labsdb',
                          'hsbwiktionary.labsdb', 'htwiki.labsdb',
                          'htwikisource.labsdb', 'huwikibooks.labsdb',
                          'huwikinews.labsdb', 'huwikiquote.labsdb',
                          'huwikisource.labsdb',
                          'huwiktionary.labsdb', 'hywiki.labsdb',
                          'hywikibooks.labsdb', 'hywikiquote.labsdb',
                          'hywikisource.labsdb',
                          'hywiktionary.labsdb', 'hzwiki.labsdb',
                          'iawiki.labsdb', 'iawikibooks.labsdb',
                          'iawiktionary.labsdb', 'idwikibooks.labsdb',
                          'idwikiquote.labsdb', 'idwikisource.labsdb',
                          'idwiktionary.labsdb', 'iewiki.labsdb',
                          'iewikibooks.labsdb', 'iewiktionary.labsdb',
                          'igwiki.labsdb', 'iiwiki.labsdb',
                          'ikwiki.labsdb', 'ikwiktionary.labsdb',
                          'ilowiki.labsdb', 'incubatorwiki.labsdb',
                          'iowiki.labsdb', 'iowiktionary.labsdb',
                          'iswiki.labsdb', 'iswikibooks.labsdb',
                          'iswikiquote.labsdb', 'iswikisource.labsdb',
                          'iswiktionary.labsdb', 'itwikibooks.labsdb',
                          'itwikinews.labsdb', 'itwikiquote.labsdb',
                          'itwikisource.labsdb',
                          'itwikiversity.labsdb',
                          'itwikivoyage.labsdb',
                          'itwiktionary.labsdb', 'iuwiki.labsdb',
                          'iuwiktionary.labsdb', 'jawikibooks.labsdb',
                          'jawikinews.labsdb', 'jawikiquote.labsdb',
                          'jawikisource.labsdb',
                          'jawikiversity.labsdb',
                          'jawiktionary.labsdb', 'jbowiki.labsdb',
                          'jbowiktionary.labsdb', 'jvwiki.labsdb',
                          'jvwiktionary.labsdb', 'kaawiki.labsdb',
                          'kabwiki.labsdb', 'kawiki.labsdb',
                          'kawikibooks.labsdb', 'kawikiquote.labsdb',
                          'kawiktionary.labsdb', 'kbdwiki.labsdb',
                          'kgwiki.labsdb', 'kiwiki.labsdb',
                          'kjwiki.labsdb', 'kkwiki.labsdb',
                          'kkwikibooks.labsdb', 'kkwikiquote.labsdb',
                          'kkwiktionary.labsdb', 'klwiki.labsdb',
                          'klwiktionary.labsdb', 'kmwiki.labsdb',
                          'kmwikibooks.labsdb', 'kmwiktionary.labsdb',
                          'knwiki.labsdb', 'knwikibooks.labsdb',
                          'knwikiquote.labsdb', 'knwikisource.labsdb',
                          'knwiktionary.labsdb', 'koiwiki.labsdb',
                          'kowikibooks.labsdb', 'kowikinews.labsdb',
                          'kowikiquote.labsdb', 'kowikisource.labsdb',
                          'kowikiversity.labsdb',
                          'kowiktionary.labsdb', 'krcwiki.labsdb',
                          'krwiki.labsdb', 'krwikiquote.labsdb',
                          'kshwiki.labsdb', 'kswiki.labsdb',
                          'kswikibooks.labsdb', 'kswikiquote.labsdb',
                          'kswiktionary.labsdb', 'kuwiki.labsdb',
                          'kuwikibooks.labsdb', 'kuwikiquote.labsdb',
                          'kuwiktionary.labsdb', 'kvwiki.labsdb',
                          'kwwiki.labsdb', 'kwwikiquote.labsdb',
                          'kwwiktionary.labsdb', 'kywiki.labsdb',
                          'kywikibooks.labsdb', 'kywikiquote.labsdb',
                          'kywiktionary.labsdb', 'ladwiki.labsdb',
                          'lawiki.labsdb', 'lawikibooks.labsdb',
                          'lawikiquote.labsdb', 'lawikisource.labsdb',
                          'lawiktionary.labsdb', 'lbewiki.labsdb',
                          'lbwiki.labsdb', 'lbwikibooks.labsdb',
                          'lbwikiquote.labsdb', 'lbwiktionary.labsdb',
                          'lezwiki.labsdb', 'lgwiki.labsdb',
                          'lijwiki.labsdb', 'liwiki.labsdb',
                          'liwikibooks.labsdb', 'liwikiquote.labsdb',
                          'liwikisource.labsdb',
                          'liwiktionary.labsdb', 'lmowiki.labsdb',
                          'lnwiki.labsdb', 'lnwikibooks.labsdb',
                          'lnwiktionary.labsdb', 'loginwiki.labsdb',
                          'lowiki.labsdb', 'lowiktionary.labsdb',
                          'ltgwiki.labsdb', 'ltwiki.labsdb',
                          'ltwikibooks.labsdb', 'ltwikiquote.labsdb',
                          'ltwikisource.labsdb',
                          'ltwiktionary.labsdb', 'lvwiki.labsdb',
                          'lvwikibooks.labsdb', 'lvwiktionary.labsdb',
                          'map_bmswiki.labsdb', 'mdfwiki.labsdb',
                          'mediawikiwiki.labsdb', 'mgwiki.labsdb',
                          'mgwikibooks.labsdb', 'mgwiktionary.labsdb',
                          'mhrwiki.labsdb', 'mhwiki.labsdb',
                          'mhwiktionary.labsdb', 'minwiki.labsdb',
                          'miwiki.labsdb', 'miwikibooks.labsdb',
                          'miwiktionary.labsdb', 'mkwiki.labsdb',
                          'mkwikibooks.labsdb', 'mkwikimedia.labsdb',
                          'mkwikisource.labsdb',
                          'mkwiktionary.labsdb', 'mlwiki.labsdb',
                          'mlwikibooks.labsdb', 'mlwikiquote.labsdb',
                          'mlwikisource.labsdb',
                          'mlwiktionary.labsdb', 'mnwiki.labsdb',
                          'mnwikibooks.labsdb', 'mnwiktionary.labsdb',
                          'mowiki.labsdb', 'mowiktionary.labsdb',
                          'mrjwiki.labsdb', 'mrwiki.labsdb',
                          'mrwikibooks.labsdb', 'mrwikiquote.labsdb',
                          'mrwikisource.labsdb',
                          'mrwiktionary.labsdb', 'mswiki.labsdb',
                          'mswikibooks.labsdb', 'mswiktionary.labsdb',
                          'mtwiki.labsdb', 'mtwiktionary.labsdb',
                          'muswiki.labsdb', 'mwlwiki.labsdb',
                          'mxwikimedia.labsdb', 'myvwiki.labsdb',
                          'mywiki.labsdb', 'mywikibooks.labsdb',
                          'mywiktionary.labsdb', 'mznwiki.labsdb',
                          'nahwiki.labsdb', 'nahwikibooks.labsdb',
                          'nahwiktionary.labsdb', 'napwiki.labsdb',
                          'nawiki.labsdb', 'nawikibooks.labsdb',
                          'nawikiquote.labsdb', 'nawiktionary.labsdb',
                          'nds_nlwiki.labsdb', 'ndswiki.labsdb',
                          'ndswikibooks.labsdb',
                          'ndswikiquote.labsdb',
                          'ndswiktionary.labsdb', 'newiki.labsdb',
                          'newikibooks.labsdb', 'newiktionary.labsdb',
                          'newwiki.labsdb', 'ngwiki.labsdb',
                          'nlwikibooks.labsdb', 'nlwikimedia.labsdb',
                          'nlwikinews.labsdb', 'nlwikiquote.labsdb',
                          'nlwikisource.labsdb',
                          'nlwikivoyage.labsdb',
                          'nlwiktionary.labsdb', 'nnwiki.labsdb',
                          'nnwikiquote.labsdb', 'nnwiktionary.labsdb',
                          'nostalgiawiki.labsdb', 'novwiki.labsdb',
                          'nowikibooks.labsdb', 'nowikimedia.labsdb',
                          'nowikinews.labsdb', 'nowikiquote.labsdb',
                          'nowikisource.labsdb',
                          'nowiktionary.labsdb', 'nrmwiki.labsdb',
                          'nsowiki.labsdb', 'nvwiki.labsdb',
                          'nycwikimedia.labsdb', 'nywiki.labsdb',
                          'nzwikimedia.labsdb', 'ocwiki.labsdb',
                          'ocwikibooks.labsdb', 'ocwiktionary.labsdb',
                          'omwiki.labsdb', 'omwiktionary.labsdb',
                          'orwiki.labsdb', 'orwiktionary.labsdb',
                          'oswiki.labsdb', 'outreachwiki.labsdb',
                          'pa_uswikimedia.labsdb', 'pagwiki.labsdb',
                          'pamwiki.labsdb', 'papwiki.labsdb',
                          'pawiki.labsdb', 'pawikibooks.labsdb',
                          'pawiktionary.labsdb', 'pcdwiki.labsdb',
                          'pdcwiki.labsdb', 'pflwiki.labsdb',
                          'pihwiki.labsdb', 'piwiki.labsdb',
                          'piwiktionary.labsdb', 'plwikibooks.labsdb',
                          'plwikimedia.labsdb', 'plwikinews.labsdb',
                          'plwikiquote.labsdb', 'plwikisource.labsdb',
                          'plwikivoyage.labsdb',
                          'plwiktionary.labsdb', 'pmswiki.labsdb',
                          'pnbwiki.labsdb', 'pnbwiktionary.labsdb',
                          'pntwiki.labsdb', 'pswiki.labsdb',
                          'pswikibooks.labsdb', 'pswiktionary.labsdb',
                          'ptwikibooks.labsdb', 'ptwikinews.labsdb',
                          'ptwikiquote.labsdb', 'ptwikisource.labsdb',
                          'ptwikiversity.labsdb',
                          'ptwikivoyage.labsdb',
                          'ptwiktionary.labsdb', 'qualitywiki.labsdb',
                          'quwiki.labsdb', 'quwikibooks.labsdb',
                          'quwikiquote.labsdb', 'quwiktionary.labsdb',
                          'rmwiki.labsdb', 'rmwikibooks.labsdb',
                          'rmwiktionary.labsdb', 'rmywiki.labsdb',
                          'rnwiki.labsdb', 'rnwiktionary.labsdb',
                          'roa_rupwiki.labsdb',
                          'roa_rupwiktionary.labsdb',
                          'roa_tarawiki.labsdb', 'rowikibooks.labsdb',
                          'rowikinews.labsdb', 'rowikiquote.labsdb',
                          'rowikisource.labsdb',
                          'rowikivoyage.labsdb',
                          'rowiktionary.labsdb', 'rswikimedia.labsdb',
                          'ruewiki.labsdb', 'ruwikibooks.labsdb',
                          'ruwikimedia.labsdb', 'ruwikinews.labsdb',
                          'ruwikiquote.labsdb', 'ruwikisource.labsdb',
                          'ruwikiversity.labsdb',
                          'ruwikivoyage.labsdb',
                          'ruwiktionary.labsdb', 'rwwiki.labsdb',
                          'rwwiktionary.labsdb', 'sahwiki.labsdb',
                          'sahwikisource.labsdb', 'sawiki.labsdb',
                          'sawikibooks.labsdb', 'sawikiquote.labsdb',
                          'sawikisource.labsdb',
                          'sawiktionary.labsdb', 'scnwiki.labsdb',
                          'scnwiktionary.labsdb', 'scowiki.labsdb',
                          'scwiki.labsdb', 'scwiktionary.labsdb',
                          'sdwiki.labsdb', 'sdwikinews.labsdb',
                          'sdwiktionary.labsdb', 'sewiki.labsdb',
                          'sewikibooks.labsdb', 'sewikimedia.labsdb',
                          'sgwiki.labsdb', 'sgwiktionary.labsdb',
                          'shwiki.labsdb', 'shwiktionary.labsdb',
                          'simplewiki.labsdb',
                          'simplewikibooks.labsdb',
                          'simplewikiquote.labsdb',
                          'simplewiktionary.labsdb', 'siwiki.labsdb',
                          'siwikibooks.labsdb', 'siwiktionary.labsdb',
                          'skwiki.labsdb', 'skwikibooks.labsdb',
                          'skwikiquote.labsdb', 'skwikisource.labsdb',
                          'skwiktionary.labsdb', 'slwiki.labsdb',
                          'slwikibooks.labsdb', 'slwikiquote.labsdb',
                          'slwikisource.labsdb',
                          'slwikiversity.labsdb',
                          'slwiktionary.labsdb', 'smwiki.labsdb',
                          'smwiktionary.labsdb', 'snwiki.labsdb',
                          'snwiktionary.labsdb', 'sourceswiki.labsdb',
                          'sowiki.labsdb', 'sowiktionary.labsdb',
                          'specieswiki.labsdb', 'sqwiki.labsdb',
                          'sqwikibooks.labsdb', 'sqwikinews.labsdb',
                          'sqwikiquote.labsdb', 'sqwiktionary.labsdb',
                          'srnwiki.labsdb', 'srwiki.labsdb',
                          'srwikibooks.labsdb', 'srwikinews.labsdb',
                          'srwikiquote.labsdb', 'srwikisource.labsdb',
                          'srwiktionary.labsdb', 'sswiki.labsdb',
                          'sswiktionary.labsdb', 'stqwiki.labsdb',
                          'strategywiki.labsdb', 'stwiki.labsdb',
                          'stwiktionary.labsdb', 'suwiki.labsdb',
                          'suwikibooks.labsdb', 'suwikiquote.labsdb',
                          'suwiktionary.labsdb', 'svwikibooks.labsdb',
                          'svwikinews.labsdb', 'svwikiquote.labsdb',
                          'svwikisource.labsdb',
                          'svwikiversity.labsdb',
                          'svwikivoyage.labsdb',
                          'svwiktionary.labsdb', 'swwiki.labsdb',
                          'swwikibooks.labsdb', 'swwiktionary.labsdb',
                          'szlwiki.labsdb', 'tawiki.labsdb',
                          'tawikibooks.labsdb', 'tawikinews.labsdb',
                          'tawikiquote.labsdb', 'tawikisource.labsdb',
                          'tawiktionary.labsdb', 'tenwiki.labsdb',
                          'test2wiki.labsdb', 'testwiki.labsdb',
                          'testwikidatawiki.labsdb', 'tetwiki.labsdb',
                          'tewiki.labsdb', 'tewikibooks.labsdb',
                          'tewikiquote.labsdb', 'tewikisource.labsdb',
                          'tewiktionary.labsdb', 'tgwiki.labsdb',
                          'tgwikibooks.labsdb', 'tgwiktionary.labsdb',
                          'thwikibooks.labsdb', 'thwikinews.labsdb',
                          'thwikiquote.labsdb', 'thwikisource.labsdb',
                          'thwiktionary.labsdb', 'tiwiki.labsdb',
                          'tiwiktionary.labsdb', 'tkwiki.labsdb',
                          'tkwikibooks.labsdb', 'tkwikiquote.labsdb',
                          'tkwiktionary.labsdb', 'tlwiki.labsdb',
                          'tlwikibooks.labsdb', 'tlwiktionary.labsdb',
                          'tnwiki.labsdb', 'tnwiktionary.labsdb',
                          'towiki.labsdb', 'towiktionary.labsdb',
                          'tpiwiki.labsdb', 'tpiwiktionary.labsdb',
                          'trwikibooks.labsdb', 'trwikimedia.labsdb',
                          'trwikinews.labsdb', 'trwikiquote.labsdb',
                          'trwikisource.labsdb',
                          'trwiktionary.labsdb', 'tswiki.labsdb',
                          'tswiktionary.labsdb', 'ttwiki.labsdb',
                          'ttwikibooks.labsdb', 'ttwikiquote.labsdb',
                          'ttwiktionary.labsdb', 'tumwiki.labsdb',
                          'twwiki.labsdb', 'twwiktionary.labsdb',
                          'tyvwiki.labsdb', 'tywiki.labsdb',
                          'uawikimedia.labsdb', 'udmwiki.labsdb',
                          'ugwiki.labsdb', 'ugwikibooks.labsdb',
                          'ugwikiquote.labsdb', 'ugwiktionary.labsdb',
                          'ukwikibooks.labsdb', 'ukwikimedia.labsdb',
                          'ukwikinews.labsdb', 'ukwikiquote.labsdb',
                          'ukwikisource.labsdb',
                          'ukwikivoyage.labsdb',
                          'ukwiktionary.labsdb', 'urwiki.labsdb',
                          'urwikibooks.labsdb', 'urwikiquote.labsdb',
                          'urwiktionary.labsdb',
                          'usabilitywiki.labsdb', 'uzwiki.labsdb',
                          'uzwikibooks.labsdb', 'uzwikiquote.labsdb',
                          'uzwiktionary.labsdb', 'vecwiki.labsdb',
                          'vecwikisource.labsdb',
                          'vecwiktionary.labsdb', 'vepwiki.labsdb',
                          'vewiki.labsdb', 'vewikimedia.labsdb',
                          'viwikibooks.labsdb', 'viwikiquote.labsdb',
                          'viwikisource.labsdb',
                          'viwikivoyage.labsdb',
                          'viwiktionary.labsdb', 'vlswiki.labsdb',
                          'votewiki.labsdb', 'vowiki.labsdb',
                          'vowikibooks.labsdb', 'vowikiquote.labsdb',
                          'vowiktionary.labsdb', 'warwiki.labsdb',
                          'wawiki.labsdb', 'wawikibooks.labsdb',
                          'wawiktionary.labsdb',
                          'wikimania2005wiki.labsdb',
                          'wikimania2006wiki.labsdb',
                          'wikimania2007wiki.labsdb',
                          'wikimania2008wiki.labsdb',
                          'wikimania2009wiki.labsdb',
                          'wikimania2010wiki.labsdb',
                          'wikimania2011wiki.labsdb',
                          'wikimania2012wiki.labsdb',
                          'wikimania2013wiki.labsdb',
                          'wikimania2014wiki.labsdb', 'wowiki.labsdb',
                          'wowikiquote.labsdb', 'wowiktionary.labsdb',
                          'wuuwiki.labsdb', 'xalwiki.labsdb',
                          'xhwiki.labsdb', 'xhwikibooks.labsdb',
                          'xhwiktionary.labsdb', 'xmfwiki.labsdb',
                          'yiwiki.labsdb', 'yiwikisource.labsdb',
                          'yiwiktionary.labsdb', 'yowiki.labsdb',
                          'yowikibooks.labsdb', 'yowiktionary.labsdb',
                          'zawiki.labsdb', 'zawikibooks.labsdb',
                          'zawikiquote.labsdb', 'zawiktionary.labsdb',
                          'zeawiki.labsdb', 'zh_classicalwiki.labsdb',
                          'zh_min_nanwiki.labsdb',
                          'zh_min_nanwikibooks.labsdb',
                          'zh_min_nanwikiquote.labsdb',
                          'zh_min_nanwikisource.labsdb',
                          'zh_min_nanwiktionary.labsdb',
                          'zh_yuewiki.labsdb', 'zhwikibooks.labsdb',
                          'zhwikinews.labsdb', 'zhwikiquote.labsdb',
                          'zhwikisource.labsdb',
                          'zhwiktionary.labsdb', 'zuwiki.labsdb',
                          'zuwikibooks.labsdb', 'zuwiktionary.labsdb'
                          ];
    }

    host { 's4.labsdb':
        ip => '192.168.99.4',
        host_aliases => [ 'commonswiki.labsdb' ];
    }

    host { 's5.labsdb':
        ip => '192.168.99.5',
        host_aliases => [ 'dewiki.labsdb', 'wikidatawiki.labsdb' ];
    }

    host { 's6.labsdb':
        ip => '192.168.99.6',
        host_aliases => [ 'frwiki.labsdb', 'jawiki.labsdb',
                          'ruwiki.labsdb' ];
    }

    host { 's7.labsdb':
        ip => '192.168.99.7',
        host_aliases => [ 'arwiki.labsdb', 'cawiki.labsdb',
                          'centralauth.labsdb', 'eswiki.labsdb',
                          'fawiki.labsdb', 'frwiktionary.labsdb',
                          'hewiki.labsdb', 'huwiki.labsdb',
                          'kowiki.labsdb', 'metawiki.labsdb',
                          'rowiki.labsdb', 'ukwiki.labsdb',
                          'viwiki.labsdb' ];
    }

    ferm::rule { 'labsdb-client-nat':
        domain => 'ip',
        table => 'nat',
        chain => 'OUTPUT',
        desc => 'Forward connections to DB aliases to actual LabsDB servers',
        rule => 'proto tcp dport 3306 {
            daddr 192.168.99.1/32 DNAT to 10.64.20.12:3306;
            daddr 192.168.99.2/32 DNAT to 10.64.37.4:3306;
            daddr 192.168.99.3/32 DNAT to 10.64.37.5:3306;
            daddr 192.168.99.4/32 DNAT to 10.64.37.4:3307;
            daddr 192.168.99.5/32 DNAT to 10.64.37.4:3308;
            daddr 192.168.99.6/32 DNAT to 10.64.37.5:3307;
            daddr 192.168.99.7/32 DNAT to 10.64.37.5:3308;
        }';
    }
    # FIXME: ferm::rule is a virtual ressource at the moment, so we
    # must probably realize it ourselves?!
    realize Ferm::Rule['labsdb-client-nat]'
}

class role::labsdb::manager {
    package { ["python-mysqldb", "python-yaml"]:
        ensure => present;
    }

    file {
        "/usr/local/sbin/skrillex.py":
            owner => root,
            group => wikidev,
            mode => 0550,
            source => "puppet:///files/mysql/skrillex.py";
        "/etc/skrillex.yaml":
            owner => root,
            group => root,
            mode => 0400,
            content => template('mysql_wmf/skrillex.yaml.erb');
    }
}

class role::db::maintenance {
    include mysql

    package { "percona-toolkit":
        ensure => latest;
    }
}
