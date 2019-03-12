class profile::mediawiki::common(
    $logstash_host = hiera('logstash_host'),
    $logstash_syslog_port = hiera('logstash_syslog_port'),
    $log_aggregator = hiera('udp2log_aggregator'),
    $deployment_server = hiera('scap::deployment_server'),
){

    # GeoIP is needed for MW
    class { '::geoip': }

    class { '::tmpreaper': }

    # Configure cgroups used by MediaWiki
    class { '::mediawiki::cgroup': }
    # Install all basic support packages for MediaWiki
    class { '::mediawiki::packages': }
    # Install the users needed for MediaWiki
    class { '::mediawiki::users':
        web => 'www-data'
    }
    # Install scap
    class { '::scap':
        deployment_server => $deployment_server,
    }
    # Now install MW-specific scap content
    class { '::mediawiki::scap': }

    # mwrepl
    class { '::mediawiki::mwrepl': }

    class { '::mediawiki::syslog':
        forward_syslog => "${logstash_host}:${logstash_syslog_port}",
        log_aggregator => $log_aggregator,
    }

    # These should properly be included in the role. Bear with me for now.
    include ::profile::mediawiki::hhvm
    include ::profile::mediawiki::php

    file { '/usr/local/bin/mediawiki-firejail-convert':
        source => 'puppet:///modules/mediawiki/mediawiki-firejail-convert',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/firejail/mediawiki-converters.profile':
        source => 'puppet:///modules/mediawiki/mediawiki-converters.profile',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/usr/local/bin/mediawiki-firejail-ghostscript':
        source => 'puppet:///modules/mediawiki/mediawiki-firejail-ghostscript',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # /var/log/mediawiki contains log files for the MediaWiki jobrunner
    # and for various periodic jobs that are managed by cron.
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

    include scap::ferm

    monitoring::service { 'mediawiki-installation DSH group':
        description    => 'mediawiki-installation DSH group',
        check_command  => 'check_dsh_groups!mediawiki-installation',
        check_interval => 60,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Application_servers#Apache_setup_checklist',
    }

}
