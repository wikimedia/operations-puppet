# SPDX-License-Identifier: Apache-2.0
# sets up a planet RSS feed aggregator (planet-rawdog aka planet 3.0)
#
# $domain_name: domain name used, e.g. wikimedia.org or wmflabs.org
#
# $meta_link: https:// link to a meta or index page for all planets
#
# $https_proxy: since we are on a private IP now we need to proxy to fetch external URLs
#
# $languages: translated strings for the UI in various languages
#                    list all planet languages and their translations here.
#                    configurations, directories and systemd timers are auto-created from this hash.
#
class profile::planet (
    String $domain_name = lookup('profile::planet::domain_name'),
    Stdlib::HTTPUrl $meta_link = lookup('profile::planet::meta_link'),
    Stdlib::HTTPUrl $https_proxy = lookup('profile::planet::https_proxy'),
    Wmflib::Ensure $updatejob_ensure = lookup('profile::planet::updatejob_ensure'),
    Hash $languages = {
        ar => {
            'subscribe'     => '&#1575;&#1588;&#1578;&#1585;&#1603;',
            'subscriptions' => '&#1575;&#1604;&#1575;&#1588;&#1578;&#1585;&#1575;&#1603;&#1575;&#1578;',
            'wikimedia'     => '&#1608;&#1610;&#1603;&#1610;&#1605;&#1610;&#1583;&#1610;&#1575;',
            'planetarium'   => '&#1576;&#1604;&#1575;&#1606;&#1610;&#1578;&#1575;&#1585;&#1610;&#1608;&#1605;',
        },
        bg => {
            'subscribe'     => '&#1040;&#1073;&#1086;&#1085;&#1080;&#1088;&#1072;&#1085;&#1077;',
            'subscriptions' => '&#1040;&#1073;&#1086;&#1085;&#1072;&#1084;&#1077;&#1085;&#1090;',
            'wikimedia'     => '&#1059;&#1080;&#1082;&#1080;&#1084;&#1077;&#1076;&#1080;&#1103;',
            'planetarium'   => '&#1087;&#1083;&#1072;&#1085;&#1077;&#1090;&#1072;&#1088;&#1080;&#1081;',
        },
        cs => {
            'subscribe'     => 'P&#345;ihl&#225;sit odb&#283;r',
            'subscriptions' => 'Odb&#283;ry',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planet&#225;rium',
        },
        de => {
            'subscribe'     => 'Abonnieren',
            'subscriptions' => 'Teilnehmer',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        el => {
            'subscribe'     => 'Παρακολούθηση',
            'subscriptions' => 'Συνδρομές',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        en => {
            'subscribe'     => 'Subscribe',
            'subscriptions' => 'Subscriptions',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        es => {
            'subscribe'     => 'Suscribirse',
            'subscriptions' => 'Suscripciones',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetario',
        },
        fr => {
            'subscribe'     => 'S\'abonner',
            'subscriptions' => 'Abonnements',
            'wikimedia'     => 'Wikim&#233;dia',
            'planetarium'   => 'Planetarium',
        },
        gmq => {
            'subscribe'     => 'Abonn&#233;r',
            'subscriptions' => 'Abonnementer',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        id => {
            'subscribe'     => 'Berlangganan',
            'subscriptions' => 'Langganan',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        it => {
            'subscribe'     => 'Abbonati',
            'subscriptions' => 'Sottoscrizioni',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        pl => {
            'subscribe'     => 'Subskrybuj',
            'subscriptions' => 'Subskrypcje',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        pt => {
            'subscribe'     => 'Subscrever',
            'subscriptions' => 'Subscri&#231;&#245;es',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planet&#225;rio',
        },
        ro => {
            'subscribe'     => 'Abonare',
            'subscriptions' => 'Abon&#259;ri',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetariu',

        },
        ru => {
            'subscribe'     => '&#1055;&#1086;&#1076;&#1087;&#1080;&#1089;&#1072;&#1090;&#1100;&#1089;&#1103;',
            'subscriptions' => '&#1055;&#1086;&#1076;&#1087;&#1080;&#1089;&#1082;&#1080;',
            'wikimedia'     => '&#1042;&#1080;&#1082;&#1080;&#1084;&#1077;&#1076;&#1080;&#1072;',
            'planetarium'   => '&#1055;&#1083;&#1072;&#1085;&#1077;&#1090;&#1072;&#1088;&#1080;&#1081;',

        },
        sq => {
            'subscribe'     => 'Abonoj',
            'subscriptions' => 'Abonimet',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',

        },
        uk => {
            'subscribe'     => '&#1055;&#1110;&#1076;&#1087;&#1080;&#1089;&#1072;&#1090;&#1080;&#1089;&#1103;',
            'subscriptions' => '&#1055;&#1110;&#1076;&#1087;&#1080;&#1089;&#1072;&#1083;&#1080;&#1089;&#1103;',
            'wikimedia'     => '&#1042;&#1110;&#1082;&#1110;&#1084;&#1077;&#1076;&#1110;&#1072;',
            'planetarium'   => '&#1055;&#1083;&#1072;&#1085;&#1077;&#1090;&#1072;&#1088;&#1110;&#1081;',
        },
        zh => {
            'subscribe'     => '&#35330;&#38321;',
            'subscriptions' => '&#25910;&#37636;',
            'wikimedia'     => '&#32173;&#22522;&#23186;&#39636;',
            'planetarium'   => '&#22825;&#25991;&#39208;',
        },
    }
) {

    class {'::planet':
        domain_name      => $domain_name,
        languages        => $languages,
        meta_link        => $meta_link,
        https_proxy      => $https_proxy,
        updatejob_ensure => $updatejob_ensure,
    }

    class {'::httpd':
        modules => ['rewrite', 'headers'],
    }

    prometheus::blackbox::check::http { 'en.planet.wikimedia.org':
        team               => 'collaboration-services',
        severity           => 'task',
        path               => '/',
        ip_families        => ['ip4'],
        force_tls          => true,
        body_regex_matches => ['Planetarium'],
    }

}
