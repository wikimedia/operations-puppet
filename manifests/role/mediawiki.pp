# role/apaches.pp

# Virtual monitor group resources for the monitoring server
@monitor_group { "appserver_eqiad": description => "eqiad application servers" }
@monitor_group { "appserver_pmtpa": description => "pmtpa application servers" }
@monitor_group { "api_appserver_eqiad": description => "eqiad API application servers" }
@monitor_group { "api_appserver_pmtpa": description => "pmtpa API application servers" }
@monitor_group { "bits_appserver_eqiad": description => "eqiad Bits application servers" }
@monitor_group { "bits_appserver_pmtpa": description => "pmtpa Bits application servers" }
@monitor_group { "imagescaler_eqiad": description => "eqiad image scalers" }
@monitor_group { "imagescaler_pmtpa": description => "pmtpa image scalers" }
@monitor_group { "jobrunner_eqiad": description => "eqiad jobrunner application servers" }
@monitor_group { "jobrunner_pmtpa": description => "pmtpa jobrunner application servers" }
@monitor_group { "videoscaler_pmtpa": description => "pmtpa video scaler" }
@monitor_group { "videoscaler_eqiad": description => "eqiad video scaler" }

class role::mediawiki {

    $mediawiki_log_aggregator = $::realm ? {
        'production' => 'fluorine.eqiad.wmnet:8420',
        'labs'       => "deployment-bastion.${::site}.wmflabs:8420",
    }

    class configuration::php {
        include role::mediawiki

        class { '::mediawiki::config::php':
            fatal_log_file => "udp://${role::mediawiki::mediawiki_log_aggregator}",
        }
    }

# Class: role::mediawiki
#
# This class installs a mediawiki application server
#
# Parameters:
#   - $lvs_pool:
#       Determines lvsrealserver IP(s) that the host will receive.
#       From lvs::configuration::$lvs_service_ips
    class common(
        $lvs_pool = undef,
        ) {

        include standard

        if $::realm == 'production' {
            include admins::roots
            include admins::mortals
            include geoip
            include ::mediawiki

            nrpe::monitor_service { "twemproxy":
                description => "twemproxy process",
                nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -u nobody -C nutcracker"
            }
            nrpe::monitor_service { 'twemproxy port':
                description => 'twemproxy port',
                nrpe_command  => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 11211 --timeout=2',
            }
        }

        if $::realm == 'labs' {
            # MediaWiki configuration specific to labs instances ('beta' project)
            include ::beta::common
            include ::mediawiki

            # Eqiad instances do not mount additional disk space
            include labs_lvm
            labs_lvm::volume { 'second-local-disk': mountat => '/srv' }

            # FIXME: Each host that has this role applied must also be
            # manually added to the dsh group file found in
            # modules/beta/files/dsh/group/mediawiki-installation or scap will
            # not communicate with that host.
            class { '::beta::scap::target':
              require => Labs_lvm::Volume['second-local-disk'],
            }

        }

        if $lvs_pool != undef {
            include lvs::configuration
            class { "lvs::realserver": realserver_ips => $lvs::configuration::lvs_service_ips[$::realm][$lvs_pool][$::site] }
        }

        if $::realm == 'production' {
            deployment::target { "mediawiki": }
        }
    }

    # This class installs everything necessary for an apache webserver
    class webserver($maxclients="40") {
        include ::mediawiki,
            ::mediawiki::pybal_check,
            role::mediawiki,
            role::mediawiki::configuration::php

        class { '::mediawiki::web':
            maxclients => $maxclients,
        }

        class { '::mediawiki::syslog':
            apache_log_aggregator => $role::mediawiki::mediawiki_log_aggregator,
        }

        monitor_service { "appserver http":
            description => "Apache HTTP",
            check_command => $::realm ? {
                'production' => "check_http_wikipedia",
                'labs' => "check_http_url!commons.wikimedia.beta.wmflabs.org|http://commons.wikimedia.beta.wmflabs.org/wiki/Main_Page"
                }
        }

        ## ganglia module for apache webservers
        file {
            "/usr/lib/ganglia/python_modules/apache_status.py":
                owner  => 'root',
                group  => 'root',
                mode   => '0444',
                source => 'puppet:///files/ganglia/plugins/apache_status.py',
                notify => Service['gmond'];
            "/etc/ganglia/conf.d/apache_status.pyconf":
                owner  => 'root',
                group  => 'root',
                mode   => '0555',
                source => 'puppet:///files/ganglia/plugins/apache_status.pyconf',
                notify => Service['gmond'];
        }
    }

    ## prod role classes
    class appserver{
        system::role { "role::mediawiki::appserver": description => "Standard Apache Application server" }

        class { "role::mediawiki::common": lvs_pool => "apaches" }

