# SPDX-License-Identifier: Apache-2.0
class prometheus_postfix_exporter {
    ensure_packages(['prometheus-postfix-exporter'])

    $systemd_conf =
        @(EOF)
        [Service]
        ExecStart=
        # Read from log file, rather than journald, due to a bug:
        #  - debian: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1055326
        #  - upstream: https://github.com/kumina/postfix_exporter/issues/55
        ExecStart=/usr/bin/prometheus-postfix-exporter --postfix.logfile_path="/var/log/postfix.log" $ARGS
        | EOF

    systemd::unit { 'prometheus-postfix-exporter':
        ensure            => present,
        content           => $systemd_conf,
        restart           => true,
        override          => true,
        override_filename => 'override',
    }
}
