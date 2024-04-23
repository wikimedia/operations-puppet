# SPDX-License-Identifier: Apache-2.0
# Restart rsyslog periodically to work around imfile / k8s loosing files
# See also https://phabricator.wikimedia.org/T357616

# Minute randomization and splay are necessary since the timer will run
# on a large enough fleet of hosts.

class toil::rsyslog_imfile_remedy (
  Wmflib::Ensure $ensure       = present,
  Integer        $period_hours = 3,
) {

  $minute = fqdn_rand(59, 'rsyslog-imfile-remedy')

  systemd::timer::job { 'rsyslog-imfile-remedy':
    ensure          => $ensure,
    user            => 'root',
    description     => 'Restart rsyslog T357616',
    interval        => {
      'start'    => 'OnCalendar',
      'interval' => "*-*-* 00/${period_hours}:${minute}:00",
    },
    command         => '/usr/bin/systemctl try-restart rsyslog',
    logging_enabled => false, # log to journald
    splay           => 30,
  }

}
