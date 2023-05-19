# SPDX-License-Identifier: Apache-2.0
# web server hosting https://doc.wikimedia.org
class profile::doc (
    Stdlib::Fqdn        $active_host  = lookup('profile::doc::active_host'),
    Array[Stdlib::Fqdn] $all_hosts    = lookup('profile::doc::all_hosts'),
    Stdlib::Unixpath    $wmf_doc_path = lookup('profile::doc::wmf_doc_path', {'default_value' => '/srv/doc'}),
    Array[Stdlib::Host] $contint_hosts = lookup('jenkins_controller_hosts'),
) {

    $deploy_user = 'deploy-ci-docroot'

    scap::target { 'integration/docroot':
        deploy_user => $deploy_user,
    }

    if debian::codename::eq('buster') {
        apt::repository { 'wikimedia-php74':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/php74',
        }
    }

    $php_version = debian::codename() ? {
        'buster'   => '7.4',
        'bullseye' => '7.4',  # provided above by component/php74
        default    => fail("${module_name} not supported by ${debian::codename()}")
    }
    $php = "php${php_version}"

    ensure_packages(["${php}-fpm", "${php}-xml"])

    # The Debian package does not provide a `php-fpm` service and we need scap
    # to be able to restart the service without relying on a version number.
    $restart_cmd = "/bin/systemctl restart ${php}-fpm"

    # scap deployment swap symlink which confuses PHP opcache. On promote
    # stage, scap invoke this script to clear the opcache.
    file { '/usr/local/sbin/restart-php-fpm-unsafe':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => "#!/bin/bash\nexec sudo -u root -- ${restart_cmd}\n"
    }

    sudo::user { 'deploy_restart_fpm':
        user       => $deploy_user,
        privileges => ["ALL = NOPASSWD: ${restart_cmd}"],
    }

    class { '::httpd':
        modules => ['setenvif',
                    'headers',
                    'rewrite',
                    'proxy',
                    'proxy_fcgi'],
    }

    class { '::httpd::mpm':
        mpm    => 'worker',
        source => 'puppet:///modules/profile/doc/httpd_worker.conf'
    }

    httpd::conf { 'wmf_doc_path':
        priority => 40,
        content  => "Define WMF_DOC_PATH ${wmf_doc_path}\nDefine WMF_DOC_PHP_VERSION ${php}",
    }

    # Apache configuration for doc.wikimedia.org
    httpd::site { 'doc.wikimedia.org':
        source => 'puppet:///modules/profile/doc/httpd-doc.wikimedia.org.conf'
    }

    profile::auto_restarts::service { "${php}-fpm": }

    ferm::service { 'doc-http':
        proto  => 'tcp',
        port   => '80',
        srange => '($CACHES $DEPLOYMENT_HOSTS)',
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }

    systemd::sysuser { 'doc-uploader':
      ensure      => present,
      id          => '922:922',
      description => 'doc-uploader system user',
    }

    file { '/srv/doc':
        ensure => 'directory',
        owner  => 'doc-uploader',
        group  => 'doc-uploader',
        mode   => '0755',
    }

    # This is to prevent monitoring from alerting. The directory is empty until
    # we have completed the migration of generated documentations. Once done,
    # we should remove the file.
    file { '/srv/doc/BACKMEUP':
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => 'Placeholder for Bacula',
    }

    backup::set { 'srv-doc': }

    class { '::rsync::server': }

    $is_active = $::fqdn == $active_host
    $ensure_on_active = $is_active.bool2str('present', 'absent')
    $gitlab_runner_hosts = wmflib::role::hosts('gitlab_runner')

    file { '/etc/rsync.d/secrets':
      ensure  => $ensure_on_active,
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => secret('doc/secrets'),
    }

    rsync::server::module { 'doc-gitlab':
        ensure         => $ensure_on_active,
        comment        => 'Docroot of https://doc.wikimedia.org/',
        read_only      => 'no',
        path           => '/srv/doc',
        uid            => 'doc-uploader',
        gid            => 'doc-uploader',
        incoming_chmod => 'D775,F664',
        hosts_allow    => $gitlab_runner_hosts,
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
        auth_users     => ['gitlab'],
        secrets_file   => '/etc/rsync.d/secrets',
        require        => [
            User['doc-uploader'],
            File['/srv/doc'],
            File['/etc/rsync.d/secrets'],
        ],
    }

    rsync::server::module { 'doc':
        ensure         => $ensure_on_active,
        comment        => 'Docroot of https://doc.wikimedia.org/',
        read_only      => 'no',
        path           => '/srv/doc',
        uid            => 'doc-uploader',
        gid            => 'doc-uploader',
        incoming_chmod => 'D775,F664',
        hosts_allow    => $contint_hosts,
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
        require        => [
            User['doc-uploader'],
            File['/srv/doc'],
        ],
    }

    rsync::server::module { 'doc-between-nodes':
        ensure         => $is_active.bool2str('absent', 'present'),
        path           => '/srv/doc',
        read_only      => 'no',
        hosts_allow    => [$active_host],
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
    }

    $all_hosts.each |Stdlib::Fqdn $other_host| {
        if $::fqdn != $other_host {
            systemd::timer::job { "rsync-doc-${other_host}":
                ensure      => $ensure_on_active,
                user        => 'root',
                description => 'rsync documentation to a non-active server',
                command     => "/usr/bin/rsync -avp --delete /srv/doc/ rsync://${other_host}/doc-between-nodes",
                interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '1h'},
            }

        }

        prometheus::blackbox::check::http { $other_host:
            server_name        => 'doc.wikimedia.org',
            instance_label     => $other_host,
            team               => 'serviceops-collab',
            severity           => 'task',
            path               => '/',
            ip_families        => ['ip4'],
            force_tls          => true,
            body_regex_matches => ['open-source'],
        }
    }
    profile::auto_restarts::service { 'rsync': }

    # We want to _include_ the E_DEPRECATED php logs, T325245
    file { 'php-logging-confd':
        ensure  => present,
        path    => "/etc/php/${php_version}/fpm/conf.d/99-logging-levels",
        owner   => 'root',
        mode    => '0644',
        content => 'error_reporting = E_ALL & ~E_STRICT',
    }

    rsyslog::input::file { 'doc-apache2-error':
        path => '/var/log/apache2/*error*.log',
    }

    rsyslog::input::file { 'doc-apache2-access':
        path => '/var/log/apache2/*access*.log',
    }

    rsyslog::input::file { 'doc-phpfpm-error':
        path => '/var/log/php*-fpm.log',
    }

}
