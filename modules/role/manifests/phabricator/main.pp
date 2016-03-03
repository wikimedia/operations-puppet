# production phabricator instance
class role::phabricator::main {

    system::role { 'role::phabricator::main':
        description => 'Phabricator (Main)'
    }

    mailalias { 'root':
        recipient => 'root@wikimedia.org',
    }

    include passwords::phabricator
    include role::phabricator::config
    include phabricator::monitoring
    include phabricator::mpm
    include lvs::realserver
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

    # lint:ignore:arrow_alignment
    class { '::phabricator':
        deploy_target    => $deploy_target,
        phabdir          => $phab_root_dir,
        serveralias      => $altdom,
        trusted_proxies  => $cache_misc_nodes[$::site],
        mysql_admin_user => $role::phabricator::config::mysql_adminuser,
        mysql_admin_pass => $role::phabricator::config::mysql_adminpass,
        libraries        => [ "${phab_root_dir}/libext/Sprint/src",
                              "${phab_root_dir}/libext/security/src",
                              "${phab_root_dir}/libext/misc/" ],
        extensions       => [ ],
        settings         => {
            'darkconsole.enabled'                    => false,
            'phabricator.base-uri'                   => "https://${domain}",
            'security.alternate-file-domain'         => "https://${altdom}",
            'mysql.user'                             => $role::phabricator::config::mysql_appuser,
            'mysql.pass'                             => $role::phabricator::config::mysql_apppass,
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
        manifest_user   => $role::phabricator::config::mysql_maniphestuser,
        manifest_pass   => $role::phabricator::config::mysql_maniphestpass,
        app_user        => $role::phabricator::config::mysql_appuser,
        app_pass        => $role::phabricator::config::mysql_apppass,
        bz_user         => $role::phabricator::config::bz_user,
        bz_pass         => $role::phabricator::config::bz_pass,
        rt_user         => $role::phabricator::config::rt_user,
        rt_pass         => $role::phabricator::config::rt_pass,
        phabtools_cert  => $role::phabricator::config::phabtools_cert,
        phabtools_user  => $role::phabricator::config::phabtools_user,
        gerritbot_token => $role::phabricator::config::gerritbot_token,
        dump            => true,
        require         => Package[$deploy_target]
    }

    cron { 'phab_dump':
        ensure  => present,
        command => 'rsync -zpt --bwlimit=40000 -4 /srv/dumps/phabricator_public.dump dataset1001.wikimedia.org::other_misc/ >/dev/null 2>&1',
        user    => 'root',
        minute  => '10',
        hour    => '4',
    }

    # Backup repositories
    backup::set { 'srv-repos': }

    class { 'exim4':
        variant => 'heavy',
        config  => template('exim/exim4.conf.phab.erb'),
        filter  => template('exim/system_filter.conf.erb'),
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

    # redirect bugzilla URL patterns to phabricator
    # handles translation of bug numbers to maniphest task ids
    phabricator::redirector { "redirector.${domain}":
        mysql_user  => $role::phabricator::config::mysql_maniphestuser,
        mysql_pass  => $role::phabricator::config::mysql_maniphestpass,
        mysql_host  => $mysql_host,
        rootdir     => '/srv/phab',
        field_index => '4rRUkCdImLQU',
        phab_host   => $domain,
        alt_host    => $altdom,
        require     => Package[$deploy_target],
    }

    # community metrics mail (T81784, T1003)
    phabricator::logmail {'communitymetrics':
        script_name  => 'community_metrics.sh',
        rcpt_address => 'wikitech-l@lists.wikimedia.org',
        sndr_address => 'communitymetrics@wikimedia.org',
        monthday     => '1',
        require      => Package[$deploy_target],
    }

    # project changes mail (T85183)
    phabricator::logmail {'projectchanges':
        script_name  => 'project_changes.sh',
        rcpt_address => [ 'aklapper@wikimedia.org', 'krenair@gmail.com' ],
        sndr_address => 'aklapper@wikimedia.org',
        monthday     => '*',
        weekday      => 1, # Monday
        require      => Package[$deploy_target],
    }
}
