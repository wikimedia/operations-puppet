# = Class: prometheus::node_debian_version
#
# Periodically export the version of Debian installed.
#
# Intended to run on all hosts.
#
class prometheus::node_debian_version (
    Wmflib::Ensure $ensure = 'present',
    Stdlib::Unixpath $outfile = '/var/lib/prometheus/node.d/debian_version.prom',
) {
    $exec = '/usr/local/bin/prometheus-debian-version'
    file { $exec:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-debian-version.sh',
    }

    systemd::timer::job { 'prometheus-debian-version-textfile':
        ensure          => $ensure,
        description     => 'Update Debian version stat exported by node_exporter',
        command         => "${exec} ${outfile}",
        user            => 'root',
        logging_enabled => false,
        require         => [File[$exec]],
        interval        => {
            # We don't care about when this runs, as long as it runs every few minutes.
            # We also explicitly *don't* want to synchronize its execution across hosts,
            # as OnCalendar would do, and this should have some natural splay.
            'start'    => 'OnUnitInactiveSec',
            'interval' => '300s',
        },
    }
}
