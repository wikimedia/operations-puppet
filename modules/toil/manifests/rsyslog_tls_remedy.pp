# Restart rsyslog if its TLS listener endpoint isn't responsive
# Bandaid while https://phabricator.wikimedia.org/T199406 is fixed

class toil::rsyslog_tls_remedy (
  $ensure = present,
) {

  systemd::timer::job { 'rsyslog-tls-remedy':
    ensure          => $ensure,
    # Don't log to file, use journald
    logging_enabled => false,
    user            => 'root',
    description     => 'Restart rsyslog when TLS listener is not responding T199406',
    command         => '/bin/sh -c "timeout 10s openssl s_client -connect localhost:6514 -quiet </dev/null || systemctl restart rsyslog"',
    interval        => {
      'start'    => 'OnCalendar',
      'interval' => '*-*-* *:00/30:00', # every 30 min
    },
  }

}
