# == Class profile::analytics::refinery::job::project_namespace_map
# Installs a weekly cron job to download the Wikimedia sitematrix project
# namespace map file so that other refinery jobs know about what wiki projects
# exist.
#
class profile::analytics::refinery::job::project_namespace_map(
    $http_proxy = hiera('profile::analytics::refinery::job::project_namespace_map::http_proxy', undef)
  ) {
    require ::profile::analytics::refinery

    # Shortcut var to DRY up cron commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${profile::analytics::refinery::path}/python"

    $output_directory = '/wmf/data/raw/mediawiki/project_namespace_map'
    $log_file         = "${::profile::analytics::refinery::log_dir}/download-project-namespace-map.log"

    if $http_proxy {
        $http_proxy_option = "-p ${http_proxy}"
    } else {
        $http_proxy_option = ''
    }

    # This downloads the project namespace map for a 'labsdb' public import.
    cron { 'refinery-download-project-namespace-map':
        command  => "${env} && ${profile::analytics::refinery::path}/bin/download-project-namespace-map -x ${output_directory} -s \$(/bin/date --date=\"$(/bin/date +\\%Y-\\%m-15) -1 month\" +'\\%Y-\\%m') ${http_proxy_option} >> ${log_file} 2>&1 ",
        user     => 'hdfs',
        minute   => '0',
        hour     => '0',
        # Start on the first day of every month.
        monthday => '1',
    }
}
