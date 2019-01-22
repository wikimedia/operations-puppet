# == Class profile::analytics::refinery::job::project_namespace_map
#
# Installs a systemd timer to download the Wikimedia sitematrix project
# namespace map file so that other refinery jobs know about what wiki projects
# exist.
#
class profile::analytics::refinery::job::project_namespace_map(
    $http_proxy = hiera('profile::analytics::refinery::job::project_namespace_map::http_proxy', undef),
    $monitoring_enabled = hiera('profile::analytics::refinery::job::project_namespace_map::monitoring_enabled', true),
  ) {
    require ::profile::analytics::refinery

    # Shortcut var to DRY up cron commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${profile::analytics::refinery::path}/python"
    $systemd_env = {
        'PYTHONPATH' => "\${PYTHONPATH}:${profile::analytics::refinery::path}/python",
    }

    $output_directory = '/wmf/data/raw/mediawiki/project_namespace_map'
    $log_file         = "${::profile::analytics::refinery::log_dir}/download-project-namespace-map.log"

    if $http_proxy {
        $http_proxy_option = "-p ${http_proxy}"
    } else {
        $http_proxy_option = ''
    }

    # This downloads the project namespace map for a 'labsdb' public import.
    cron { 'refinery-download-project-namespace-map':
        ensure   => absent,
        command  => "${env} && ${profile::analytics::refinery::path}/bin/download-project-namespace-map -x ${output_directory} -s \$(/bin/date --date=\"$(/bin/date +\\%Y-\\%m-15) -1 month\" +'\\%Y-\\%m') ${http_proxy_option} >> ${log_file} 2>&1 ",
        user     => 'hdfs',
        minute   => '0',
        hour     => '0',
        # Start on the first day of every month.
        monthday => '1',
    }

    file { '/usr/local/bin/refinery-download-project-namespace-map':
        content => template('profile/analytics/refinery/job/refinery-sqoop-mediawiki.sh.erb'),
        mode    => '0550',
        owner   => 'hdfs',
        group   => 'hdfs',
    }

    systemd::timer::job { 'refinery-download-project-namespace-map':
        description               => "Periodic download of the Wikimedia sitematrix project's namespace map file",
        command                   => '/usr/local/bin/refinery-download-project-namespace-map',
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-01 00:00:00'
        },
        user                      => 'hdfs',
        environment               => $systemd_env,
        monitoring_enabled        => $monitoring_enabled,
        monitoring_contact_groups => 'analytics',
        logging_enabled           => true,
        logfile_basedir           => $::profile::analytics::refinery::log_dir,
        logfile_name              => 'syslog.log',
        logfile_owner             => 'hdfs',
        logfile_group             => 'hdfs',
        logfile_perms             => 'all',
        syslog_force_stop         => true,
        syslog_identifier         => $title,
        require                   => File['/usr/local/bin/refinery-download-project-namespace-map'],
    }

}
