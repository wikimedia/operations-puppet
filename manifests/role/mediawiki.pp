@monitoring::group { 'appserver_eqiad':     description => 'eqiad application servers' }
@monitoring::group { 'api_appserver_eqiad': description => 'eqiad API application servers' }
@monitoring::group { 'imagescaler_eqiad':   description => 'eqiad image scalers' }
@monitoring::group { 'jobrunner_eqiad':     description => 'eqiad jobrunner application servers' }
@monitoring::group { 'videoscaler_eqiad':   description => 'eqiad video scaler' }

@monitoring::group { 'appserver_codfw':     description => 'codfw application servers' }
@monitoring::group { 'api_appserver_codfw': description => 'codfw API application servers' }
@monitoring::group { 'imagescaler_codfw':   description => 'codfw image scalers' }
@monitoring::group { 'jobrunner_codfw':     description => 'codfw jobrunner application servers' }
@monitoring::group { 'videoscaler_codfw':   description => 'codfw video scaler' }

class role::mediawiki::common {
    include ::standard
    include ::geoip
    include ::mediawiki
    include ::mediawiki::nutcracker
    include ::tmpreaper

    ferm::rule { 'skip_nutcracker_conntrack_out':
        desc  => 'Skip outgoing connection tracking for Nutcracker',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => 'proto tcp sport (6379 11212) NOTRACK;',
    }

    ferm::rule { 'skip_nutcracker_conntrack_in':
        desc  => 'Skip incoming connection tracking for Nutcracker',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'proto tcp dport (6379 11212) NOTRACK;',
    }

    ferm::service{ 'ssh_pybal':
        proto  => 'tcp',
        port   => '22',
        srange => '$INTERNAL',
        desc   => 'Allow incoming SSH for pybal health checks',
    }

    if $::site == 'eqiad' {
        monitoring::service { 'mediawiki-installation DSH group':
            description           => 'mediawiki-installation DSH group',
            check_command         => 'check_dsh_groups!mediawiki-installation',
            normal_check_interval => 60,
        }
    }
    $scap_proxies = hiera('dsh::config::scap_proxies',[])
    if member($scap_proxies, $::fqdn) {
        include scap::proxy

        ferm::service { 'rsyncd_scap_proxy':
            proto   => 'tcp',
            port    => '873',
            srange  => '$MW_APPSERVER_NETWORKS',
        }
    }
}

class role::mediawiki::webserver($pool) {
    include ::role::mediawiki::common
    include ::apache::monitoring
    include ::mediawiki::web
    # HACK: Fix to not be different classes!
    if $::realm == 'labs' {
        include ::mediawiki::web::beta_sites
    } else {
        include ::mediawiki::web::sites
    }

    if hiera('has_lvs', true) {
        include ::lvs::configuration
        $ips = $lvs::configuration::service_ips[$pool][$::site]

        class { 'lvs::realserver':
            realserver_ips => $ips,
        }
    }

    ferm::service { 'mediawiki-http':
        proto   => 'tcp',
        notrack => true,
        port    => 'http',
    }

    # allow ssh from deployment hosts
    ferm::rule { 'deployment-ssh':
        ensure => present,
        rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
    }

    # If a service check happens to run while we are performing a
    # graceful restart of Apache, we want to try again before declaring
    # defeat. See T103008.
    monitoring::service { 'appserver http':
        description   => 'Apache HTTP',
        check_command => 'check_http_wikipedia',
        retries       => 2,
    }

    if os_version('ubuntu >= trusty') {
        monitoring::service { 'appserver_http_hhvm':
            description   => 'HHVM rendering',
            check_command => 'check_http_wikipedia_main',
            retries       => 2,
        }

        nrpe::monitor_service { 'hhvm':
            description  => 'HHVM processes',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C hhvm',
        }
    }

}

class role::mediawiki::appserver {
    system::role { 'role::mediawiki::appserver': }

    include ::role::mediawiki::webserver

}

class role::mediawiki::appserver::api {
    system::role { 'role::mediawiki::appserver::api': }

    include ::role::mediawiki::webserver

    # Using fastcgi we need more local ports
    sysctl::parameters { 'raise_port_range':
        values   => {
            'net.ipv4.local_port_range' => '22500 65535',
            'net.ipv4.tcp_tw_reuse'     => '1',
        },
        priority => 90,
    }
}

class role::mediawiki::imagescaler {
    system::role { 'role::mediawiki::imagescaler': }

    # operations/mediawiki-config's CommonSettings.php checks if this file is
    # present. If it is, it raises $wgMaxShellMemory and $wgMaxShellFileSize.
    file { '/etc/wikimedia-image-scaler':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    include ::mediawiki::multimedia
    include ::role::mediawiki::webserver
    include base::firewall
}

class role::mediawiki::videoscaler {
    system::role { 'role::mediawiki::videoscaler': }

    # operations/mediawiki-config's CommonSettings.php checks if this file is
    # present. If it is, it raises $wgMaxShellMemory and $wgMaxShellFileSize.
    file { '/etc/wikimedia-image-scaler':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    include ::role::mediawiki::common
    include ::mediawiki::multimedia
    include ::mediawiki::jobrunner
    include base::firewall
}

class role::mediawiki::jobrunner {
    system::role { 'role::mediawiki::jobrunner': }

    include ::role::mediawiki::common

    include ::mediawiki::jobrunner
}

# monitor the Apple dictionary bridge (T83147)
class role::mediawiki::searchmonitor {

    # https://search.wikimedia.org/?lang=en&site=wikipedia&search=Wikimedia_Foundation&limit=1
    monitoring::service { 'mediawiki-dict-bridge':
        description   => 'Mediawiki Apple Dictionary Bridge',
        check_command => 'check_https_dictbridge',
    }

}

# Class for a subgroup of appservers where we can test experimental features
class role::mediawiki::canary_appserver {
    # salt -G 'canary:appserver' will select servers with this role.'
    salt::grain { 'canary': value => 'appserver' }
    include role::mediawiki::appserver

    # include the deployment scripts because mwscript can occasionally be useful
    # here: T112174
    include scap::scripts
}

# Ditto, for api
class role::mediawiki::appserver::canary_api {
    # salt -G 'canary:api_appserver' will select servers with this role.'
    salt::grain { 'canary': value => 'api_appserver' }
    include role::mediawiki::appserver::api
}

# mediawiki maintenance scripts
class role::mediawiki::maintenance {

    include mediawiki::maintenance::pagetriage
    include mediawiki::maintenance::translationnotifications
    include mediawiki::maintenance::updatetranslationstats
    include mediawiki::maintenance::wikidata
    include mediawiki::maintenance::echo_mail_batch
    include mediawiki::maintenance::parsercachepurging
    include mediawiki::maintenance::cleanup_upload_stash
    include mediawiki::maintenance::tor_exit_node
    include mediawiki::maintenance::update_flaggedrev_stats
    include mediawiki::maintenance::refreshlinks
    include mediawiki::maintenance::update_special_pages
    include mediawiki::maintenance::update_article_count
    include mediawiki::maintenance::purge_abusefilter
    include mediawiki::maintenance::purge_checkuser
    include mediawiki::maintenance::purge_securepoll
    include mediawiki::maintenance::jobqueue_stats

    # (T17434) Periodical run of currently disabled special pages
    include mediawiki::maintenance::updatequerypages

}
