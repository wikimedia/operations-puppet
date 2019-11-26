# the query_service package is cloned from git and kept up to date via a cron
class query_service::deploy::autodeploy(
    String $deploy_user,
    String $deploy_name,
    Stdlib::Absolutepath $package_dir,
    Stdlib::Absolutepath $autodeploy_log_dir
){

    class { '::query_service::deploy::manual':
        deploy_user => $deploy_user,
        package_dir => $package_dir,
        deploy_name => $deploy_name,
    }

    file { $autodeploy_log_dir:
        ensure => directory,
        owner  => $deploy_user,
        group  => 'root',
        mode   => '0775',
    }

    $autodeployment_log = "${$autodeploy_log_dir}/${deploy_name}_autodeployment.log"

    file { '/usr/local/bin/query-service-autodeploy':
        ensure => present,
        source => 'puppet:///modules/query_service/cron/autodeploy.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    cron { 'autodeploy':
        ensure  => present,
        command => "/usr/local/bin/query-service-autodeploy ${deploy_name} ${package_dir} >> ${$autodeployment_log} 2>&1",
        user    => $deploy_user,
        minute  => 0,
        hour    => [5, 11, 17, 23],
    }

    logrotate::rule { 'autodeployment_log':
        ensure       => present,
        file_glob    => $autodeployment_log,
        frequency    => 'daily',
        missing_ok   => true,
        not_if_empty => true,
        rotate       => 30,
        compress     => true,
    }

}