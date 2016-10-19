# production phabricator instance
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
    include base::firewall
    include ::apache::mod::remoteip

    # this site's misc-lb caching proxies hostnames
    $cache_misc_nodes = hiera('cache::misc::nodes', [])
    $domain = 'phabricator.wikimedia.org'
    $altdom = 'phab.wmfusercontent.org'
    $mysql_host = 'm3-master.eqiad.wmnet'
    $mysql_slave = 'm3-slave.eqiad.wmnet'
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

    # lint:ignore:arrow_alignment
    class { '::phabricator':
        deploy_target    => $deploy_target,
        phabdir          => $phab_root_dir,
        serveraliases    => [ $altdom,
                              'bugzilla.wikimedia.org',
                              'bugs.wikimedia.org' ],
        trusted_proxies  => $cache_misc_nodes[$::site],
        mysql_admin_user => $passwords::mysql::phabricator::admin_user,
        mysql_admin_pass => $passwords::mysql::phabricator::admin_pass,
        libraries        => [ "${phab_root_dir}/libext/Sprint/src",
                              "${phab_root_dir}/libext/security/src",
                              "${phab_root_dir}/libext/misc/" ],
        settings         => {
            'darkconsole.enabled'                    => false,
            'differential.allow-self-accept'         => true,
            'phabricator.base-uri'                   => "https://${domain}",
            'security.alternate-file-domain'         => "https://${altdom}",
            'mysql.user'                             => $passwords::mysql::phabricator::app_user,
            'mysql.pass'                             => $passwords::mysql::phabricator::app_pass,
            'mysql.host'                             => $mysql_host,
            'phpmailer.smtp-host'                    => inline_template('<%= @mail_smarthost.join(";") %>'),
            'metamta.default-address'                => "no-reply@${domain}",
            'metamta.domain'                         => $domain,
            'metamta.maniphest.public-create-email'  => "task@${domain}",
            'metamta.reply-handler-domain'           => $domain,
            'repository.default-local-path'          => '/srv/repos',
            'phd.taskmasters'                        => 10,
            'events.listeners'                       => [],
            'diffusion.allow-http-auth'              => true,
            'diffusion.ssh-host'                     => 'git-ssh.wikimedia.org',
            'gitblit.hostname'                       => 'git.wikimedia.org',
        },
    }
    # lint:endignore

    # This exists to offer git services
    interface::ip { 'role::phabricator::main::ipv4':
        interface => 'eth0',
        address   => '10.64.32.186',
        prefixlen => '21',
    }
    interface::ip { 'role::phabricator::main::ipv6':
        interface => 'eth0',
        address   => '2620:0:861:103:10:64:32:186',
        prefixlen => '128',
        # mark as deprecated = never pick this address unless explicitly asked
        options   => 'preferred_lft 0',
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

    $emailbotcert = $passwords::phabricator::emailbot_cert
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
            certificate => $emailbotcert,
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

    ferm::rule { 'ssh_public':
        rule => 'saddr (0.0.0.0/0 ::/0) daddr (10.64.32.186/32 208.80.154.250/32 2620:0:861:103:10:64:32:186/128 2620:0:861:ed1a::3:16/128) proto tcp dport (22) ACCEPT;',
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
}
