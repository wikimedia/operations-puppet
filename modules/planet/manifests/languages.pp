# List all planet languages and translations for
# index.html.tmpl here.  Configurations, directories and
# cronjobs are auto-created from this hash.

class planet::languages {

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
}
