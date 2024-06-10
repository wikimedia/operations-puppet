# SPDX-License-Identifier: Apache-2.0
# == Define: prometheus::node_textfile
#
# This define sets up a local script which runs periodically with the intention
# to export local metrics under /var/lib/prometheus/node.d/foo where foo
# is the name/title of the define
#
# [*filesource*]
#   A Puppet file source for the exporter script
#
# [*interval*]
#   An interval for how often the script should run, specified in systemd timer
#   syntax, see the systemd.time manpage
#
# [*run_cmd']
#   How the exporter script should be started
#
# [*extra_packages*]
#   If the script requires additional Debian packages to be installed they can
#   be configured here.
#
# [*user*]
#   Configures the user to run the script under, defaults to "root"
#
define prometheus::node_textfile (
    String                       $interval,
    String                       $run_cmd,
    Wmflib::Ensure               $ensure          = 'present',
    Optional[Stdlib::Filesource] $filesource      = undef,
    Optional[String]             $user            = 'root',
    Optional[Array[String]]      $extra_packages  = [],
) {
    if $extra_packages {
        ensure_packages($extra_packages, {'ensure' => $ensure})
    }

    if $filesource {
        file { "/usr/local/bin/${title}":
            ensure => $ensure,
            mode   => '0555',
            source => $filesource
        }
    }

    systemd::timer::job { "prometheus-node-textfile-${title}":
        ensure      => $ensure,
        description => "Systemd timer to gather node metrics for ${title}",
        user        => $user,
        command     => $run_cmd,
        interval    => {'start' => 'OnCalendar', 'interval' => $interval},
    }
}
