# == Class systemd ==
#
# This class just defines a the systemctl daemon-reload exec
# that systemd::file defines can notify to.
#
class systemd {
    if $::initsystem != 'systemd' {
        fail('You can only include the systemd class on systems using systemd.')
    }

    exec { 'systemd daemon-reload':
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
    }
    # Make the service actions happen after the daemon-reload if that
    # is happening.
    Exec['systemd daemon-reload'] -> Service<| |>
}
