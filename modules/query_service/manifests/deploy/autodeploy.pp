# the query_service package is cloned from git and kept up to date via a cron
class query_service::deploy::autodeploy(
    String $deploy_user,
    Stdlib::Absolutepath $package_dir,
    Stdlib::Absolutepath $autodeploy_log_dir
){

    class { '::query_service::deploy::manual':
        deploy_user => $deploy_user,
        package_dir => $package_dir,
    }

    file { $autodeploy_log_dir:
        ensure => directory,
        owner  => $deploy_user,
        group  => 'root',
        mode   => '0775',
    }

    $wdqs_autodeployment_log = "${$autodeploy_log_dir}/wdqs_autodeployment.log"

    file { '/usr/local/bin/wdqs-autodeploy':
        ensure => present,
        source => 'puppet:///modules/query_service/cron/wdqs-autodeploy.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    cron { 'wdqs-autodeploy':
        ensure  => present,
        command => "/usr/local/bin/wdqs-autodeploy ${package_dir} >> ${$wdqs_autodeployment_log} 2>&1",
        user    => $deploy_user,
        minute  => 0,
        hour    => [5, 11, 17, 23],
    }

    logrotate::rule { 'wdqs_autodeployment_log':
        ensure       => present,
        file_glob    => $wdqs_autodeployment_log,
        frequency    => 'daily',
        missing_ok   => true,
        not_if_empty => true,
        rotate       => 30,
        compress     => true,
    }

}