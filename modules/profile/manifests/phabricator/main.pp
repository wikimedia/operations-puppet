# phabricator instance
#
# filtertags: labs-project-deployment-prep labs-project-phabricator
class profile::phabricator::main (
    Hash $cache_nodes = hiera('cache::nodes', {}),
    String $domain = hiera('phabricator_domain', 'phabricator.wikimedia.org'),
    String $altdom = hiera('phabricator_altdomain', 'phab.wmfusercontent.org'),
    Stdlib::Fqdn $mysql_host = hiera('phabricator::mysql::master', 'localhost'),
    Integer $mysql_port = hiera('phabricator::mysql::master::port', 3306),
    String $mysql_slave = hiera('phabricator::mysql::slave', 'localhost'),
    Integer $mysql_slave_port = hiera('phabricator::mysql::slave::port', 3323),
    Stdlib::Unixpath $phab_root_dir = '/srv/phab',
    String $deploy_target = 'phabricator/deployment',
    Optional[String] $phab_app_user = hiera('phabricator_app_user', undef),
    Optional[String] $phab_app_pass = hiera('phabricator_app_pass', undef),
    Optional[String] $phab_daemons_user = hiera('phabricator_daemons_user', undef),
    Optional[String] $phab_manifest_user = hiera('phabricator_manifest_user', undef),
    Optional[String] $phab_manifest_pass = hiera('phabricator_manifest_pass', undef),
    Optional[String] $phab_daemons_pass = hiera('phabricator_daemons_pass', undef),
    Optional[String] $phab_mysql_admin_user = hiera('phabricator_admin_user', undef),
    Optional[String] $phab_mysql_admin_pass = hiera('phabricator_admin_pass', undef),
    Stdlib::Fqdn $phab_diffusion_ssh_host = hiera('phabricator_diffusion_ssh_host', 'git-ssh.wikimedia.org'),
    Array $cluster_search = hiera('phabricator_cluster_search'),
    Optional[String] $active_server = hiera('phabricator_server', undef),
    Optional[String] $passive_server = hiera('phabricator_server_failover', undef),
    Boolean $logmail = hiera('phabricator_logmail', false),
    Boolean $aphlict_enabled = hiera('phabricator_aphlict_enabled', false),
    Hash $rate_limits = hiera('profile::phabricator::main::rate_limits'),
    Integer $phd_taskmasters = hiera('phabricator_phd_taskmasters', 10),
    Boolean $enable_php_fpm = hiera('phabricator_enable_php_fpm', false),
    Integer $opcache_validate = hiera('phabricator_opcache_validate', 0),
    String $timezone = hiera('phabricator_timezone', 'UTC'),
) {

    mailalias { 'root':
        recipient => 'root@wikimedia.org',
    }

    include passwords::phabricator
    include passwords::mysql::phabricator

    # dumps are only enabled on the active server set in Hiera
    $phabricator_active_server = hiera('phabricator_active_server')
    if $::hostname == $phabricator_active_server {
        $dump_enabled = true
        $rsync_cfg_enabled = true
        $ferm_ensure = 'present'
        $aphlict_ensure = 'present'
    } else {
        $dump_enabled = false
        $rsync_cfg_enabled = false
        $ferm_ensure = 'absent'
        $aphlict_ensure = 'absent'

        # on standby/staging servers allow http from
        # deployment servers for testing changes
        ferm::service { 'phabmain_http_deployment':
            ensure => present,
            proto  => 'tcp',
            port   => '80',
            srange => '$DEPLOYMENT_HOSTS',
        }
    }

    if $aphlict_enabled {
        $notification_servers = [
            {
                'type'      => 'client',
                'host'      => $domain,
                'port'      => 22280,
                'protocol'  => 'http',
            },
            {
                'type'      => 'admin',
                'host'      => $phabricator_active_server,
                'port'      => 22281,
                'protocol'  => 'http',
            }
        ]
    } else {
        $notification_servers = []
    }

    # logmail must be explictly enabled in Hiera with 'phabricator_logmail: true'
    # to avoid duplicate mails from labs and standby (T173297)
    $logmail_ensure = $logmail ? {
        true    => 'present',
        default => 'absent',
    }

    # todo: change the password for app_user
    if $phab_app_user == undef {
        $app_user = $passwords::mysql::phabricator::app_user
    } else {
        $app_user = $phab_app_user
    }
    if $phab_app_pass == undef {
        $app_pass = $passwords::mysql::phabricator::app_pass
    } else {
        $app_pass = $phab_app_pass
    }

    # todo: create a separate phd_user and phd_pass
    if $phab_daemons_user == undef {
        $daemons_user = $passwords::mysql::phabricator::app_user
    } else {
        $daemons_user = $phab_daemons_user
    }
    if $phab_daemons_pass == undef {
        $daemons_pass = $passwords::mysql::phabricator::app_pass
    } else {
        $daemons_pass = $phab_daemons_pass
    }

    if $phab_manifest_user == undef {
        $manifest_user = $passwords::mysql::phabricator::manifest_user
    } else {
        $manifest_user = $phab_manifest_user
    }
    if $phab_manifest_pass == undef {
        $manifest_pass = $passwords::mysql::phabricator::manifest_pass
    } else {
        $manifest_pass = $phab_manifest_pass
    }

    # todo: create a separate mail_user and mail_pass?
    $mail_user = $daemons_user
    $mail_pass = $daemons_pass

    $conf_files = {
        'www' => {
            'environment'       => 'www',
            'owner'             => 'root',
            'group'             => 'www-data',
            'phab_settings'     => {
                'mysql.user'        => $app_user,
                'mysql.pass'        => $app_pass,
            }
        },
        'phd' => {
            'environment'       => 'phd',
            'owner'             => 'root',
            'group'             => 'phd',
            'phab_settings'     => {
                'mysql.user'        => $daemons_user,
                'mysql.pass'        => $daemons_pass,
            }
        },
        'vcs' => {
            'environment'       => 'vcs',
            'owner'             => 'root',
            'group'             => 'phd',
            'phab_settings'     => {
                'mysql.user'        => $daemons_user,
                'mysql.pass'        => $daemons_pass,
            }
        },
        'mail' => {
            'environment'       => 'mail',
            'owner'             => 'root',
            'group'             => 'mail',
            'phab_settings'     => {
                'mysql.user'        => $mail_user,
                'mysql.pass'        => $mail_pass,
            }
        },
    }

    if $phab_mysql_admin_user == undef {
        $mysql_admin_user = $passwords::mysql::phabricator::admin_user
    } else {
        $mysql_admin_user = $phab_mysql_admin_user
    }

    if $phab_mysql_admin_pass == undef {
        $mysql_admin_pass = $passwords::mysql::phabricator::admin_pass
    } else {
        $mysql_admin_pass = $phab_mysql_admin_pass
    }

    $mail_config = [
        {
            'key'      => 'wikimedia-smtp',
            'type'     => 'smtp',
            'options'  => {
                'host' => 'localhost',
                'port' => 25,
            }
        }
    ]

    $cache_text_nodes = pick($cache_nodes['text'], {})

    # lint:ignore:arrow_alignment
    class { '::phabricator':
        deploy_target    => $deploy_target,
        phabdir          => $phab_root_dir,
        serveraliases    => [ $altdom,
                              'bugzilla.wikimedia.org',
                              'bugs.wikimedia.org' ],
        trusted_proxies  => $cache_text_nodes[$::site],
        mysql_admin_user => $mysql_admin_user,
        mysql_admin_pass => $mysql_admin_pass,
        libraries        => [ "${phab_root_dir}/libext/Sprint/src",
                              "${phab_root_dir}/libext/security/src",
                              "${phab_root_dir}/libext/misc",
                              "${phab_root_dir}/libext/ava/src",
                              "${phab_root_dir}/libext/translations/src" ],
        settings         => {
            'cluster.search'                         => $cluster_search,
            'darkconsole.enabled'                    => false,
            'differential.allow-self-accept'         => true,
            'phabricator.base-uri'                   => "https://${domain}",
            'security.alternate-file-domain'         => "https://${altdom}",
            'mysql.host'                             => $mysql_host,
            'cluster.mailers'                        => $mail_config,
            'metamta.default-address'                => "no-reply@${domain}",
            'metamta.reply-handler-domain'           => $domain,
            'repository.default-local-path'          => '/srv/repos',
            'phd.taskmasters'                        => $phd_taskmasters,
            'events.listeners'                       => [],
            'diffusion.allow-http-auth'              => true,
            'diffusion.ssh-host'                     => $phab_diffusion_ssh_host,
            'gitblit.hostname'                       => 'git.wikimedia.org',
            'notification.servers'                   => $notification_servers,
        },
        conf_files       => $conf_files,
        enable_php_fpm   => $enable_php_fpm,
        opcache_validate => $opcache_validate,
        timezone         => $timezone,
    }
    # lint:endignore

    # only supports stretch, do not use on jessie
    if $enable_php_fpm {
        $fpm_config = {
            'date'                   => {
                'timezone' => $timezone,
            },
            'opcache'                   => {
                'memory_consumption'      => 128,
                'interned_strings_buffer' => 16,
                'max_accelerated_files'   => 10000,
                'validate_timestamps'     => $opcache_validate,
            },
            'max_execution_time'  => 30,
            'post_max_size'       => '10M',
            'track_errors'        => 'Off',
            'upload_max_filesize' => '10M',
        }

        # Install the runtime
        class { '::php':
            ensure         => present,
            version        => '7.2',
            sapis          => ['cli', 'fpm'],
            config_by_sapi => {
                'fpm' => $fpm_config,
            },
            require        => Apt::Repository['wikimedia-php72'],
        }

        $core_extensions =  [
            'curl',
            'gd',
            'gmp',
            'intl',
            'mbstring',
            'ldap',
        ]

        $core_extensions.each |$extension| {
            php::extension { $extension:
                package_name => "php7.2-${extension}",
                require      => Apt::Repository['wikimedia-php72'],
                sapis        => ['cli', 'fpm'],
            }
        }

        # Extensions that require configuration.
        php::extension {
            'mailparse':
                package_name => 'php-mailparse',
                sapis        => ['cli', 'fpm'],
                priority     => 21;
            'mysqlnd':
                package_name => 'php7.2-mysqlnd',
                sapis        => ['cli', 'fpm'],
                priority     => 10;
            'xml':
                package_name => 'php7.2-xml',
                sapis        => ['cli', 'fpm'],
                priority     => 15;
            'mysqli':
                package_name => 'php7.2-mysql',
                sapis        => ['cli', 'fpm'];
            'apcu':
                package_name => 'php-apcu',
                sapis        => ['cli', 'fpm'];
        }

        class { '::php::fpm':
            ensure  => present,
            config  => {
                'emergency_restart_interval' => '60s',
                'process.priority'           => -19,
            },
            require => Apt::Repository['wikimedia-php72'],
        }

        $num_workers = max(floor($facts['processors']['count'] * 1.5), 8)
        # These numbers need to be positive integers
        $max_spare = ceiling($num_workers * 0.3)
        $min_spare = ceiling($num_workers * 0.1)
        php::fpm::pool { 'www':
            config => {
                'pm'                   => 'dynamic',
                'pm.max_spare_servers' => $max_spare,
                'pm.min_spare_servers' => $min_spare,
                'pm.start_servers'     => $min_spare,
                'pm.max_children'      => $num_workers,
            }
        }
    }

    class { '::phabricator::aphlict':
        ensure  => $aphlict_ensure,
        basedir => $phab_root_dir,
        require => Class[phabricator]
    }

    # This exists to offer git services at git-ssh.wikimedia.org
    $vcs_ip_v4 = hiera('phabricator::vcs::address::v4', undef)
    $vcs_ip_v6 = hiera('phabricator::vcs::address::v6', undef)
    if $vcs_ip_v4 or $vcs_ip_v6 {
        interface::alias { 'phabricator vcs':
            ipv4 => $vcs_ip_v4,
            ipv6 => $vcs_ip_v6,
        }
    }

    class { '::phabricator::tools':
        directory       => "${phab_root_dir}/tools",
        dbmaster_host   => $mysql_host,
        dbmaster_port   => $mysql_port,
        dbslave_host    => $mysql_slave,
        dbslave_port    => $mysql_slave_port,
        manifest_user   => $manifest_user,
        manifest_pass   => $manifest_pass,
        app_user        => $app_user,
        app_pass        => $app_pass,
        bz_user         => $passwords::mysql::phabricator::bz_user,
        bz_pass         => $passwords::mysql::phabricator::bz_pass,
        rt_user         => $passwords::mysql::phabricator::rt_user,
        rt_pass         => $passwords::mysql::phabricator::rt_pass,
        phabtools_cert  => $passwords::phabricator::phabtools_cert,
        phabtools_user  => $passwords::phabricator::phabtools_user,
        gerritbot_token => $passwords::phabricator::gerritbot_token,
        dump            => $dump_enabled,
        require         => Package[$deploy_target]
    }

    if $rsync_cfg_enabled {
        class { '::rsync::server': }

        $rsync_clients = ['labstore1006.wikimedia.org', 'labstore1007.wikimedia.org']
        rsync::server::module { 'srvdumps':
            path           => '/srv/dumps',
            read_only      => 'yes',
            hosts_allow    => $rsync_clients,
            auto_ferm      => true,
            auto_ferm_ipv6 => true,
        }
    }

    # Backup repositories
    backup::set { 'srv-repos': }

    class { '::exim4':
        variant => 'heavy',
        config  => template('role/exim/exim4.conf.phab.erb'),
        filter  => template('role/exim/system_filter.conf.erb'),
    }

    class { '::phabricator::mailrelay':
        default  => {
            maint    => false,
        },
        phab_bot => {
            root_dir => "${phab_root_dir}/phabricator/",
        },
    }

    ferm::service { 'phabmain_http':
        ensure => $ferm_ensure,
        proto  => 'tcp',
        port   => '80',
        srange => '($CACHES $DEPLOYMENT_HOSTS)',
    }

    # receive mail from mail smarthosts
    ferm::service { 'phabmain-smtp':
        ensure => $ferm_ensure,
        port   => '25',
        proto  => 'tcp',
        srange => inline_template('(<%= @mail_smarthost.map{|x| "@resolve(#{x})" }.join(" ") %>)'),
    }

    ferm::service { 'phabmain-smtp_ipv6':
        ensure => $ferm_ensure,
        port   => '25',
        proto  => 'tcp',
        srange => inline_template('(<%= @mail_smarthost.map{|x| "@resolve(#{x}, AAAA)" }.join(" ") %>)'),
    }

    # ssh between phabricator servers for clustering support
    $phabricator_servers_ferm = join(hiera('phabricator_servers'), ' ')
    ferm::service { 'ssh_cluster':
        port   => '22',
        proto  => 'tcp',
        srange => "@resolve((${phabricator_servers_ferm}))",
    }

    if $aphlict_enabled {
        ferm::service { 'notification_server':
            ensure => $ferm_ensure,
            proto  => 'tcp',
            port   => '22280',
        }
    }

    # redirect bugzilla URL patterns to phabricator
    # handles translation of bug numbers to maniphest task ids
    phabricator::redirector { "redirector.${domain}":
        mysql_user  => $passwords::mysql::phabricator::manifest_user,
        mysql_pass  => $passwords::mysql::phabricator::manifest_pass,
        mysql_host  => $mysql_host,
        rootdir     => '/srv/phab',
        field_index => '4rRUkCdImLQU',
        phab_host   => $domain,
        alt_host    => $altdom,
        rate_limits => $rate_limits,
        require     => Package[$deploy_target],
    }

    # community metrics mail (T81784, T1003)
    phabricator::logmail {'communitymetrics':
        ensure       => $logmail_ensure,
        script_name  => 'community_metrics.sh',
        rcpt_address => 'wikitech-l@lists.wikimedia.org',
        sndr_address => 'communitymetrics@wikimedia.org',
        monthday     => 1,
        require      => Package[$deploy_target],
    }

    # project changes mail (T85183)
    phabricator::logmail {'projectchanges':
        ensure       => $logmail_ensure,
        script_name  => 'project_changes.sh',
        rcpt_address => [ 'phabricator-reports@lists.wikimedia.org' ],
        sndr_address => 'aklapper@wikimedia.org',
        weekday      => 1, # Monday
        require      => Package[$deploy_target],
    }

    if $active_server != undef {
      rsync::quickdatacopy { 'srv-repos':
        ensure      => present,
        source_host => $active_server,
        dest_host   => $passive_server,
        auto_sync   => true,
        module_path => '/srv/repos',
      }
    }

    # Ship apache error logs to ELK - T141895
    rsyslog::input::file { 'apache2-error':
        path => '/var/log/apache2/*error*.log',
    }

    rsyslog::input::file { 'apache2-access':
        path => '/var/log/apache2/*access*.log',
    }

}
