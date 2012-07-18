# NTP client

class ntp::client(
  $servers =['linne.wikimedia.org', 'dobson.wikimedia.org'],
  $peers   =[]
) {
  $ntp_server = false

  include ntp

  monitor_service { 'ntp':
    description   => 'NTP',
    check_command => 'check_ntp_time!0.5!1',
    retries       => 15, # wait for resync, don't flap after restart
  }
}
