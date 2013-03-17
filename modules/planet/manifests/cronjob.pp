# type: cronjob for planet-venus feed updates
define planet::cronjob {

  $planet_bin = '/usr/bin/planet'
  $planet_config = "/usr/share/planet-venus/wikimedia/${title}/config.ini"
  $planet_logfile = "/var/log/planet/${title}-planet.log"

  cron {
    "update-${title}-planet":
    ensure  => present,
    command => "${planet_bin} -v ${planet_config} > ${planet_logfile} 2>&1",
    user    => 'planet',
    minute  => '0',
    require => [User['planet']];
  }

}
