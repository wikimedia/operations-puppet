# == systemd::syslog ==
#
# Configures logging via rsyslog and logrotate for systemd units. 
#
# === Paramenters ===
#
# [*base_dir*]
#  Base directory path for the logging directory. The 'title' will be appended
#  to form the final string value (example: 'title' => 'servicebla',
#  log dir => /var/log/servicebla) 
#  Default: '/var/log'
#
# [*owner*]
# User owner of the final logging directory.
#
# [*group*]
# Group owner of the final logging directory.
#
# [*readable_by*]
# Establish the File permissions assigned to the final logging directory.
# Options available: 'user' (0600), 'group' (0640), all '0644'
# Default: 'group'
# 
# [*logfilename*]
# Filename of the logging file.
# Default: 'syslog.log'
#
define systemd::syslog(
    $base_dir     = '/var/log',
    $owner        = $title,
    $group        = $title,
    $readable_by  = 'group'
    $log_filename = 'syslog.log' 
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
        file { $local_logdir:
            ensure => directory,
            owner  => $owner,
            group  => $group,
            mode   => $dirmode,
        }
    }

    file { $local_syslogfile:
        ensure  => present,
        replace => false,
        content => '',
        owner   => $title,
        group   => $title,
        mode    => $filemode,
        before  => Rsyslog::Conf[$title],
    }

    rsyslog::conf { $title:
        content  => template('systemd/rsyslog.conf.erb'),
        priority => 20,
        require  => File[$local_logdir],
        before   => Base::Service_unit[$title],
    }

    file { "/etc/logrotate.d/${title}":
        content => template('systemd/logrotate.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
