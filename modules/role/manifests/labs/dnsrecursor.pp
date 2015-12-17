# Class: role::labs::dnsrecursor
#
# Labs instances can't communicate directly with other instances
#  via floating IP, but they often want to do DNS lookups for the
#  public IP of other instances (e.g. beta.wmflabs.org).
#
# This recursor does two useful things:
#
#  - It maintains a mapping between floating and private IPs
#  for select instances.  Anytime the upstream DNS server returns
#  a public IP in that mapping, we return the corresponding private
#  IP instead.
#
#  - It relays requests for *.wmflabs to the auth server that knows
#  about such things (defined as $labs_forward)
#
#  Other than that it should act like any other WMF recursor.
#
#
# Eventually all labs instances will point to one of these in resolv.conf

class role::labs::dnsrecursor {

    system::role { 'role::labs::dnsrecursor':
        description => 'Recursive DNS server for Labs instances',
    }

    include passwords::openstack::nova
    include ::network::constants
    $all_networks = $::network::constants::all_networks

    $recursor_ip = ipresolve(hiera('labs_recursor'),4)

    interface::ip { 'role::lab::dnsrecursor':
        interface => 'eth0',
        address   => $recursor_ip
    }

    #  We need to alias some public IPs to their corresponding private IPs.
    $wikitech_nova_ldap_user_pass = $::passwords::openstack::nova::nova_ldap_user_pass
    $nova_controller_hostname = hiera('labs_nova_controller')

    $listen_addresses = $::realm ? {
        'labs'  => [$::ipaddress],
        default => [$recursor_ip]
    }

    $labs_auth_dns = ipresolve(hiera('labs_dns_host'),4)

    $lua_hooks = ['/etc/powerdns/labs-ip-alias.lua', '/etc/powerdns/metaldns.lua']

    class { '::dnsrecursor':
            listen_addresses         => $listen_addresses,
            allow_from               => $all_networks,
            additional_forward_zones => "wmflabs=${labs_auth_dns}, 68.10.in-addr.arpa=${labs_auth_dns}",
            auth_zones               => 'labsdb=/var/zones/labsdb',
            lua_hooks                => $lua_hooks,
    }

    $alias_file = '/etc/powerdns/labs-ip-alias.lua'
    class { '::dnsrecursor::labsaliaser':
        username   => 'novaadmin',
        password   => $wikitech_nova_ldap_user_pass,
        projects   => [
            'tools',
            'deployment-prep',
            'toolserver-legacy',
            'project-proxy',
        ],
        nova_api_url => "http://${nova_controller_hostname}:35357/v2.0",
        alias_file   => $alias_file,
    }
    require dnsrecursor::metalresolver

