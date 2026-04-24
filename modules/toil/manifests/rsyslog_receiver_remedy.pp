# SPDX-License-Identifier: Apache-2.0
# @summary Restart rsyslog-receiver if its TLS listener endpoint isn't responsive
# Bandaid while https://phabricator.wikimedia.org/T199406 is fixed

class toil::rsyslog_receiver_remedy (
  Stdlib::Unixpath $cert_file,
  Stdlib::Unixpath $key_file,
  Stdlib::Unixpath $ca_file,
  Wmflib::Ensure   $ensure = present,
) {
  systemd::timer::job { 'rsyslog-receiver-remedy':
    ensure          => $ensure,
    # Don't log to file, use journald
    logging_enabled => false,
    user            => 'root',
    description     => 'Restart rsyslog-receiver when its TLS listener is not responding T199406',
    interval        => {
      'start'    => 'OnCalendar',
      'interval' => '*-*-* *:00/05:00', # every 5 min
    },
    command         => "/bin/sh -c \"timeout 5s openssl s_client -connect localhost:6514 -cert_chain ${cert_file} -cert ${cert_file} -key ${key_file} -CAfile ${ca_file} -quiet -no_ign_eof </dev/null || systemctl restart rsyslog-receiver\"",
  }
}
