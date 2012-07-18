# NTP Server

class ntp::server(
  $servers = [
    '198.186.191.229',
    '64.113.32.2',
    '173.8.198.242',
    '208.75.88.4',
    '75.144.70.35'
  ],
  $peers   =[]
) {
  $ntp_server = true

  include ntp

  system_role { 'ntp::server':
    description => 'NTP server',
  }

  monitor_service { 'ntp peers':
    description   => 'NTP peers',
    check_command => 'check_ntp_peer!0.1!0.5';
  }
}