        if $::site == "eqiad" and $::processorcount == "16" {
            $maxclients = "60"
        }
        elsif $::processorcount == "12" or $::processorcount == "24" {
            $maxclients = "50"
        }
        else {
            $maxclients = "40"
        }
        class { "role::mediawiki::webserver": maxclients => $maxclients }
    }
    # role class specifically for test.w.o apache(s)
    class appserver::test{
        system::role { "role::mediawiki::appserver::test": description => "Test Apache Application server" }

        class { "role::mediawiki::common": lvs_pool => "apaches" }

        class { "role::mediawiki::webserver": maxclients => "100" }
    }
    # Class for the beta project
    # The Apaches instances act as webserver AND imagescalers. We cannot
    # apply both roles cause puppet will complains about a duplicate class
    # definition for role::mediawiki::common
    class appserver::beta{
        system::role { "role::mediawiki::appserver::beta": description => "Beta Apache Application server" }

        class { "role::mediawiki::common": }

        include ::beta::hhvm

        include role::mediawiki::webserver

        # Load the class just like the role::mediawiki::imagescaler
        # role.
        include ::imagescaler::cron,
            ::imagescaler::packages,
            ::imagescaler::files

        # Beta application servers have some ferm DNAT rewriting rules (bug
        # 45868) so we have to explicitly allow http (port 80)
        ferm::service { 'http':
            proto => 'tcp',
            port  => 'http'
        }

    }
    class appserver::api{
        system::role { "role::mediawiki::appserver::api": description => "Api Apache Application server" }

        class { "role::mediawiki::common": lvs_pool => "api" }

        class { "role::mediawiki::webserver": maxclients => "100" }
    }
    class appserver::bits{
        system::role { "role::mediawiki::appserver::bits": description => "Bits Apache Application server" }

        class { "role::mediawiki::common": lvs_pool => "apaches" }

        class { "role::mediawiki::webserver": maxclients => "100" }
    }
    class imagescaler{
        system::role { "role::mediawiki::imagescaler": description => "Imagescaler Application server" }

        class { "role::mediawiki::common": lvs_pool => "rendering" }

        class { "role::mediawiki::webserver": maxclients => "18" }

        # When adding class there, please also update the appserver::beta
        # class which mix both webserver and imagescaler roles.
        include ::imagescaler::cron,
            ::imagescaler::packages,
            ::imagescaler::files
    }
    class videoscaler( $run_jobs_enabled = true ){
        system::role { "role::mediawiki::videoscaler": description => "TMH Jobrunner Server" }

        include role::mediawiki::common

        include ::imagescaler::cron
        include ::imagescaler::packages,
        include ::imagescaler::files

        class {"::mediawiki::jobrunner":
            run_jobs_enabled => $run_jobs_enabled,
            dprioprocs => 5,
            iprioprocs => 0,
            procs_per_iobound_type => 0,
            type => "webVideoTranscode",
            timeout => 14400,
            extra_args => "-v 0"
        }

        include ::mediawiki::config::base,
            ::mediawiki::packages,
            role::mediawiki::configuration::php

        # dependency for wikimedia-task-appserver
        exec { 'videoscaler-apache-service-stopped':
            command => '/etc/init.d/apache2 stop',
            onlyif  => '/etc/init.d/apache2 status',
        }
    }
    class jobrunner( $run_jobs_enabled = true ){
        system::role { "role::mediawiki::jobrunner": description => "Standard Jobrunner Server" }

        include ::mediawiki

        include role::mediawiki::common

        if $::realm == 'production' {
            if $::hostname !~ /^tmh/ {
                class { '::mediawiki::jobrunner':
                    dprioprocs             => 17,
                    iprioprocs             => 6,
                    procs_per_iobound_type => 5,
                    run_jobs_enabled       => $run_jobs_enabled,
                }
            }
        } else {
            class { '::mediawiki::jobrunner':
                dprioprocs             => 5,
                iprioprocs             => 3,
                procs_per_iobound_type => 2,
                run_jobs_enabled       => $run_jobs_enabled,
            }
        }

        include ::mediawiki::config::base,
            ::mediawiki::packages,
            role::mediawiki::configuration::php

        # dependency for wikimedia-task-appserver
        exec { 'jobrunner-apache-service-stopped':
            command => '/etc/init.d/apache2 stop',
            onlyif  => '/etc/init.d/apache2 status',
        }
    }

    # Class for servers which run MW maintenance scripts.
    # Maintenance servers are sometimes dual-purpose with misc apache, so the
    # apache service installed by wikimedia-task-appserver is not disabled here.
    class maintenance {
        include role::mediawiki::common

        include ::mediawiki::config::base,
            ::mediawiki::packages,
            role::mediawiki::configuration::php
    }
}
