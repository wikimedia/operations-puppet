# phabricator instance
#
# filtertags: labs-project-deployment-prep labs-project-phabricator
class profile::phabricator::main (
    $cache_misc_nodes = hiera('cache::misc::nodes', []),
    $domain = hiera('phabricator_domain', 'phabricator.wikimedia.org'),
    $altdom = hiera('phabricator_altdomain', 'phab.wmfusercontent.org'),
    $mysql_host = hiera('phabricator::mysql::master', 'localhost'),
    $mysql_slave = hiera('phabricator::mysql::slave', 'localhost'),
    $phab_root_dir = '/srv/phab',
    $deploy_target = 'phabricator/deployment',
    $phab_app_user = hiera('phabricator_app_user', undef),
    $phab_app_pass = hiera('phabricator_app_pass', undef),
    $phab_daemons_user = hiera('phabricator_daemons_user', undef),
    $phab_daemons_pass = hiera('phabricator_daemons_pass', undef),
    $phab_mysql_admin_user = hiera('phabricator_admin_user', undef),
    $phab_mysql_admin_pass = hiera('phabricator_admin_pass', undef),
    $phab_diffusion_ssh_host = hiera('phabricator_diffusion_ssh_host', 'git-ssh.wikimedia.org'),
    $cluster_search = hiera('phabricator_cluster_search'),
    $active_server = hiera('phabricator_server', undef),
    $passive_server = hiera('phabricator_server_failover', undef),
    $logmail = hiera('phabricator_logmail', false),
    $aphlict_enabled = hiera('phabricator_aphlict_enabled', false),
){

    mailalias { 'root':
        recipient => 'root@wikimedia.org',
    }

    include passwords::phabricator
    include passwords::mysql::phabricator

    # dumps are only enabled on the active server set in Hiera
    $phabricator_active_server = hiera('phabricator_active_server')
    if $::hostname == $phabricator_active_server {
        $dump_rsync_ensure = 'present'
        $dump_enabled = true
        $ferm_ensure = 'present'
        $aphlict_ensure = 'present'
    } else {
        $dump_rsync_ensure ='absent'
        $dump_enabled = false
        $ferm_ensure = 'absent'
        $aphlict_ensure = 'absent'
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

    # lint:ignore:arrow_alignment
    class { '::phabricator':
        deploy_target    => $deploy_target,
        phabdir          => $phab_root_dir,
        serveraliases    => [ $altdom,
                              'bugzilla.wikimedia.org',
                              'bugs.wikimedia.org' ],
        trusted_proxies  => $cache_misc_nodes[$::site],
        mysql_admin_user => $mysql_admin_user,
        mysql_admin_pass => $mysql_admin_pass,
        libraries        => [ "${phab_root_dir}/libext/Sprint/src",
                              "${phab_root_dir}/libext/security/src",
                              "${phab_root_dir}/libext/misc",
                              "${phab_root_dir}/libext/translations/src" ],
        settings         => {
            'cluster.search'                         => $cluster_search,
            'darkconsole.enabled'                    => false,
            'differential.allow-self-accept'         => true,
            'phabricator.base-uri'                   => "https://${domain}",
            'security.alternate-file-domain'         => "https://${altdom}",
            'mysql.host'                             => $mysql_host,
            'phpmailer.smtp-host'                    => inline_template('<%= @mail_smarthost.join(";") %>'),
            'metamta.default-address'                => "no-reply@${domain}",
            'metamta.domain'                         => $domain,
            'metamta.reply-handler-domain'           => $domain,
            'repository.default-local-path'          => '/srv/repos',
            'phd.taskmasters'                        => 10,
            'events.listeners'                       => [],
            'diffusion.allow-http-auth'              => true,
            'diffusion.ssh-host'                     => $phab_diffusion_ssh_host,
            'gitblit.hostname'                       => 'git.wikimedia.org',
            'notification.servers'                   => $notification_servers,
        },
        conf_files     => $conf_files,
    }
    # lint:endignore

    # common Apache modules
    include ::apache::mod::rewrite
    include ::apache::mod::headers

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
        dbhost          => $mysql_host,
        dbslave         => $mysql_slave,
        manifest_user   => $passwords::mysql::phabricator::manifest_user,
        manifest_pass   => $passwords::mysql::phabricator::manifest_pass,
        app_user        => $passwords::mysql::phabricator::app_user,
        app_pass        => $passwords::mysql::phabricator::app_pass,
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

    cron { 'phab_dump':
        ensure  => $dump_rsync_ensure,
        command => 'rsync -zpt --bwlimit=40000 -4 /srv/dumps/phabricator_public.dump dataset1001.wikimedia.org::other_misc/ >/dev/null 2>&1',
        user    => 'root',
        minute  => '10',
        hour    => '4',
    }

    # Backup repositories
    backup::set { 'srv-repos': }

    class { 'exim4':
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
        srange => '$CACHE_MISC',
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
        require     => Package[$deploy_target],
    }

    # community metrics mail (T81784, T1003)
    phabricator::logmail {'communitymetrics':
        ensure       => $logmail_ensure,
        script_name  => 'community_metrics.sh',
        rcpt_address => 'wikitech-l@lists.wikimedia.org',
        sndr_address => 'communitymetrics@wikimedia.org',
        monthday     => '1',
        require      => Package[$deploy_target],
    }

    # project changes mail (T85183)
    phabricator::logmail {'projectchanges':
        ensure       => $logmail_ensure,
        script_name  => 'project_changes.sh',
        rcpt_address => [ 'phabricator-reports@lists.wikimedia.org' ],
        sndr_address => 'aklapper@wikimedia.org',
        monthday     => '*',
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
}
