# === Define: systemd::syslog
#
# Configures logging via rsyslog and logrotate for systemd units.
# Use the SyslogIdentifier parameter in the service's unit file
# if firejail (or similar) is used otherwise rsyslog will not receive
# the right program name.
#
# === Parameters
#
# [*base_dir*]
#   Base path, 'title' will be appended to form the final directory path.
#   For example: $title => 'servicebla', log dir => '/var/log/servicebla'
#   Default: '/var/log'
#
# [*owner*]
#   User owner of the logging directory.
#   Default: $title
#
# [*group*]
#   Group owner of the logging directory.
#   Default: $title
#
# [*readable_by*]
#   Establish the file permissions assigned to the logging directory.
#   Options available: 'user' (0600), 'group' (0640), all '0644'
#   Default: 'group'
#
# [*log_filename*]
#   Filename of the logging file.
#   Default: 'syslog.log'
#
# [*force_stop*]
#   Force 'stop' rule in the syslog configuration to
#   avoid sending the logs to syslog/daemon.log files.
#   Default: false
#
define systemd::syslog(
    Wmflib::Ensure $ensure = 'present',
    $base_dir     = '/var/log',
    $owner        = $title,
    $group        = $title,
    Enum['user', 'group', 'all'] $readable_by  = 'group',
    $log_filename = 'syslog.log',
    $force_stop   = false,
) {
    if $::initsystem != 'systemd' {
        fail('systemd::syslog is useful only with systemd')
    }

    # File permissions
    $dirmode = '0755'
    $filemode = $readable_by ? {
        'user'  => '0600',
        'group' => '0640',
        'all'   => '0644'
    }

    $local_logdir = "${base_dir}/${title}"
    $local_syslogfile = "${local_logdir}/${log_filename}"

    if ! defined(File[$local_logdir]) {
        $local_logdir_ensure = $ensure ? {
            absent  => absent,
            default => directory,
        }
        file { $local_logdir:
            ensure => $local_logdir_ensure,
            owner  => $owner,
            group  => $group,
            mode   => $dirmode,
        }
    }

    file { $local_syslogfile:
        ensure  => $ensure,
        replace => false,
        content => '',
        owner   => $owner,
        group   => $group,
        mode    => $filemode,
        before  => Rsyslog::Conf[$title],
    }

    rsyslog::conf { $title:
        ensure   => $ensure,
        content  => template('systemd/rsyslog.conf.erb'),
        priority => 20,
        require  => File[$local_logdir],
    }

    if defined(Service[$title]) {
        Rsyslog::Conf[$title] -> Service[$title]
    }

    logrotate::conf { $title:
        ensure  => $ensure,
        content => template('systemd/logrotate.erb'),
    }
}
