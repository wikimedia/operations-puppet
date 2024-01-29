# SPDX-License-Identifier: Apache-2.0
define fifo_log_demux::instance(
    Wmflib::Ensure $ensure = present,
    String $user = 'root',
    Stdlib::Absolutepath $fifo = '/var/run/fifo.pipe',
    Stdlib::Absolutepath $socket = '/var/run/log.socket',
    Boolean $create_fifo = false,
    Optional[String] $fifo_owner = undef,
    Optional[String] $fifo_group = undef,
    Optional[String] $wanted_by = undef,
    Optional[Stdlib::Filemode] $fifo_mode = undef,
) {
    include fifo_log_demux

    if $create_fifo {
        exec { "create_fifo@${title}":
            command => "/usr/bin/mkfifo ${fifo}",
            creates => $fifo,
        }

        file { $fifo:
            ensure  => $ensure,
            owner   => $fifo_owner,
            group   => $fifo_group,
            mode    => $fifo_mode,
            require => Exec["create_fifo@${title}"],
        }
    }

    # Removing this as we had Wants= in the [Install] section which would
    # perpetually keep the dependency on fifo-log-demux that we're trying to
    # remove from web servers. Once this is deployed we can remove this.
    file { '/etc/systemd/system/trafficserver.service.wants/fifo-log-demux@notpurge.service':
      ensure => 'absent',
    }
    file { '/etc/systemd/system/nginx.service.requires/fifo-log-demux@ncredir_access_log.service':
      ensure => 'absent',
    }

    systemd::service { "fifo-log-demux@${title}":
        ensure  => $ensure,
        # See above comment regarding removal of dependencies.
        # This can be uncommented when deployed.
        # restart => true,
        content => systemd_template('fifo-log-demux@'),
    }
}
