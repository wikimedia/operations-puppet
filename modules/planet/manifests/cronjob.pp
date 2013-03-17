# type: cronjob for planet-venus feed updates
define planet::cronjob {

  cron {
    "update-${title}-planet":
    ensure  => present,
    command => "/usr/bin/planet -v /usr/share/planet-venus/wikimedia/${title}/config.ini > /var/log/planet/${title}-planet.log 2>&1",
    user    => 'planet',
    minute  => '0',
    require => [User['planet']];
  }

}
