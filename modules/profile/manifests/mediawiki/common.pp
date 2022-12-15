class profile::mediawiki::common(
    Stdlib::Host $logstash_host = lookup('logstash_host'),
    Stdlib::Port $logstash_syslog_port = lookup('logstash_syslog_port'),
    String $log_aggregator = lookup('udp2log_aggregator'),
    Array[Wmflib::Php_version] $php_versions = lookup('profile::mediawiki::php::php_versions', {'default_value' => ['7.2']}),
    Optional[Wmflib::Ensure] $php_restarts = lookup('profile::mediawiki::php::restarts::ensure', {'default_value' => undef}),
    Optional[Boolean] $fetch_ipinfo_dbs = lookup('profile::mediawiki::common::fetch_ipinfo_dbs', {'default_value' => false}),
){
    # Enable the memory cgroup
    require ::profile::base::memory_cgroup
    # Require system users that might be used by scap or other processes
    require ::profile::mediawiki::system_users
    # GeoIP is needed for MW
    class { '::geoip':
        fetch_ipinfo_dbs => $fetch_ipinfo_dbs,
    }

    # Enable systemd coredump on all servers running mediawiki
    # Whether php7 will produce coredumps is configurable through
    # rlimit_core in php.ini. Coredumps will be found under
    # /var/lib/systemd/coredump
    class { '::systemd::coredump':
        ensure => present,
    }

    # Configure cgroups used by MediaWiki
    class { '::mediawiki::cgroup': }
    # Install all basic support packages for MediaWiki
    class { '::mediawiki::packages': }
    # Install the users needed for MediaWiki
    if $php_restarts {
        # We need to add the ability to restart all php fpms or just one of them.
        $restart_all = [
            'ALL = (root) NOPASSWD: /usr/local/sbin/restart-php-fpm-all',
            'ALL = (root) NOPASSWD: /usr/local/sbin/restart-php-fpm-all --force'
        ]
        $extra_privileges = $restart_all + $php_versions.map |$v| {
            $pn = php::fpm::programname($v)
            [
            "ALL = (root) NOPASSWD: /usr/local/sbin/check-and-restart-php ${pn} *",
            "ALL = (root) NOPASSWD: /usr/local/sbin/restart-${pn} --force",
            ]
        }.flatten
        class { '::mediawiki::users':
            web              => 'www-data',
            extra_privileges => $extra_privileges,
        }
    } else {
        class { '::mediawiki::users':
            web => 'www-data'
        }
    }

    # Install scap
    include ::profile::mediawiki::scap_client
    # Monitor mediawiki versions (T242023)
    include ::profile::mediawiki::monitor_versions

    class { '::mediawiki::syslog':
        log_aggregator => $log_aggregator,
    }

    include ::profile::rsyslog::udp_localhost_compat
    include ::profile::mediawiki::php

    # furl is a cURL-like command-line tool for making FastCGI requests.
    # See `furl --help` for documentation and usage.

    file { '/usr/local/bin/furl':
        source => 'puppet:///modules/mediawiki/furl',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }


    file { '/usr/local/bin/mediawiki-firejail-convert':
        source => 'puppet:///modules/mediawiki/mediawiki-firejail-convert.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/firejail/mediawiki.local':
        source => 'puppet:///modules/mediawiki/firejail-mediawiki.profile',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/firejail/mediawiki-converters.profile':
        source => 'puppet:///modules/mediawiki/mediawiki-converters.profile',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/usr/local/bin/mediawiki-firejail-ghostscript':
        source => 'puppet:///modules/mediawiki/mediawiki-firejail-ghostscript.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # /var/log/mediawiki contains log files for the MediaWiki jobrunner
    # and for various periodic jobs that are managed by Puppet/systemd timers
    file { '/var/log/mediawiki':
        ensure => directory,
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0644',
    }

    # Script to use for decommissioning a machine and move it to role::system::spare
    file { '/root/decommission_appserver':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
        source => 'puppet:///modules/mediawiki/decommission_appserver.sh',
    }


    # TODO: move to profile::mediawiki::webserver ?
    ferm::service{ 'ssh_pybal':
        proto  => 'tcp',
        port   => '22',
        srange => '$PRODUCTION_NETWORKS',
        desc   => 'Allow incoming SSH for pybal health checks',
    }

    # Allow sockets in TIME_WAIT state to be re-used.
    # This helps prevent exhaustion of ephemeral port or conntrack sessions.
    # See <http://vincent.bernat.im/en/blog/2014-tcp-time-wait-state-linux.html>
    sysctl::parameters { 'tcp_tw_reuse':
        values => { 'net.ipv4.tcp_tw_reuse' => 1 },
    }

    # Go faster (T315398)
    class { 'cpufrequtils': }

    monitoring::service { 'mediawiki-installation DSH group':
        description    => 'mediawiki-installation DSH group',
        check_command  => 'check_dsh_groups!mediawiki-installation',
        check_interval => 60,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_dsh_groups',
    }

}
