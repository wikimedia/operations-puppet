# == Class role::analytics_cluster::refinery::job::project_namespace_map
# Installs a weekly cron job to download the Wikimedia sitematrix project
# namespace map file so that other refinery jobs know about what wiki projects
# exist.
#
class role::analytics_cluster::refinery::job::project_namespace_map {
    require ::role::analytics_cluster::refinery

    # Shortcut var to DRY up cron commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${role::analytics_cluster::refinery::path}/python"

    $output_directory = '/wmf/data/raw/mediawiki/project_namespace_map'

    # This downloads the project namespace map for a 'labsdb' public import.
    cron { 'refinery-download-project-namespace':
        command => "${env} && ${role::analytics_cluster::refinery::path}/bin/download-project-namespace-map -x ${output_directory} -s \$(/bin/date '+%Y-%m)",
        user    => 'hdfs',
        minute  => '0',
        hour    => '12'
        weekday => '6' # Saturday
    }
}
