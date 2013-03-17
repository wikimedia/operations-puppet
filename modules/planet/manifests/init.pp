# planet RSS feed aggregator 2.0 (planet-venus)

class planet {

  system_role { 'planet': description => 'Planet (venus) weblog aggregator' }

  # locales are essential for planet. if a new language is added check these too
  generic::locales::international

  # be flexible about labs vs. prod
  case $::realm {
    labs: {
      $planet_domain_name = 'wmflabs.org'
    }
    production: {
      $planet_domain_name = 'wikimedia.org'
    }
    default: {
      fail('unknown realm, should be labs or production')
    }
  }

  # webserver setup
  install_certificate{ "star.planet.${planet_domain_name}": }
  class {'webserver::php5': ssl => 'true'; }
  apache_module { rewrite: name => "rewrite" }

  # dependencies
  Class['webserver::php5'] -> apache_module['rewrite'] -> Install_certificate["star.planet.${planet_domain_name}"]

  # List all planet languages and translations for
  # index.html.tmpl here.  Configurations, directories and
  # cronjobs are auto-created from this hash.
  $planet_languages = {
    ar => {
      'subscribe'     => 'اشترك',
      'subscriptions' => 'الاشتراكات',
      'lastupdated'   => 'اخر تحديث',
    },
    ca => {
      'subscribe'     => 'Subscriure\'s',
      'subscriptions' => 'Subscripcions',
      'lastupdated'   => 'Última actualització',
    },
    cs => {
      'subscribe'     => 'Přihlásit odběr',
      'subscriptions' => 'Odběry',
      'lastupdated'   => 'Poslední aktualizace',
    },
    de => {
      'subscribe'     => 'Abonnieren',
      'subscriptions' => 'Teilnehmer',
      'lastupdated'   => 'Zuletzt aktualisiert',
    },
    en => {
      'subscribe'     => 'Subscribe',
      'subscriptions' => 'Subscriptions',
      'lastupdated'   => 'Last updated',
    },
    es => {
      'subscribe'     => 'Suscribirse',
      'subscriptions' => 'Suscripciones',
      'lastupdated'   => 'Última actualización',
    },
    fr => {
      'subscribe'     => 'S\'abonner',
      'subscriptions' => 'Abonnements',
      'lastupdated'   => 'Dernière mise à jour',
    },
    gmq => {
      'subscribe'     => 'Abonnér',
      'subscriptions' => 'Abonnementer',
      'lastupdated'   => 'Senest opdateret',
    },
    it => {
      'subscribe'     => 'Abbonati',
      'subscriptions' => 'Sottoscrizioni',
      'lastupdated'   => 'Last updated',
    },
    ja => {
      'subscribe'     => 'Subscribe',
      'subscriptions' => 'Subscriptions',
      'lastupdated'   => 'Last updated',
    },
    pl => {
      'subscribe'     => 'Subskrybuj',
      'subscriptions' => 'Subskrypcje',
      'lastupdated'   => 'Ostatnia zmiana',
    },
    pt => {
      'subscribe'     => 'Subscrever',
      'subscriptions' => 'Subcrições',
      'lastupdated'   => 'Última actualização',
    },
    ro => {
      'subscribe'     => 'Abonare',
      'subscriptions' => 'Abonări',
      'lastupdated'   => 'Ultima actualizare',
    },
    ru => {
      'subscribe'     => 'Подписаться',
      'subscriptions' => 'Подписки',
      'lastupdated'   => 'Последнее обновление',
    },
    sr => {
      'subscribe'     => 'Subscribe',
      'subscriptions' => 'Subscriptions',
      'lastupdated'   => 'Last updated',
    },
    zh => {
      'subscribe'     => '訂閱',
      'subscriptions' => '收錄',
      'lastupdated'   => '最近更新'
    },
  }

  # the actual planet-venus class doing all the rest
  class {'planet::venus':
    planet_domain_name => $planet_domain_name,
    planet_languages => $planet_languages,
  }
}

