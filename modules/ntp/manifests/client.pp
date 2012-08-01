# NTP client

class ntp::client(
  $servers =['linne.wikimedia.org', 'dobson.wikimedia.org'],
  $peers   =[]
) {
  $ntp_server = false

  include ntp

  # Restart NTP if hit by the erroneous leap second
  exec { "/bin/true":
    path => "/bin:/sbin:/usr/bin:/usr/sbin",
    notify => Service[ntp],
    onlyif => "ntpq -c 'rv 0 leap' | grep -q leap=01"
  }

  monitor_service { 'ntp':
    description   => 'NTP',
    check_command => 'check_ntp_time!0.5!1',
    retries       => 15, # wait for resync, don't flap after restart
  }
}
