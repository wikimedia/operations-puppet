# root, repl, nagios, prometheus
# WARNING: any root user will have access to these files
# Do not apply to hosts with users with arbitrary roots
# or any non-production mysql, such as labs-support hosts,
# wikitech hosts, etc.
class profile::mariadb::grants::production(
    $shard    = false,
    $prompt   = '',
    $password = 'undefined',
    $wikiuser_username = lookup('profile::mariadb::wikiuser_username'),
    $wikiadmin_username = lookup('profile::mariadb::wikiadmin_username'),
    $vrts_database_pw = lookup('profile::vrts::database_pass'),
    $vrts_exim_database_pass = lookup('profile::vrts::exim_database_pass'),
    ) {

    include passwords::misc::scripts
    include passwords::openstack::keystone
    include passwords::testreduce::mysql
    include passwords::prometheus
    include passwords::striker
    include passwords::labsdbaccounts
    include passwords::mysql::phabricator
    include passwords::recommendationapi::mysql
    include passwords::designate
    include passwords::rddmarc

    $cumin_pass       = $passwords::misc::scripts::mysql_cumin_pass
    $repl_pass       = $passwords::misc::scripts::mysql_repl_pass
    $prometheus_pass = $passwords::prometheus::db_pass

    file { '/etc/mysql/production-grants.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/mariadb/grants/production.sql.erb'),
    }

    if $shard {
        $designate_pass      = $passwords::designate::db_pass
        $keystone_pass       = $passwords::openstack::keystone::keystone_db_pass
        $testreduce_pass     = $passwords::testreduce::mysql::db_pass
        $testreduce_cli_pass = $passwords::testreduce::mysql::mysql_client_pass
        $striker_pass        = $passwords::striker::application_db_password
        $striker_admin_pass  = $passwords::striker::admin_db_password
        $labspuppet_pass     = lookup('labspuppetbackend_mysql_password')
        $labsdbaccounts_pass = $passwords::labsdbaccounts::db_password
        $wikiuser_pass       = $passwords::misc::scripts::wikiuser_pass
        $wikiadmin_pass      = $passwords::misc::scripts::wikiadmin_pass
        $rddmarc_pass        = $passwords::rddmarc::db_password
        $phab_admin_pass     = $passwords::mysql::phabricator::admin_pass
        $phab_phd_pass       = $passwords::mysql::phabricator::phd_pass
        $phab_app_pass       = $passwords::mysql::phabricator::app_pass
        $phab_bz_pass        = $passwords::mysql::phabricator::bz_pass
        $phab_rt_pass        = $passwords::mysql::phabricator::rt_pass
        $phab_manifest_pass  = $passwords::mysql::phabricator::manifest_pass
        $phab_metrics_pass   = $passwords::mysql::phabricator::metrics_pass
        $recommendationapi_pass        = $passwords::recommendationapi::mysql::recommendationapi_pass
        $recommendationapiservice_pass = $passwords::recommendationapi::mysql::recommendationapiservice_pass

        file { '/etc/mysql/production-grants-shard.sql':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            content => template("profile/mariadb/grants/production-${shard}.sql.erb"),
        }
    }
}
