# production phabricator instance
#
# filtertags: labs-project-deployment-prep labs-project-phabricator
class role::phabricator::main {

    system::role { 'role::phabricator::main':
        description => 'Phabricator (Main)'
    }

    mailalias { 'root':
        recipient => 'root@wikimedia.org',
    }

    include passwords::phabricator
    include passwords::mysql::phabricator
    include phabricator::monitoring
    include phabricator::mpm
    include ::lvs::realserver
    include ::base::firewall
    include ::apache::mod::remoteip

    # this site's misc-lb caching proxies hostnames
    $cache_misc_nodes = hiera('cache::misc::nodes', [])
    $domain = hiera('phabricator_domain', 'phabricator.wikimedia.org')
    $altdom = hiera('phabricator_altdomain', 'phab.wmfusercontent.org')

    $mysql_host = hiera('phabricator::mysql::master', 'localhost')
    $mysql_slave = hiera('phabricator::mysql::slave', 'localhost')
    $phab_root_dir = '/srv/phab'
    $deploy_target = 'phabricator/deployment'

    # logmail and dumps are only enabled on the active server set in Hiera
    $phabricator_active_server = hiera('phabricator_active_server')
    if $::hostname == $phabricator_active_server {
        $logmail_ensure = 'present'
        $dump_rsync_ensure = 'present'
        $dump_enabled = true
    } else {
        $logmail_ensure = 'absent'
        $dump_rsync_ensure ='absent'
        $dump_enabled = false
    }

    $phab_app_user = hiera('phabricator_app_user', undef)
    $phab_app_pass = hiera('phabricator_app_pass', undef)
    $phab_daemons_user = hiera('phabricator_daemons_user', undef)
    $phab_daemons_pass = hiera('phabricator_daemons_pass', undef)

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

    $phab_mysql_admin_user = hiera('phabricator_admin_user', undef)
    $phab_mysql_admin_pass = hiera('phabricator_admin_pass', undef)

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

    $phab_diffusion_ssh_host = hiera('phabricator_diffusion_ssh_host', 'git-ssh.wikimedia.org')

    $elasticsearch_host = hiera('phabricator_elasticsearch_hostname', 'search.svc.eqiad.wmnet')
    $elasticsearch_port = hiera('phabricator_elasticsearch_port', 9243)
    $elasticsearch_version = hiera('phabricator_elasticsearch_version', '2')
    $elasticsearch_enabled = hiera('phabricator_elasticsearch_enabled', true)

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
                              "${phab_root_dir}/libext/misc/" ],
        settings         => {
            'cluster.search' => [
                {
                    'type' => 'elasticsearch',
                    'hosts' => [
                        {
                            'protocol'  => 'https',
                            'host'      => $elasticsearch_host,
                            'port'      => $elasticsearch_port,
                            'path'      => '/phabricator',
                            'version'   => $elasticsearch_version,
                            'roles'     => {
                                'read'  => $elasticsearch_enabled,
                                'write' => $elasticsearch_enabled,
                            },
                        },
                    ],
                },
                {
                    'type' => 'mysql',
                    'roles' => {
                        'read' => false,
                        'write' => true,
                    }
                },
            ],
            'search.elastic.host'                    => $elasticsearch_host,
            'search.elastic.version'                 => $elasticsearch_version,
            'search.elastic.enabled'                 => $elasticsearch_enabled,
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
        },
        conf_files     => $conf_files,
    }
    # lint:endignore

    # This exists to offer git services
    $vcs_address_ipv4 = hiera('phabricator::vcs::address::v4', undef)
    if $vcs_address_ipv4 != undef {
        interface::ip { 'role::phabricator::main::ipv4':
            interface => 'eth0',
            address   => $vcs_address_ipv4,
            prefixlen => '21',
        }
    }
    $vcs_address_ipv6 = hiera('phabricator::vcs::address::v6', undef)
    if $vcs_address_ipv6 != undef {
        interface::ip { 'role::phabricator::main::ipv6':
            interface => 'eth0',
            address   => $vcs_address_ipv6,
            prefixlen => '128',
            # mark as deprecated = never pick this address unless explicitly asked
            options   => 'preferred_lft 0',
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
    include exim4::ganglia

    class { '::phabricator::mailrelay':
        default                 => {
            security     => 'users',
            maint        => false,
            taskcreation => "task@${domain}",
        },
        direct_comments_allowed => {
            ops-codfw   => '*',
            ops-eqiad   => '*',
            ops-esams   => '*',
            ops-ulsfo   => '*',
            domains     => 'markmonitor.com,wikimedia.org',
            procurement => 'cdw.com,cyrusone.com,dasher.com,dell.com,globalsign.com,optiv.com,unitedlayer.com,us.ntt.net,wikimedia.org,zayo.com',
        },
        phab_bot                => {
            root_dir    => '/srv/phab/phabricator/',
            username    => 'emailbot',
            host        => "https://${domain}/api/",
            certificate => $passwords::phabricator::emailbot_cert,
        },
    }

    ferm::service { 'phabmain_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'phabmain_https':
        proto => 'tcp',
        port  => '443',
    }

    # receive mail from mail smarthosts
    ferm::service { 'phabmain-smtp':
        port   => '25',
        proto  => 'tcp',
        srange => inline_template('(<%= @mail_smarthost.map{|x| "@resolve(#{x})" }.join(" ") %>)'),
    }

    ferm::service { 'phabmain-smtp_ipv6':
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
    # disabled due to maintenance: T138460, re-enabled T139950
    phabricator::logmail {'communitymetrics':
        ensure       => $logmail_ensure,
        script_name  => 'community_metrics.sh',
        rcpt_address => 'wikitech-l@lists.wikimedia.org',
        sndr_address => 'communitymetrics@wikimedia.org',
        monthday     => '1',
        require      => Package[$deploy_target],
    }

    # project changes mail (T85183)
    # disabled due to maintenance: T138460, re-enabled T139950
    phabricator::logmail {'projectchanges':
        ensure       => $logmail_ensure,
        script_name  => 'project_changes.sh',
        rcpt_address => [ 'phabricator-reports@lists.wikimedia.org' ],
        sndr_address => 'aklapper@wikimedia.org',
        monthday     => '*',
        weekday      => 1, # Monday
        require      => Package[$deploy_target],
    }

    include role::phabricator::rsync
}