    # There are three replica servers (c1, c2, c3).  The mapping of
    # "shards" (s1, etc.) and databases (enwiki, etc.) to these is
    # arbitrary and can be adjusted to depool a server or redistribute
    # load.
    $c1_dbs = ['c1', 's1', 'enwiki']
    $c2_dbs = ['c2', 's2', 's4', 's5', 'bgwiki', 'bgwiktionary',
        'commonswiki', 'cswiki', 'dewiki', 'enwikiquote',
        'enwiktionary', 'eowiki', 'fiwiki', 'idwiki', 'itwiki',
        'nlwiki', 'nowiki', 'plwiki', 'ptwiki', 'svwiki', 'thwiki',
        'trwiki', 'wikidatawiki', 'zhwiki']
    $c3_dbs = ['c3', 's3', 's6', 's7', 'aawiki', 'aawikibooks',
        'aawiktionary', 'abwiki', 'abwiktionary', 'acewiki',
        'advisorywiki', 'afwiki', 'afwikibooks', 'afwikiquote',
        'afwiktionary', 'akwiki', 'akwikibooks', 'akwiktionary',
        'alswiki', 'alswikibooks', 'alswikiquote', 'alswiktionary',
        'amwiki', 'amwikiquote', 'amwiktionary', 'angwiki',
        'angwikibooks', 'angwikiquote', 'angwikisource',
        'angwiktionary', 'anwiki', 'anwiktionary', 'arcwiki',
        'arwiki', 'arwikibooks', 'arwikimedia', 'arwikinews',
        'arwikiquote', 'arwikisource', 'arwikiversity',
        'arwiktionary', 'arzwiki', 'astwiki', 'astwikibooks',
        'astwikiquote', 'astwiktionary', 'aswiki', 'aswikibooks',
        'aswikisource', 'aswiktionary', 'avwiki', 'avwiktionary',
        'aywiki', 'aywikibooks', 'aywiktionary', 'azwiki', 'azbwiki',
        'azwikibooks', 'azwikiquote', 'azwikisource', 'azwiktionary',
        'barwiki', 'bat_smgwiki', 'bawiki', 'bawikibooks', 'bclwiki',
        'bdwikimedia', 'be_x_oldwiki', 'betawikiversity', 'bewiki',
        'bewikibooks', 'bewikimedia', 'bewikiquote', 'bewikisource',
        'bewiktionary', 'bgwikibooks', 'bgwikinews', 'bgwikiquote',
        'bgwikisource', 'bhwiki', 'bhwiktionary', 'biwiki',
        'biwikibooks', 'biwiktionary', 'bjnwiki', 'bmwiki',
        'bmwikibooks', 'bmwikiquote', 'bmwiktionary', 'bnwiki',
        'bnwikibooks', 'bnwikisource', 'bnwiktionary', 'bowiki',
        'bowikibooks', 'bowiktionary', 'bpywiki', 'brwiki',
        'brwikimedia', 'brwikiquote', 'brwikisource', 'brwiktionary',
        'bswiki', 'bswikibooks', 'bswikinews', 'bswikiquote',
        'bswikisource', 'bswiktionary', 'bugwiki', 'bxrwiki',
        'cawiki', 'cawikibooks', 'cawikimedia', 'cawikinews',
        'cawikiquote', 'cawikisource', 'cawiktionary', 'cbk_zamwiki',
        'cdowiki', 'cebwiki', 'centralauth', 'cewiki', 'chowiki',
        'chrwiki', 'chrwiktionary', 'chwiki', 'chwikibooks',
        'chwiktionary', 'chywiki', 'ckbwiki', 'cnwikimedia', 'cowiki',
        'cowikibooks', 'cowikimedia', 'cowikiquote', 'cowiktionary', 'crhwiki',
        'crwiki', 'crwikiquote', 'crwiktionary', 'csbwiki',
        'csbwiktionary', 'cswikibooks', 'cswikinews', 'cswikiquote',
        'cswikisource', 'cswikiversity', 'cswiktionary', 'cuwiki',
        'cvwiki', 'cvwikibooks', 'cywiki', 'cywikibooks',
        'cywikiquote', 'cywikisource', 'cywiktionary', 'dawiki',
        'dawikibooks', 'dawikiquote', 'dawikisource', 'dawiktionary',
        'dewikibooks', 'dewikinews', 'dewikiquote', 'dewikisource',
        'dewikiversity', 'dewikivoyage', 'dewiktionary', 'diqwiki',
        'dkwikimedia', 'donatewiki', 'dsbwiki', 'dvwiki',
        'dvwiktionary', 'dzwiki', 'dzwiktionary', 'eewiki', 'elwiki',
        'elwikibooks', 'elwikinews', 'elwikiquote', 'elwikisource',
        'elwikiversity', 'elwikivoyage', 'elwiktionary', 'emlwiki',
        'enwikibooks', 'enwikinews', 'enwikisource', 'enwikiversity',
        'enwikivoyage', 'eowikibooks', 'eowikinews', 'eowikiquote',
        'eowikisource', 'eowiktionary', 'eswiki', 'eswikibooks',
        'eswikinews', 'eswikiquote', 'eswikisource', 'eswikiversity',
        'eswikivoyage', 'eswiktionary', 'etwiki', 'etwikibooks',
        'etwikimedia', 'etwikiquote', 'etwikisource', 'etwiktionary',
        'euwiki', 'euwikibooks', 'euwikiquote', 'euwiktionary',
        'extwiki', 'fawiki', 'fawikibooks', 'fawikinews',
        'fawikiquote', 'fawikisource', 'fawikivoyage', 'fawiktionary',
        'ffwiki', 'fiu_vrowiki', 'fiwikibooks', 'fiwikimedia',
        'fiwikinews', 'fiwikiquote', 'fiwikisource', 'fiwikiversity',
        'fiwiktionary', 'fjwiki', 'fjwiktionary', 'foundationwiki',
        'fowiki', 'fowikisource', 'fowiktionary', 'frpwiki',
        'frrwiki', 'frwiki', 'frwikibooks', 'frwikinews',
        'frwikiquote', 'frwikisource', 'frwikiversity',
        'frwikivoyage', 'frwiktionary', 'furwiki', 'fywiki',
        'fywikibooks', 'fywiktionary', 'gagwiki', 'ganwiki', 'gawiki',
        'gawikibooks', 'gawikiquote', 'gawiktionary', 'gdwiki',
        'gdwiktionary', 'glkwiki', 'glwiki', 'glwikibooks',
        'glwikiquote', 'glwikisource', 'glwiktionary', 'gnwiki',
        'gnwikibooks', 'gnwiktionary', 'gomwiki', 'gotwiki', 'gotwikibooks',
        'guwiki', 'guwikibooks', 'guwikiquote', 'guwikisource',
        'guwiktionary', 'gvwiki', 'gvwiktionary', 'hakwiki', 'hawiki',
        'hawiktionary', 'hawwiki', 'hewiki', 'hewikibooks',
        'hewikinews', 'hewikiquote', 'hewikisource', 'hewikivoyage',
        'hewiktionary', 'hifwiki', 'hiwiki', 'hiwikibooks',
        'hiwikiquote', 'hiwiktionary', 'howiki', 'hrwiki',
        'hrwikibooks', 'hrwikiquote', 'hrwikisource', 'hrwiktionary',
        'hsbwiki', 'hsbwiktionary', 'htwiki', 'htwikisource',
        'huwiki', 'huwikibooks', 'huwikinews', 'huwikiquote',
        'huwikisource', 'huwiktionary', 'hywiki', 'hywikibooks',
        'hywikiquote', 'hywikisource', 'hywiktionary', 'hzwiki',
        'iawiki', 'iawikibooks', 'iawiktionary', 'idwikibooks',
        'idwikiquote', 'idwikisource', 'idwiktionary', 'iewiki',
        'iewikibooks', 'iewiktionary', 'igwiki', 'iiwiki', 'ikwiki',
        'ikwiktionary', 'ilowiki', 'incubatorwiki', 'iowiki',
        'iowiktionary', 'iswiki', 'iswikibooks', 'iswikiquote',
        'iswikisource', 'iswiktionary', 'itwikibooks', 'itwikinews',
        'itwikiquote', 'itwikisource', 'itwikiversity',
        'itwikivoyage', 'itwiktionary', 'iuwiki', 'iuwiktionary',
        'jawiki', 'jawikibooks', 'jawikinews', 'jawikiquote',
        'jawikisource', 'jawikiversity', 'jawiktionary', 'jbowiki',
        'jbowiktionary', 'jvwiki', 'jvwiktionary', 'kaawiki',
        'kabwiki', 'kawiki', 'kawikibooks', 'kawikiquote',
        'kawiktionary', 'kbdwiki', 'kgwiki', 'kiwiki', 'kjwiki',
        'kkwiki', 'kkwikibooks', 'kkwikiquote', 'kkwiktionary',
        'klwiki', 'klwiktionary', 'kmwiki', 'kmwikibooks',
        'kmwiktionary', 'knwiki', 'knwikibooks', 'knwikiquote',
        'knwikisource', 'knwiktionary', 'koiwiki', 'kowiki',
        'kowikibooks', 'kowikinews', 'kowikiquote', 'kowikisource',
        'kowikiversity', 'kowiktionary', 'krcwiki', 'krwiki',
        'krwikiquote', 'kshwiki', 'kswiki', 'kswikibooks',
        'kswikiquote', 'kswiktionary', 'kuwiki', 'kuwikibooks',
        'kuwikiquote', 'kuwiktionary', 'kvwiki', 'kwwiki',
        'kwwikiquote', 'kwwiktionary', 'kywiki', 'kywikibooks',
        'kywikiquote', 'kywiktionary', 'ladwiki', 'lawiki',
        'lawikibooks', 'lawikiquote', 'lawikisource', 'lawiktionary',
        'lbewiki', 'lbwiki', 'lbwikibooks', 'lbwikiquote',
        'lbwiktionary', 'lezwiki', 'lgwiki', 'lijwiki', 'liwiki',
        'liwikibooks', 'liwikiquote', 'liwikisource', 'liwiktionary',
        'lmowiki', 'lnwiki', 'lnwikibooks', 'lnwiktionary',
        'loginwiki', 'lowiki', 'lowiktionary', 'lrcwiki', 'ltgwiki', 'ltwiki',
        'ltwikibooks', 'ltwikiquote', 'ltwikisource', 'ltwiktionary',
        'lvwiki', 'lvwikibooks', 'lvwiktionary', 'maiwiki',
        'map_bmswiki', 'mdfwiki', 'mediawikiwiki', 'metawiki',
        'mgwiki', 'mgwikibooks', 'mgwiktionary', 'mhrwiki', 'mhwiki',
        'mhwiktionary', 'minwiki', 'miwiki', 'miwikibooks',
        'miwiktionary', 'mkwiki', 'mkwikibooks', 'mkwikimedia',
        'mkwikisource', 'mkwiktionary', 'mlwiki', 'mlwikibooks',
        'mlwikiquote', 'mlwikisource', 'mlwiktionary', 'mnwiki',
        'mnwikibooks', 'mnwiktionary', 'mowiki', 'mowiktionary',
        'mrjwiki', 'mrwiki', 'mrwikibooks', 'mrwikiquote',
        'mrwikisource', 'mrwiktionary', 'mswiki', 'mswikibooks',
        'mswiktionary', 'mtwiki', 'mtwiktionary', 'muswiki',
        'mwlwiki', 'mxwikimedia', 'myvwiki', 'mywiki', 'mywikibooks',
        'mywiktionary', 'mznwiki', 'nahwiki', 'nahwikibooks',
        'nahwiktionary', 'napwiki', 'nawiki', 'nawikibooks',
        'nawikiquote', 'nawiktionary', 'nds_nlwiki', 'ndswiki',
        'ndswikibooks', 'ndswikiquote', 'ndswiktionary', 'newiki',
        'newikibooks', 'newiktionary', 'newwiki', 'ngwiki',
        'nlwikibooks', 'nlwikimedia', 'nlwikinews', 'nlwikiquote',
        'nlwikisource', 'nlwikivoyage', 'nlwiktionary', 'nnwiki',
        'nnwikiquote', 'nnwiktionary', 'nostalgiawiki', 'novwiki',
        'nowikibooks', 'nowikimedia', 'nowikinews', 'nowikiquote',
        'nowikisource', 'nowiktionary', 'nrmwiki', 'nsowiki',
        'nvwiki', 'nycwikimedia', 'nywiki', 'nzwikimedia', 'ocwiki',
        'ocwikibooks', 'ocwiktionary', 'omwiki', 'omwiktionary',
        'orwiki', 'orwikisource', 'orwiktionary', 'oswiki',
        'outreachwiki', 'pa_uswikimedia', 'pagwiki', 'pamwiki',
        'papwiki', 'pawiki', 'pawikibooks', 'pawiktionary', 'pcdwiki',
        'pdcwiki', 'pflwiki', 'pihwiki', 'piwiki', 'piwiktionary',
        'plwikibooks', 'plwikimedia', 'plwikinews', 'plwikiquote',
        'plwikisource', 'plwikivoyage', 'plwiktionary', 'pmswiki',
        'pnbwiki', 'pnbwiktionary', 'pntwiki', 'pswiki',
        'pswikibooks', 'pswiktionary', 'ptwikibooks', 'ptwikinews',
        'ptwikiquote', 'ptwikisource', 'ptwikiversity',
        'ptwikivoyage', 'ptwiktionary', 'qualitywiki', 'quwiki',
        'quwikibooks', 'quwikiquote', 'quwiktionary', 'rmwiki',
        'rmwikibooks', 'rmwiktionary', 'rmywiki', 'rnwiki',
        'rnwiktionary', 'roa_rupwiki', 'roa_rupwiktionary',
        'roa_tarawiki', 'rowiki', 'rowikibooks', 'rowikinews',
        'rowikiquote', 'rowikisource', 'rowikivoyage', 'rowiktionary',
        'rswikimedia', 'ruewiki', 'ruwiki', 'ruwikibooks',
        'ruwikimedia', 'ruwikinews', 'ruwikiquote', 'ruwikisource',
        'ruwikiversity', 'ruwikivoyage', 'ruwiktionary', 'rwwiki',
        'rwwiktionary', 'sahwiki', 'sahwikisource', 'sawiki',
        'sawikibooks', 'sawikiquote', 'sawikisource', 'sawiktionary',
        'scnwiki', 'scnwiktionary', 'scowiki', 'scwiki',
        'scwiktionary', 'sdwiki', 'sdwikinews', 'sdwiktionary',
        'sewiki', 'sewikibooks', 'sewikimedia', 'sgwiki',
        'sgwiktionary', 'shwiki', 'shwiktionary', 'simplewiki',
        'simplewikibooks', 'simplewikiquote', 'simplewiktionary',
        'siwiki', 'siwikibooks', 'siwiktionary', 'skwiki',
        'skwikibooks', 'skwikiquote', 'skwikisource', 'skwiktionary',
        'slwiki', 'slwikibooks', 'slwikiquote', 'slwikisource',
        'slwikiversity', 'slwiktionary', 'smwiki', 'smwiktionary',
        'snwiki', 'snwiktionary', 'sourceswiki', 'sowiki',
        'sowiktionary', 'specieswiki', 'sqwiki', 'sqwikibooks',
        'sqwikinews', 'sqwikiquote', 'sqwiktionary', 'srnwiki',
        'srwiki', 'srwikibooks', 'srwikinews', 'srwikiquote',
        'srwikisource', 'srwiktionary', 'sswiki', 'sswiktionary',
        'stqwiki', 'strategywiki', 'stwiki', 'stwiktionary', 'suwiki',
        'suwikibooks', 'suwikiquote', 'suwiktionary', 'svwikibooks',
        'svwikinews', 'svwikiquote', 'svwikisource', 'svwikiversity',
        'svwikivoyage', 'svwiktionary', 'swwiki', 'swwikibooks',
        'swwiktionary', 'szlwiki', 'tawiki', 'tawikibooks',
        'tawikinews', 'tawikiquote', 'tawikisource', 'tawiktionary',
        'tenwiki', 'test2wiki', 'testwiki', 'testwikidatawiki',
        'tetwiki', 'tewiki', 'tewikibooks', 'tewikiquote',
        'tewikisource', 'tewiktionary', 'tgwiki', 'tgwikibooks',
        'tgwiktionary', 'thwikibooks', 'thwikinews', 'thwikiquote',
        'thwikisource', 'thwiktionary', 'tiwiki', 'tiwiktionary',
        'tkwiki', 'tkwikibooks', 'tkwikiquote', 'tkwiktionary',
        'tlwiki', 'tlwikibooks', 'tlwiktionary', 'tnwiki',
        'tnwiktionary', 'towiki', 'towiktionary', 'tpiwiki',
        'tpiwiktionary', 'trwikibooks', 'trwikimedia', 'trwikinews',
        'trwikiquote', 'trwikisource', 'trwiktionary', 'tswiki',
        'tswiktionary', 'ttwiki', 'ttwikibooks', 'ttwikiquote',
        'ttwiktionary', 'tumwiki', 'twwiki', 'twwiktionary',
        'tyvwiki', 'tywiki', 'uawikimedia', 'udmwiki', 'ugwiki',
        'ugwikibooks', 'ugwikiquote', 'ugwiktionary', 'ukwiki',
        'ukwikibooks', 'ukwikimedia', 'ukwikinews', 'ukwikiquote',
        'ukwikisource', 'ukwikivoyage', 'ukwiktionary', 'urwiki',
        'urwikibooks', 'urwikiquote', 'urwiktionary', 'usabilitywiki',
        'uzwiki', 'uzwikibooks', 'uzwikiquote', 'uzwiktionary',
        'vecwiki', 'vecwikisource', 'vecwiktionary', 'vepwiki',
        'vewiki', 'vewikimedia', 'viwiki', 'viwikibooks',
        'viwikiquote', 'viwikisource', 'viwikivoyage', 'viwiktionary',
        'vlswiki', 'votewiki', 'vowiki', 'vowikibooks', 'vowikiquote',
        'vowiktionary', 'warwiki', 'wawiki', 'wawikibooks',
        'wawiktionary', 'wikimania2005wiki', 'wikimania2006wiki',
        'wikimania2007wiki', 'wikimania2008wiki', 'wikimania2009wiki',
        'wikimania2010wiki', 'wikimania2011wiki', 'wikimania2012wiki',
        'wikimania2013wiki', 'wikimania2014wiki', 'wikimania2015wiki',
        'wikimania2016wiki', 'wowiki', 'wowikiquote', 'wowiktionary',
        'wuuwiki', 'xalwiki', 'xhwiki', 'xhwikibooks', 'xhwiktionary',
        'xmfwiki', 'yiwiki', 'yiwikisource', 'yiwiktionary', 'yowiki',
        'yowikibooks', 'yowiktionary', 'zawiki', 'zawikibooks', 'zawikiquote',
        'zawiktionary', 'zeawiki', 'zh_classicalwiki', 'zh_min_nanwiki',
        'zh_min_nanwikibooks', 'zh_min_nanwikiquote', 'zh_min_nanwikisource',
        'zh_min_nanwiktionary', 'zh_yuewiki', 'zhwikibooks', 'zhwikinews',
        'zhwikiquote', 'zhwikisource', 'zhwikivoyage', 'zhwiktionary',
        'zuwiki', 'zuwikibooks', 'zuwiktionary']

    file { '/var/zones':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444'
    }

    file { '/var/zones/labsdb':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['pdns-recursor'],
        content => template('role/labs/dns/db_aliases.erb'),
        require => File['/var/zones']
    }

    ::dnsrecursor::monitor { $listen_addresses: }

    ferm::service { 'recursor_udp_dns_rec':
        proto => 'udp',
        port  => '53',
    }

    ferm::service { 'recursor_tcp_dns_rec':
        proto => 'tcp',
        port  => '53',
    }

    ferm::rule { 'recursor_skip_dns_conntrack-out':
        desc  => 'Skip DNS outgoing connection tracking',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => 'proto udp sport 53 NOTRACK;',
    }

    ferm::rule { 'recursor_skip_dns_conntrack-in':
        desc  => 'Skip DNS incoming connection tracking',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'proto udp dport 53 NOTRACK;',
    }
}
