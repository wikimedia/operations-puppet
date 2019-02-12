# https://www.mediawiki.org/wiki/Extension:OpenStackManager
class openstack::wikitech::web(
    String $webserver_hostname,
    String $webserver_hostname_aliases,
    String $wikidb,
    String $wikitech_nova_ldap_proxyagent_pass,
    String $wikitech_nova_ldap_user_pass,
) {

    class {'::openstack::wikitech::wikitechprivatesettings':
        wikitech_nova_ldap_proxyagent_pass => $wikitech_nova_ldap_proxyagent_pass,
        wikitech_nova_ldap_user_pass       => $wikitech_nova_ldap_user_pass,
    }

    require_package([
        'python-mysqldb',
        'python-keystone',
        'php-ldap']
    )

    backup::set {'a-backup': }

    httpd::site { $webserver_hostname:
        content => template('openstack/wikitech/wikitech-web.wikimedia.org.erb'),
    }

    file {
        '/var/www/robots.txt':
            ensure => 'present',
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => 'puppet:///modules/openstack/wikitech/wikitech-robots.txt';
        '/usr/local/apache':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root';
        '/usr/local/apache/common':
            ensure => link,
            target => '/usr/local/apache/common-local';
        '/usr/local/apache/common-local':
            ensure => link,
            target => '/srv/mediawiki';
    }

    # TODO: Remove after change is applied
    cron { 'db-bak':
        ensure => absent,
    }

    cron { 'backup-cleanup':
        ensure => absent,
    }

    # TODO: Remove after change is applied
    cron { 'run-jobs':
        ensure => absent,
    }

    systemd::timer::job { 'wikitech_run_jobs':
        ensure                    => present,
        description               => 'Run Wikitech runJobs.php maintenance script',
        command                   => "/usr/local/bin/mwscript maintenance/runJobs.php --wiki=${wikidb} > /dev/null 2>&1",
        interval                  => {
        'start'    => 'OnCalendar',
        'interval' => '*-*-* *:*:*', # Every minute
        },
        logging_enabled           => false,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team',
        user                      => $::mediawiki::users::web,
    }
}
