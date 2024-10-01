# https://www.mediawiki.org/wiki/Extension:OpenStackManager
class openstack::wikitech::web(
    String $webserver_hostname,
    String $wikidb,
    String $wikitech_nova_ldap_proxyagent_pass,
    String $wikitech_nova_ldap_user_pass,
    String $phabricator_api_token,
    String $gerrit_api_user,
    String $gerrit_api_password,
    String $gitlab_api_token,
    Boolean $public_rewrites = true,
    String $php_fpm_fcgi_endpoint = 'unix:/run/php/fpm-www-7.4.sock|fcgi://localhost',
) {

    class {'::openstack::wikitech::wikitechprivatesettings':
        wikitech_nova_ldap_proxyagent_pass => $wikitech_nova_ldap_proxyagent_pass,
        wikitech_nova_ldap_user_pass       => $wikitech_nova_ldap_user_pass,
        phabricator_api_token              => $phabricator_api_token,
        gerrit_api_user                    => $gerrit_api_user,
        gerrit_api_password                => $gerrit_api_password,
        gitlab_api_token                   => $gitlab_api_token,
    }

    backup::set {'cloudweb-srv-backup': }

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

    systemd::timer::job { 'wikitech_run_jobs':
        ensure             => absent,
        description        => 'Run Wikitech runJobs.php maintenance script',
        command            => "/usr/local/bin/mwscript maintenance/runJobs.php --wiki=${wikidb}",
        interval           => {
        'start'    => 'OnCalendar',
        'interval' => '*-*-* *:*:00', # Every minute
        },
        logging_enabled    => false,
        monitoring_enabled => false,
        user               => $::mediawiki::users::web,
    }

    file { '/etc/wikitech-logoutd.ini':
        content => "[logoutd]\ndbname=${wikidb}\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    profile::logoutd::script { 'wikitech':
        source => 'puppet:///modules/openstack/wikitech/wikitech-logout.py',
    }
}
