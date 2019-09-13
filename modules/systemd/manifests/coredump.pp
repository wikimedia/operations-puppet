#  == Class systemd::coredump ==
#
#  Configure systemd-coredump. By default we will make sure that
#  /etc/systemc/coredumps.conf is absent.
#
#  [*enabled*]
#
# Whether coredump is enabled or not.

class systemd::coredump (
    Wmflib::Ensure $ensure = absent
){
    require ::systemd
    $exec_label = 'systemd daemon-reload for coredump'
        file { '/etc/systemd/coredump.conf':
            ensure => $ensure,
            source => 'puppet:///modules/systemd/coredump.conf',
            mode   => '0444',
            owner  => 'root',
            group  => 'root',
            notify => Exec[$exec_label],
        }
    exec { $exec_label:
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
    }

    # That should always be there so any leftover files on a
    # server where coredump is not enabled any more, will be removed
    systemd::tmpfile { 'coredump':
        content => 'd /var/lib/systemd/coredump 0755 root root 15d',
    }
    sysctl::parameters { 'coredump':
        ensure => $ensure,
        values => {
            'kernel.core_pattern' => '|/usr/lib/systemd/systemd-coredump %P %u %g %s %t %c %e'
        }
    }
}
