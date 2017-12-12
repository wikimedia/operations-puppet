# sets up a planet RSS feed aggregator (planet-venus aka planet 2.0)
#
# $domain_name: domain name used, e.g. wikimedia.org or wmflabs.org
#
# $meta_link: protocol-relative link to a meta or index page for all planets
#
# $http_proxy: since we are on a private IP now we need to proxy to fetch external URLs
#
# $languages: translated strings for the UI in various languages
#                    list all planet languages and translations for index.html.tmpl here.
#                    configurations, directories and cronjobs are auto-created from this hash.
#
class profile::planet::venus (
    $domain_name = hiera('profile::planet::venus::domain_name'),
    $meta_link = hiera('profile::planet::venus::meta_link'),
    $http_proxy = hiera('profile::planet::venus::http_proxy'),
    $languages = {
        ar => {
            'subscribe'     => '&#1575;&#1588;&#1578;&#1585;&#1603;',
            'subscriptions' => '&#1575;&#1604;&#1575;&#1588;&#1578;&#1585;&#1575;&#1603;&#1575;&#1578;',
            'lastupdated'   => '&#1575;&#1582;&#1585; &#1578;&#1581;&#1583;&#1610;&#1579;',
            'alltimesutc'   => '&#1548;&#1603;&#1575;&#1601;&#1577; &#1575;&#1604;&#1571;&#1608;&#1602;&#1575;&#1578; &#1605;&#1576;&#1610;&#1606;&#1577; &#1576;&#1575;&#1604;&#1578;&#1608;&#1602;&#1610;&#1578; &#1575;&#1604;&#1593;&#1575;&#1604;&#1605;&#1610; &#1575;&#1604;&#1605;&#1606;&#1587;&#1602;',
            'poweredby'     => '&#1576;&#1583;&#1593;&#1605; &#1605;&#1606;',
            'wikimedia'     => '&#1608;&#1610;&#1603;&#1610;&#1605;&#1610;&#1583;&#1610;&#1575;',
            'planetarium'   => '&#1576;&#1604;&#1575;&#1606;&#1610;&#1578;&#1575;&#1585;&#1610;&#1608;&#1605;',
        },
        bg => {
            'subscribe'     => '&#1040;&#1073;&#1086;&#1085;&#1080;&#1088;&#1072;&#1085;&#1077;',
            'subscriptions' => '&#1040;&#1073;&#1086;&#1085;&#1072;&#1084;&#1077;&#1085;&#1090;',
            'lastupdated'   => '&#1079;&#1072; &#1087;&#1086;&#1089;&#1083;&#1077;&#1076;&#1085;&#1086; &#1089;&#1072; &#1072;&#1082;&#1090;&#1091;&#1072;&#1083;&#1080;&#1079;&#1080;&#1088;&#1072;&#1085;&#1080;',
            'alltimesutc'   => 'All times are UTC.',
            'poweredby'     => '&#1088;&#1072;&#1073;&#1086;&#1090;&#1080; &#1087;&#1086; &#1089;&#1086;&#1092;&#1090;&#1091;&#1077;&#1088;&#1072; &#1085;&#1072;',
            'wikimedia'     => '&#1059;&#1080;&#1082;&#1080;&#1084;&#1077;&#1076;&#1080;&#1103;',
            'planetarium'   => '&#1087;&#1083;&#1072;&#1085;&#1077;&#1090;&#1072;&#1088;&#1080;&#1081;',
        },
        cs => {
            'subscribe'     => 'P&#345;ihl&#225;sit odb&#283;r',
            'subscriptions' => 'Odb&#283;ry',
            'lastupdated'   => 'Posledn&#237; aktualizace',
            'alltimesutc'   => 'V&#353;echny &#269;asy jsou v UTC.',
            'poweredby'     => 'Provozov&#225;no na',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planet&#225;rium',
        },
        de => {
            'subscribe'     => 'Abonnieren',
            'subscriptions' => 'Teilnehmer',
            'lastupdated'   => 'Zuletzt aktualisiert',
            'alltimesutc'   => 'Alle Zeiten sind UTC.',
            'poweredby'     => 'Betrieben mit',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        el => {
            'subscribe'     => 'Παρακολούθηση',
            'subscriptions' => 'Συνδρομές',
            'lastupdated'   => 'Τελευταία ενημέρωση',
            'alltimesutc'   => 'Όλες οι ώρες είναι UTC.',
            'poweredby'     => 'Υποστηρίζεται από το',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        en => {
            'subscribe'     => 'Subscribe',
            'subscriptions' => 'Subscriptions',
            'lastupdated'   => 'Last updated',
            'alltimesutc'   => 'All times are UTC.',
            'poweredby'     => 'Powered by',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        es => {
            'subscribe'     => 'Suscribirse',
            'subscriptions' => 'Suscripciones',
            'lastupdated'   => '&#218;ltima actualizaci&#243;n',
            'alltimesutc'   => 'Las horas mostradas son en UTC.',
            'poweredby'     => 'Impulsado por',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetario',
        },
        fr => {
            'subscribe'     => 'S\'abonner',
            'subscriptions' => 'Abonnements',
            'lastupdated'   => 'Derni&#232;re mise &#224; jour',
            'alltimesutc'   => 'Les heures sont not&#233;es en UTC (GMT).',
            'poweredby'     => 'Propuls&#233; par',
            'wikimedia'     => 'Wikim&#233;dia',
            'planetarium'   => 'Planetarium',
        },
        gmq => {
            'subscribe'     => 'Abonn&#233;r',
            'subscriptions' => 'Abonnementer',
            'lastupdated'   => 'Senest opdateret',
            'alltimesutc'   => 'Alle tider &#228;r UTC.',
            'poweredby'     => 'Drivs af',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        id => {
            'subscribe'     => 'Berlangganan',
            'subscriptions' => 'Langganan',
            'lastupdated'   => 'Terakhir diperbarui',
            'alltimesutc'   => 'Waktu dalam UTC.',
            'poweredby'     => 'Dimotori oleh',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        it => {
            'subscribe'     => 'Abbonati',
            'subscriptions' => 'Sottoscrizioni',
            'lastupdated'   => 'Last updated',
            'alltimesutc'   => 'Tutti gli orari sono UTC.',
            'poweredby'     => 'Reso possibile da',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        pl => {
            'subscribe'     => 'Subskrybuj',
            'subscriptions' => 'Subskrypcje',
            'lastupdated'   => 'Ostatnia zmiana',
            'alltimesutc'   => 'Wszystkie czasy podane w UTC.',
            'poweredby'     => 'Witryna nap&#281;dzana przez',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        pt => {
            'subscribe'     => 'Subscrever',
            'subscriptions' => 'Subcri&#231;&#245;es',
            'lastupdated'   => '&#218;ltima actualiza&#231;&#227;o',
            'alltimesutc'   => 'Todos os hor&#225;rios est&#227;o em UTC.',
            'poweredby'     => 'Alimentado por',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planet&#225;rio',
        },
        ro => {
            'subscribe'     => 'Abonare',
            'subscriptions' => 'Abon&#259;ri',
            'lastupdated'   => 'Ultima actualizare',
            'alltimesutc'   => 'Toate orele sunt &#238;n UTC.',
            'poweredby'     => 'Motorizat de',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetariu',

        },
        ru => {
            'subscribe'     => '&#1055;&#1086;&#1076;&#1087;&#1080;&#1089;&#1072;&#1090;&#1100;&#1089;&#1103;',
            'subscriptions' => '&#1055;&#1086;&#1076;&#1087;&#1080;&#1089;&#1082;&#1080;',
            'lastupdated'   => '&#1055;&#1086;&#1089;&#1083;&#1077;&#1076;&#1085;&#1077;&#1077; &#1086;&#1073;&#1085;&#1086;&#1074;&#1083;&#1077;&#1085;&#1080;&#1077;',
            'alltimesutc'   => '&#1063;&#1072;&#1089;&#1086;&#1074;&#1086;&#1081; &#1087;&#1086;&#1103;&#1089;: UTC.',
            'poweredby'     => '&#1056;&#1072;&#1073;&#1086;&#1090;&#1072;&#1077;&#1090; &#1085;&#1072;',
            'wikimedia'     => '&#1042;&#1080;&#1082;&#1080;&#1084;&#1077;&#1076;&#1080;&#1072;',
            'planetarium'   => '&#1055;&#1083;&#1072;&#1085;&#1077;&#1090;&#1072;&#1088;&#1080;&#1081;',

        },
        sq => {
            'subscribe'     => 'Abonoj',
            'subscriptions' => 'Abonimet',
            'lastupdated'   => 'Last updated',
            'alltimesutc'   => 'All times are UTC.',
            'poweredby'     => 'Mund&euml;suar nga',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',

        },
        uk => {
            'subscribe'     => '&#1055;&#1110;&#1076;&#1087;&#1080;&#1089;&#1072;&#1090;&#1080;&#1089;&#1103;',
            'subscriptions' => '&#1055;&#1110;&#1076;&#1087;&#1080;&#1089;&#1072;&#1083;&#1080;&#1089;&#1103;',
            'lastupdated'   => '&#1054;&#1073;&#1085;&#1086;&#1074;&#1083;&#1077;&#1085;&#1086;',
            'alltimesutc'   => '&#1042;&#1077;&#1089;&#1100; &#1095;&#1072;&#1089; &#1074; UTC.',
            'poweredby'     => '&#1057;&#1090;&#1074;&#1086;&#1088;&#1077;&#1085;&#1086; &#1079;&#1072; &#1076;&#1086;&#1087;&#1086;&#1084;&#1086;&#1075;&#1086;&#1102;',
            'wikimedia'     => '&#1042;&#1110;&#1082;&#1110;&#1084;&#1077;&#1076;&#1110;&#1072;',
            'planetarium'   => '&#1055;&#1083;&#1072;&#1085;&#1077;&#1090;&#1072;&#1088;&#1110;&#1081;',
        },
        zh => {
            'subscribe'     => '&#35330;&#38321;',
            'subscriptions' => '&#25910;&#37636;',
            'lastupdated'   => '&#26368;&#36817;&#26356;&#26032;',
            'alltimesutc'   => '&#25152;&#26377;&#26178;&#38291;&#20197;UTC&#28858;&#28310;',
            'poweredby'     => 'Powered by',
            'wikimedia'     => '&#32173;&#22522;&#23186;&#39636;',
            'planetarium'   => '&#22825;&#25991;&#39208;',
        },
    }
) {

    class {'::planet':
        domain_name => $domain_name,
        languages   => $languages,
        meta_link   => $meta_link,
        http_proxy  => $http_proxy,
    }

    class {'::httpd':
        modules => ['rewrite', 'headers'],
    }

    ferm::service { 'planet-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }

}
