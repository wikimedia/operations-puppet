# == Define: varnish::logging::mtail
#
#  Configure a varnishmtail instance and the associated mtail scripts.
#  The instance is responsible for running a varnishmtail script, for
#  example /usr/local/bin/varnishmtail-default. Different varnishmtail scripts
#  invoke varnishncsa in different ways, mostly changing the output format
#  string argument (-F). Regardless of how the output from varnishncsa looks
#  like, it is piped to a mtail instance running the given mtail programs
#  (mtail_programs), and exposing the resulting metrics on mtail_port to be
#  consumed by Prometheus. All mtail_programs are installed under a directory
#  named after the instance, for example /etc/mtail-default/.
#
# === Examples
#
#  varnish::logging::mtail { 'default':
#    mtail_programs => ['varnishreqstats', 'varnishttfb'],
#    mtail_port     => 3903,
#  }
#
#  varnish::logging::mtail { 'internal':
#    mtail_programs => ['varnishprocessing', 'varnisherrors'],
#    mtail_port     => 3913,
#  }
#
define varnish::logging::mtail(
  Array[String] $mtail_programs,
  Stdlib::Port::User $mtail_port,
) {
    # Common wrapper used by all varnishmtail instances
    file { '/usr/local/bin/varnishmtail-wrapper':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/varnishmtail-wrapper.sh',
    }

    file { "/usr/local/bin/varnishmtail-${title}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => "puppet:///modules/varnish/varnishmtail-${title}.sh",
        notify  => Systemd::Service["varnishmtail@${title}"],
        require => File['/usr/local/bin/varnishmtail-wrapper'],
    }

    $mtail_dir = "/etc/mtail-${title}"

    systemd::service { "varnishmtail@${title}":
        ensure  => present,
        content => systemd_template('varnishmtail@'),
        restart => true,
        require => File["/usr/local/bin/varnishmtail-${title}"],
    }

    $mtail_programs.each |String $name| {
        mtail::program { $name:
            source      => "puppet:///modules/mtail/programs/${name}.mtail",
            notify      => Systemd::Service["varnishmtail@${title}"],
            destination => $mtail_dir,
        }
    }
}
