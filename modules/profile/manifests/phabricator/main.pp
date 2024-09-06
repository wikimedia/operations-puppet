# SPDX-License-Identifier: Apache-2.0
# phabricator instance
#
class profile::phabricator::main (
    String                      $domain             = lookup('phabricator_domain',
                                                      { 'default_value' => 'phabricator.wikimedia.org' }),
    String                      $remote_aphlict_domain =
                                                      lookup('aphlict_domain',
                                                      { 'default_value' => 'aphlict.discovery.wmnet' }),
    Integer                     $remote_aphlict_admin_port =
                                                      lookup('profile::phabricator::aphlict::admin_port',
                                                      { 'default_value' => 22281 }),
    String                      $altdom             = lookup('phabricator_altdomain',
                                                      { 'default_value' => 'phab.wmfusercontent.org' }),
    Stdlib::Fqdn                $mysql_master       = lookup('phabricator::mysql::master',
                                                      { 'default_value' => 'localhost' }),
    String                      $mysql_master_port  = lookup('phabricator::mysql::master::port',
                                                      { 'default_value' => '3306' }),
    String                      $mysql_slave        = lookup('phabricator::mysql::slave',
                                                      { 'default_value' => 'localhost' }),
    String                      $mysql_slave_port   = lookup('phabricator::mysql::slave::port',
                                                      { 'default_value' => '3323' }),
    Stdlib::Unixpath            $phab_root_dir      = lookup('phabricator_root_dir',
                                                      { 'default_value' => '/srv/phab'}),
    String                      $deploy_target      = lookup('phabricator_deploy_target',
                                                      { 'default_value' => 'phabricator/deployment'}),
    Optional[String]            $deploy_user        = lookup('phabricator_deploy_user',
                                                      { 'default_value' => 'phab-deploy' }),
    Optional[String]            $phab_app_user      = lookup('phabricator_app_user',
                                                      { 'default_value' => undef }),
    Optional[String]            $phab_app_pass      = lookup('phabricator_app_pass',
                                                      { 'default_value' => undef }),
    Optional[String]            $phab_daemons_user  = lookup('phabricator_daemons_user',
                                                      { 'default_value' => undef }),
    Optional[String]            $phab_manifest_user = lookup('phabricator_manifest_user',
                                                      { 'default_value' => undef }),
    Optional[String]            $phab_manifest_pass = lookup('phabricator_manifest_pass',
                                                      { 'default_value' => undef }),
    Optional[String]            $phab_daemons_pass  = lookup('phabricator_daemons_pass',
                                                      { 'default_value' => undef }),
    Optional[String]            $phab_mysql_admin_user=
                                                      lookup('phabricator_admin_user',
                                                      { 'default_value' => undef }),
    Optional[String]            $phab_mysql_admin_pass =
                                                      lookup('phabricator_admin_pass',
                                                      { 'default_value' => undef }),
    Stdlib::Fqdn                $phab_diffusion_ssh_host=
                                                      lookup('phabricator_diffusion_ssh_host',
                                                      { 'default_value' => 'git-ssh.wikimedia.org' }),
    Boolean                     $enable_vcs         = lookup('phabricator::vcs::enable',
                                                      { 'default_value' => false }),
    Boolean                     $use_lvs            = lookup('profile::phabricator::main::use_lvs',
                                                      { 'default_value' => false }),
    Optional[Stdlib::IP::Address::V4] $vcs_ip_v4    = lookup('phabricator::vcs::address::v4',
                                                      { 'default_value' => undef }),
    Optional[Stdlib::IP::Address::V6] $vcs_ip_v6    = lookup('phabricator::vcs::address::v6',
                                                      { 'default_value' => undef }),
    Array                       $cluster_search     = lookup('phabricator_cluster_search'),
    Stdlib::Fqdn                $active_server      = lookup('phabricator_active_server',
                                                      { 'default_value' => undef }),
    Stdlib::Fqdn                $passive_server     = lookup('phabricator_passive_server',
                                                      { 'default_value' => undef }),
    Boolean                     $local_aphlict_enabled =
                                                      lookup('phabricator_aphlict_enabled',
                                                      { 'default_value' => false }),
    Boolean                     $aphlict_ssl        = lookup('phabricator_aphlict_enable_ssl',
                                                      { 'default_value' => false }),
    Optional[Stdlib::Unixpath]  $aphlict_cert       = lookup('phabricator_aphlict_cert',
                                                      { 'default_value' => undef }),
    Optional[Stdlib::Unixpath]  $aphlict_key        = lookup('phabricator_aphlict_key',
                                                      { 'default_value' => undef }),
    Optional[Stdlib::Unixpath]  $aphlict_chain      = lookup('phabricator_aphlict_chain',
                                                      { 'default_value' => undef }),
    Hash                        $rate_limits        = lookup('profile::phabricator::main::rate_limits',
                                                      { 'default_value' => {
                                                            'request' => 0,
                                                            'connection' => 0}
                                                      }),
    Integer                     $phd_taskmasters    = lookup('phabricator_phd_taskmasters',
                                                      { 'default_value' => 10 }),
    Integer                     $opcache_validate   = lookup('phabricator_opcache_validate',
                                                      { 'default_value' => 0 }),
    String                      $timezone           = lookup('phabricator_timezone',
                                                      { 'default_value' => 'UTC' }),
    Boolean                     $dump_enabled       = lookup('profile::phabricator::main::dump_enabled',
                                                      { 'default_value' => false }),

    String                      $http_srange        = lookup('profile::phabricator::main::http_srange'),

    Boolean                     $manage_scap_user   = lookup('profile::phabricator::main::manage_scap_user',
                                                      { 'default_value' => true }),
    String                      $gitlab_api_key     = lookup('profile::phabricator::main::gitlab_api_key',
                                                      { 'default_value' => '' }),
    Stdlib::Unixpath            $database_datadir   = lookup('profile::phabricator::main::database_datadir',
                                                      {default_value => '/var/lib/mysql'}),
    Optional[
        Array[Stdlib::Fqdn]
    ]                           $mx_in_hosts        = lookup('profile::phabricator::main::mx_in_hosts',
                                                      { 'default_value' => undef }),
) {

    $mail_alias = $::realm ? {
        'production' => 'wikimedia.org',
        default      => 'wmflabs.org',
    }

    mailalias { 'root':
        recipient => "root@${mail_alias}",
    }

    # in cloud, use a local db server
    if $::realm == 'labs' {
        class { 'profile::mariadb::generic_server':
            datadir => $database_datadir,
        }
    }

    include passwords::phabricator
    include passwords::mysql::phabricator

    # things configured differently if we are on the
    # "phabricator_active_server" defined in Hiera
    if $::fqdn == $active_server {
        $firewall_ensure = 'present'
        if $local_aphlict_enabled {
            $aphlict_ensure = 'present'
        } else {
            $aphlict_ensure = 'absent'
        }
        $mysql_host = $mysql_master
        $mysql_port = $mysql_master_port
        systemd::unmask { 'phd.service': }
        $phd_service_ensure = 'running'
        $phd_service_enable = true
    } else {
        $firewall_ensure = 'absent'
        $aphlict_ensure = 'absent'
        $mysql_host = $mysql_slave
        $mysql_port = $mysql_slave_port
        $phd_service_ensure = 'stopped'
        $phd_service_enable = false
        systemd::mask { 'phd.service': }
    }

    # in prod we just open port 80 for deployment_hosts for testing, caching layer speaks TLS to envoy
    # in cloud we need to also open it for proxies which don't speak TLS to backends
    firewall::service { 'phabmain_http':
        ensure => present,
        proto  => 'tcp',
        port   => 80,
        srange => $http_srange,
    }

    if $local_aphlict_enabled {
        $notification_servers = [
            {
                'type'      => 'client',
                'host'      => $domain,
                'port'      => 22280,
                'protocol'  => 'https',
            },
            {
                'type'      => 'admin',
                'host'      => 'localhost',
                'port'      => 22281,
                'protocol'  => 'http',
            }
        ]

    } else {
        # As of writing, client requests are routed through the public Phab/Phorge name. Our Apache Traffic Server then
        # redirects to the remote aphlict:
        # https://gerrit.wikimedia.org/r/plugins/gitiles/operations/puppet/+/5e2613eed44b788348c223c7bb62d5089d7a2352/hieradata/common/profile/trafficserver/backend.yaml#153
        $notification_servers = [
            {
                'type'      => 'client',
                'host'      => $domain,
                'port'      => 443,
                'protocol'  => 'https',
            },
            {
                'type'      => 'admin',
                'host'      => $remote_aphlict_domain,
                'port'      => $remote_aphlict_admin_port,
                'protocol'  => 'http',
            }
        ]
    }

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

    # As of T146055: phd_user and phd_pass exist to separate privileges. phd_user could eventually
    # be granted less or different privs in mysql as compared to app_user.
    # phd could also run on a different hardware from the web frontend.
    if $phab_daemons_user == undef {
        $daemons_user = $passwords::mysql::phabricator::phd_user
    } else {
        $daemons_user = $phab_daemons_user
    }
    if $phab_daemons_pass == undef {
        $daemons_pass = $passwords::mysql::phabricator::phd_pass
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

    # Collect an array of all ipaddresses
    # in reality $facts['networking']['ipaddress6'] will be the address traffic is sourced from but it
    # does no harm adding all of them
    # TODO: move this to a general function i.e. network::ipaddresses(ipv4=true, ipv6=true)
    $trusted_proxies = $facts['networking']['interfaces'].reduce([]) |$memo, $value| {
        $bindings = $value[1].has_key('bindings') ? {
            true    => $value[1]['bindings'].map |$binding| { $binding['address'] },
            default => [],
        }
        $bindings6 = $value[1].has_key('bindings6') ? {
            true    => $value[1]['bindings6'].map |$binding| { $binding['address'] },
            default => [],
        }
        $memo + $bindings + $bindings6
    }.sort

    class { 'phabricator':
        deploy_target      => $deploy_target,
        deploy_user        => $deploy_user,
        phabdir            => $phab_root_dir,
        serveraliases      => [ $altdom,
                              'bugzilla.wikimedia.org',
                              'bugs.wikimedia.org' ],
        trusted_proxies    => $trusted_proxies,
        enable_vcs         => $enable_vcs,
        mysql_admin_user   => $mysql_admin_user,
        mysql_admin_pass   => $mysql_admin_pass,
        libraries          => [ "${phab_root_dir}/libext/misc",
                              "${phab_root_dir}/libext/ava/src",
                              "${phab_root_dir}/libext/translations/src" ],
        settings           => {
            'cluster.search'                 => $cluster_search,
            'darkconsole.enabled'            => false,
            'differential.allow-self-accept' => true,
            'phabricator.base-uri'           => "https://${domain}",
            'security.alternate-file-domain' => "https://${altdom}",
            'mysql.host'                     => $mysql_host,
            'mysql.port'                     => $mysql_port,
            'cluster.mailers'                => $mail_config,
            'metamta.default-address'        => "no-reply@${domain}",
            'metamta.reply-handler-domain'   => $domain,
            'repository.default-local-path'  => '/srv/repos',
            'phd.taskmasters'                => $phd_taskmasters,
            'events.listeners'               => [],
            'diffusion.allow-http-auth'      => true,
            'diffusion.ssh-host'             => $phab_diffusion_ssh_host,
        },
        config_deploy_vars => {
            'phabricator' => {
                'www'       => {
                    'database_username' => $app_user,
                    'database_password' => $app_pass,
                },
                'mail'      => {
                    'database_username' => $app_user,
                    'database_password' => $app_pass,
                },
                'phd'       => {
                    'database_username' => $daemons_user,
                    'database_password' => $daemons_pass,
                },
                'vcs'       => {
                    'database_username' => $daemons_user,
                    'database_password' => $daemons_pass,
                },
                'redirects' => {
                    'database_username' => $daemons_user,
                    'database_password' => $daemons_pass,
                    'database_host'     => $mysql_host,
                    'field_index'       => '4rRUkCdImLQU',
                },
                'local'     => {
                    'base_uri'                  => "https://${domain}",
                    'alternate_file_domain'     => "https://${altdom}",
                    'mail_default_address'      => "no-reply@${domain}",
                    'mail_reply_handler_domain' => $domain,
                    'phd_taskmasters'           => $phd_taskmasters,
                    'ssh_host'                  => $phab_diffusion_ssh_host,
                    'notification_servers'      => $notification_servers,
                    'cluster_search'            => $cluster_search,
                    'cluster_mailers'           => $mail_config,
                    'database_host'             => $mysql_host,
                    'database_port'             => $mysql_port,
                    'gitlab_api_key'            => $gitlab_api_key,
                },
            },
        },
        opcache_validate   => $opcache_validate,
        timezone           => $timezone,
        phd_service_ensure => $phd_service_ensure,
        phd_service_enable => $phd_service_enable,
        manage_scap_user   => $manage_scap_user,
    }

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

    $core_extensions =  [
        'curl',
        'gd',
        'gmp',
        'intl',
        'mbstring',
        'ldap',
    ]

    $php_version = wmflib::debian_php_version()

    # Install the runtime
    class { '::php':
        ensure         => present,
        versions       => [$php_version],
        sapis          => ['cli', 'fpm'],
        config_by_sapi => {
            'fpm' => $fpm_config,
        },
    }

    $core_extensions.each |$extension| {
        php::extension { $extension:
            versioned_packages => true,
            sapis              => ['cli', 'fpm'],
        }
    }

    class { '::php::fpm':
        ensure => present,
        config => {
            'emergency_restart_interval' => '60s',
            'process.priority'           => -19,
        },
    }

    # Extensions that require configuration.
    php::extension {
        default:
            sapis        => ['cli', 'fpm'];
        'apcu':
            ;
        'mailparse':
            priority     => 21;
        'mysqlnd':
            install_packages => false,
            priority         => 10;
        'xml':
            versioned_packages => true,
            priority           => 15;
        'mysqli':
            package_overrides => {"${php_version}" =>"php${php_version}-mysql"},;
    }

    $num_workers = max(floor($facts['processors']['count'] * 1.5), 8)
    # These numbers need to be positive integers
    $max_spare = ceiling($num_workers * 0.3)
    $min_spare = ceiling($num_workers * 0.1)
    php::fpm::pool { 'www':
        version => $php_version,
        config  => {
            'pm'                   => 'dynamic',
            'pm.max_spare_servers' => $max_spare,
            'pm.min_spare_servers' => $min_spare,
            'pm.start_servers'     => $min_spare,
            'pm.max_children'      => $num_workers,
        }
    }

    class { '::phabricator::aphlict':
        ensure     => $aphlict_ensure,
        basedir    => $phab_root_dir,
        enable_ssl => $aphlict_ssl,
        sslcert    => $aphlict_cert,
        sslkey     => $aphlict_key,
        sslchain   => $aphlict_chain,
        require    => Class[phabricator],
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

    # Backup repositories and home dirs
    backup::set { 'srv-repos': }
    backup::set { 'home': }

    include profile::mail::default_mail_relay
    $smarthosts = $profile::mail::default_mail_relay::smarthosts
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

    # Receive mail from inbound mail hosts
    if $mx_in_hosts == undef {
        $_mx_in_hosts = profile::postfix::mx_inbound_hosts()
    } else {
        $_mx_in_hosts = $mx_in_hosts
    }
    if $_mx_in_hosts and $_mx_in_hosts.length > 0 {
        firewall::service { 'phabmain-smtp':
            ensure => $firewall_ensure,
            port   => 25,
            proto  => 'tcp',
            srange => $_mx_in_hosts,
        }
    }

    # ssh between phabricator servers for clustering support
    firewall::service { 'ssh_cluster':
        port   => 22,
        proto  => 'tcp',
        srange => [$active_server, $passive_server],
    }

    if $local_aphlict_enabled {
        firewall::service { 'notification_server':
            ensure => $firewall_ensure,
            proto  => 'tcp',
            port   => 22280,
        }
    }

    # Ship apache error logs to ELK - T141895
    rsyslog::input::file { 'apache2-error':
        path => '/var/log/apache2/*error*.log',
    }

    rsyslog::input::file { 'apache2-access':
        path => '/var/log/apache2/*access*.log',
    }

    file { '/usr/local/bin/chk_phuser':
        source => 'puppet:///modules/phabricator/chk_phuser.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    # mysql read access for phab admins, in production (T238425)
    if $::realm == 'production' {
        $::admin::data['groups']['phabricator-admin']['members'].each |String $user| {
            file { "/home/${user}/.my.cnf":
                content => template('phabricator/my.cnf.erb'),
                owner   => $user,
                group   => 'root',
                mode    => '0440',
            }
        }
    }

    # set git safedir on the phab deploy repo to properly display version info (T360756)
    # see comments inside the script why it's a bash script and not just puppet
    file { '/usr/local/bin/phab_git_safedir.sh':
        source => 'puppet:///modules/phabricator/phab_git_safedir.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    # update gitconfig in the same way that git::systemconfig does it to avoid conflicts
    # but only when notified by our script
    exec { 'update-safedir-gitconfig':
        command     => '/bin/cat /etc/gitconfig.d/*.gitconfig > /etc/gitconfig',
        refreshonly => true,
    }

    # determine phab deploy dir and set it as safedir
    # unless it's already in the generated config file
    # notify to build the config from snippets
    # puppet will removed the snippet in gitconfig.d afterwards
    exec { 'phab-git-safedir':
        command => '/usr/local/bin/phab_git_safedir.sh',
        unless  => '/usr/bin/grep -q deployment-cache /etc/gitconfig',
        notify  => Exec['update-safedir-gitconfig'],
    }
}
