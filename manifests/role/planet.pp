# planet RSS feed aggregator 2.0 (planet-venus)

class role::planet {

    system::role { 'role::planet': description => 'Planet (venus) weblog aggregator' }

    # be flexible about labs vs. prod
    case $::realm {
        'labs': {
            $planet_domain_name = 'wmflabs.org'
        }
        'production': {
            $planet_domain_name = 'wikimedia.org'
        }
        default: {
            fail('unknown realm, should be labs or production')
        }
    }

    # List all planet languages and translations for
    # index.html.tmpl here. Configurations, directories and
    # cronjobs are auto-created from this hash.
    $planet_languages = {
        ar => {
            'subscribe'     => 'اشترك',
            'subscriptions' => 'الاشتراكات',
            'lastupdated'   => 'اخر تحديث',
            'alltimesutc'   => '،كافة الأوقات مبينة بالتوقيت العالمي المنسق',
            'poweredby'     => 'بدعم من',
            'wikimedia'     => 'ويكيميديا',
            'planetarium'   => 'بلانيتاريوم',
        },
        ca => {
            'subscribe'     => 'Subscriure\'s',
            'subscriptions' => 'Subscripcions',
            'lastupdated'   => 'Última actualització',
            'alltimesutc'   => 'Tots els temps són UTC.',
            'poweredby'     => 'Basat en',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetari',
        },
        cs => {
            'subscribe'     => 'Přihlásit odběr',
            'subscriptions' => 'Odběry',
            'lastupdated'   => 'Poslední aktualizace',
            'alltimesutc'   => 'Všechny časy jsou v UTC.',
            'poweredby'     => 'Provozováno na',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetárium',
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
            'lastupdated'   => 'Última actualización',
            'alltimesutc'   => 'Las horas mostradas son en UTC.',
            'poweredby'     => 'Impulsado por',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetario',
        },
        fr => {
            'subscribe'     => 'S\'abonner',
            'subscriptions' => 'Abonnements',
            'lastupdated'   => 'Dernière mise à jour',
            'alltimesutc'   => 'Les heures sont notées en UTC (GMT).',
            'poweredby'     => 'Propulsé par',
            'wikimedia'     => 'Wikimédia',
            'planetarium'   => 'Planetarium',
        },
        gmq => {
            'subscribe'     => 'Abonnér',
            'subscriptions' => 'Abonnementer',
            'lastupdated'   => 'Senest opdateret',
            'alltimesutc'   => 'Alle tider är UTC.',
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
        ja => {
            'subscribe'     => '購読する',
            'subscriptions' => '登録されているブログ',
            'lastupdated'   => '最終更新日時',
            'alltimesutc'   => '時刻はすべてUTC表記です。',
            'poweredby'     => 'Powered by',
            'wikimedia'     => 'ウィキメディア',
            'planetarium'   => 'プラネタリウム',
        },
        pl => {
            'subscribe'     => 'Subskrybuj',
            'subscriptions' => 'Subskrypcje',
            'lastupdated'   => 'Ostatnia zmiana',
            'alltimesutc'   => 'Wszystkie czasy podane w UTC.',
            'poweredby'     => 'Witryna napędzana przez',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetarium',
        },
        pt => {
            'subscribe'     => 'Subscrever',
            'subscriptions' => 'Subcrições',
            'lastupdated'   => 'Última actualização',
            'alltimesutc'   => 'Todos os horários estão em UTC.',
            'poweredby'     => 'Alimentado por',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetário',
        },
        ro => {
            'subscribe'     => 'Abonare',
            'subscriptions' => 'Abonări',
            'lastupdated'   => 'Ultima actualizare',
            'alltimesutc'   => 'Toate orele sunt în UTC.',
            'poweredby'     => 'Motorizat de',
            'wikimedia'     => 'Wikimedia',
            'planetarium'   => 'Planetariu',

        },
        ru => {
            'subscribe'     => 'Подписаться',
            'subscriptions' => 'Подписки',
            'lastupdated'   => 'Последнее обновление',
            'alltimesutc'   => 'Часовой пояс: UTC.',
            'poweredby'     => 'Работает на',
            'wikimedia'     => 'Викимедиа',
            'planetarium'   => 'Планетарий',

        },
        sr => {
            'subscribe'     => 'Prati',
            'subscriptions' => 'Blogovi',
            'lastupdated'   => 'Poslednje ažurirano',
            'alltimesutc'   => 'Sva vremena su u UTC.',
            'poweredby'     => 'Pokreće',
            'wikimedia'     => 'Vikimedija',
            'planetarium'   => 'Planetarijum',

        },
        uk => {
            'subscribe'     => 'Підписатися',
            'subscriptions' => 'Підписалися',
            'lastupdated'   => 'Обновлено',
            'alltimesutc'   => 'Весь час в UTC.',
            'poweredby'     => 'Створено за допомогою',
            'wikimedia'     => 'Вікімедіа',
            'planetarium'   => 'Планетарій',
        },
        zh => {
            'subscribe'     => '訂閱',
            'subscriptions' => '收錄',
            'lastupdated'   => '最近更新',
            'alltimesutc'   => '所有時間以UTC為準',
            'poweredby'     => 'Powered by',
            'wikimedia'     => '維基媒體',
            'planetarium'   => '天文館',
        },
    }

    # protocol-relative link to a meta or index page for all planets
    $planet_meta_link = "meta.wikimedia.org/wiki/Planet_Wikimedia"

    # the 'planet' class from modules/planet/init.pp does the setup
    class {'::planet':
        planet_domain_name => $planet_domain_name,
        planet_languages   => $planet_languages,
        planet_meta_link   => $planet_meta_link
    }

    ferm::service { 'planet-http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'planet-https':
        proto => 'tcp',
        port  => '443',
    }

}

