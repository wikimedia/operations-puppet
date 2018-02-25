class profile::openstack::base::wikitech::web(
    $osm_host = hiera('profile::openstack::base::wikitech::web::osm_host'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $webserver_hostname_aliases = hiera('profile::openstack::base::wikitech::webserver_hostname_aliases'),
    $wikidb = hiera('profile::openstack::base::wikitech::db_name'),
    $wikitech_nova_ldap_proxyagent_pass = hiera('profile::openstack::base::ldap_proxyuser_pass'),
    $wikitech_nova_ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    ) {

    # What follows is a modified copy/paste of ::mediawiki.
    #  modified to avoid pulling in the webserver bits which conflict
    #  with our httpd-using horizon and striker web conf.

    include ::mediawiki::cgroup
    include ::mediawiki::packages
    include ::mediawiki::scap
    include ::mediawiki::users
    include ::mediawiki::syslog
    include ::mediawiki::php
    include ::mediawiki::mwrepl

    # ::mediawiki::hhvm is the source of the conflict, so find a deconstruction below
    #include ::mediawiki::hhvm

    # This profile is used to contain the convert command of imagemagick using
    # firejail Profiles specific to the image/video scalers are handled via
    # mediawiki::firejail
    file { '/etc/firejail/mediawiki-imagemagick.profile':
        source  => 'puppet:///modules/mediawiki/mediawiki-imagemagick.profile',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['firejail'],
    }

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
    # -- end copy/paste of ::mediawiki --

    # Here begins a deconstruction of mediawiki::hhvm
    include ::hhvm::admin
    include ::hhvm::monitoring
    #include ::hhvm::debug
    include ::mediawiki::hhvm::housekeeping

    # Derive HHVM's thread count by taking the smallest of:
    #  - the memory of the system divided by a typical thread memory allocation
    #  - processor count * 4 (we have hyperthreading)
    $max_threads = min(
        floor(to_bytes($::memorysize) / to_bytes('120M')),
        $::processorcount*4)

    # Number of malloc arenas to use, see T151702
    # HHVM defaults to 1
    # We want to have the same number of arenas as our threads
    $malloc_arenas = $max_threads

    class { '::hhvm':
        # lint:ignore:arrow_alignment
        user          => $::mediawiki::users::web,
        group         => $::mediawiki::users::web,
        fcgi_settings => {
            # See https://docs.hhvm.com/hhvm/configuration/INI-settings
            hhvm => {
                xenon          => {
                    period => to_seconds('10 minutes'),
                },
                error_handling => {
                    call_user_handler_on_fatals => true,
                },
                server         => {
                    source_root           => '/srv/mediawiki/docroot',
                    error_document500     => '/srv/mediawiki/errorpages/hhvm-fatal-error.php',
                    error_document404     => '/srv/mediawiki/errorpages/404.php',
                    # Currently testing on Beta Cluster: auto_prepend_file (T180183)
                    request_init_document => '/srv/mediawiki/wmf-config/HHVMRequestInit.php',
                    thread_count          => $max_threads,
                    ip                    => '127.0.0.1',
                },
                pcre_cache_type => 'lru',
            },
            curl => {
                namedPools   => 'cirrus-eqiad,cirrus-codfw',
                # ugly hack to work around colision in the hash
                'namedPools.cirrus-codfw' => {
                    size => '20',
                },
                'namedPools.cirrus-eqiad' => {
                    size => '20',
                },
            },
        },
        cli_settings => {
            curl => {
                namedPools => 'cirrus-eqiad,cirrus-codfw',
            },
        },
        malloc_arenas => $malloc_arenas,
        # lint:endignore
    }

    # furl is a cURL-like command-line tool for making FastCGI requests.
    # See `furl --help` for documentation and usage.

    file { '/usr/local/bin/furl':
        source => 'puppet:///modules/mediawiki/furl',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    if os_version('ubuntu >= trusty') {
        # Provision an Upstart task (a short-running process) that runs
        # when HHVM is started and that warms up the JIT by repeatedly
        # requesting URLs read from /etc/hhvm/warmup.urls.

        $warmup_urls = [ 'http://en.wikipedia.org/wiki/Special:Random' ]

        file { '/etc/hhvm/warmup.urls':
            content => join($warmup_urls, "\n"),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
        }

        file { '/etc/init/hhvm-warmup.conf':
            source  => 'puppet:///modules/mediawiki/hhvm-warmup.conf',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => File['/usr/local/bin/furl', '/etc/hhvm/warmup.urls'],
            before  => Service['hhvm'],
        }
    }

    # Note: the warmup process should be revisited and is thus not implemented on
    # Debian/systemd at the moment.

    # Use Debian's Alternatives system to mark HHVM as the default PHP
    # implementation for this system. This makes /usr/bin/php a symlink
    # to /usr/bin/hhvm.

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
        before  => Service['hhvm'],
    }
    # Here ends the deconstruction of mediawiki::hhvm

    class {'::mediawiki::multimedia':}
    class {'::profile::backup::host':}

    # For Math extensions file (T126628)
    file { '/srv/math-images':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    class { '::openstack::wikitech::web':
        webserver_hostname                 => $osm_host,
        webserver_hostname_aliases         => $webserver_hostname_aliases,
        wikidb                             => $wikidb,
        wikitech_nova_ldap_proxyagent_pass => $wikitech_nova_ldap_proxyagent_pass,
        wikitech_nova_ldap_user_pass       => $wikitech_nova_ldap_user_pass,
    }

    ferm::service { 'wikitech_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }
}
