# == Define profile::analytics::refinery::job::gobblin_job
# Wrapper define for declaring a gobblin job systemd timer.
# This is planned to be replaced by an Airflow job in the near future.
#
# === Parameters
# [*sysconfig_properties_file*]
#   Path to gobblin sysconfig properties file.
#
# [*jobconfig_properties_file]
#   Path to gobblin jobconfig pull properties file.
#   Default: /srv/deployment/analytics/refinery/gobblin/jobs/${title}.pull
#
define profile::analytics::refinery::job::gobblin_job (
    $sysconfig_properties_file,
    $jobconfig_properties_file  = undef,
    $user                       = 'analytics',
    $group                      = 'analytics',
    $gobblin_jar_file           = undef,
    $gobblin_script             = undef,
    $log_directory              = '/var/log/refinery/gobblin',
    $interval                   = undef,
    $environment                = {},
    $monitoring_enabled         = true,
    $monitoring_contact_groups  = 'analytics',
    $ensure                     = 'present',
) {
    require ::profile::analytics::refinery
    $refinery_path = $::profile::analytics::refinery::path

    $_jobconfig_properties_file = $jobconfig_properties_file ? {
        undef   => "${refinery_path}/gobblin/jobs/${title}.pull",
        default => $jobconfig_properties_file,
    }

    $_gobblin_jar_file = $gobblin_jar_file ? {
        undef   => "${refinery_path}/artifacts/gobblin-wmf.jar",
        default => $gobblin_jar_file,
    }

    $_gobblin_script = $gobblin_script ? {
        undef   => "${refinery_path}/bin/gobblin",
        default => $gobblin_script,
    }

    $default_environment = {
        'PYTHONPATH' => "${refinery_path}/python"
    }
    $_environment = merge($default_environment, $environment)

    if !defined(File[$log_directory]) {
        file { $log_directory:
            ensure => 'directory',
            group  => $group,
        }
    }

    $command = "${_gobblin_script} --sysconfig=${sysconfig_properties_file} --jar=${_gobblin_jar_file} ${_jobconfig_properties_file}"

    kerberos::systemd_timer { "gobblin-${title}":
        ensure                    => $ensure,
        description               => "Hadoop Gobblin job ${title}",
        command                   => $command,
        interval                  => $interval,
        user                      => $user,
        environment               => $_environment,
        monitoring_enabled        => $monitoring_enabled,
        monitoring_contact_groups => $monitoring_contact_groups,
        logfile_basedir           => $log_directory,
        logfile_name              => "${title}.log",
        logfile_owner             => $user,
        logfile_group             => $user,
        logfile_perms             => 'all',
        syslog_force_stop         => true,
        syslog_identifier         => "gobblin-${title}",
    }
}
