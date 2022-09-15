# all things common to Wikimedia releases* servers
class profile::releases::common(
    Stdlib::Fqdn $sitename = lookup('profile::releases::mediawiki::sitename'),
    Stdlib::Host $deployment_server = lookup('deployment_server'),
    Stdlib::Fqdn $primary_server = lookup('releases_server'),
    Array[Stdlib::Fqdn] $secondary_servers = lookup('releases_servers_failover'),
    String $server_admin = lookup('profile::releases::mediawiki::server_admin'),
){

    # T205037
    # $motd_ensure = mediawiki::state('primary_dc') ? {
    #     $::site => 'absent',
    #     default => 'present',
    # }

    # when there is more than one releases server per DC
    # we can't rely on primary_dc alone
    $motd_ensure = $primary_server ? {
        $::fqdn => 'absent',
        default => 'present',
    }

    motd::script { 'rsync_source_warning':
        ensure   => $motd_ensure,
        priority => 1,
        content  => template('role/releases/rsync_source_warning.motd.erb'),
    }

    $all_secondary_servers = join($secondary_servers, ' ')
    $all_releases_servers = "${primary_server} ${all_secondary_servers}"
    $all_releases_servers_array = split($all_releases_servers, ' ')

    $all_releases_servers_array.each |String $releases_server| {
        unless $primary_server == $releases_server {
            # automatically sync relases files to all secondary
            # servers and ensure they are real mirrors of each other
            rsync::quickdatacopy { "srv-org-wikimedia-releases-${releases_server}":
              ensure      => present,
              auto_sync   => true,
              delete      => true,
              source_host => $primary_server,
              dest_host   => $releases_server,
              module_path => '/srv/org/wikimedia/releases',
            }
            # allow syncing jenkins data between servers for migrations
            # but do not automatically do it
            rsync::quickdatacopy { "var-lib-jenkins-${releases_server}":
              ensure      => present,
              auto_sync   => false,
              delete      => true,
              source_host => $primary_server,
              dest_host   => $releases_server,
              module_path => '/var/lib/jenkins',
            }
        }
    }

    if $::fqdn == $primary_server {
            profile::auto_restarts::service { 'rsync': }
    }

    class { '::httpd':
        modules => ['rewrite', 'headers', 'proxy', 'proxy_http'],
    }

    httpd::site { $sitename:
        content => template('releases/apache.conf.erb'),
    }

    profile::auto_restarts::service { 'apache2': }

    monitoring::service { 'https_releases':
        description   => "HTTPS ${sitename}",
        check_command => "check_https_url!${sitename}!/",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Releases.wikimedia.org',
    }

    ferm::service { 'releases_http':
        proto  => 'tcp',
        port   => '80',
        srange => "(${::ipaddress} ${::ipaddress6})",
    }

    ferm::service { 'releases_http_deployment_cumin':
        proto  => 'tcp',
        port   => '80',
        srange => '($DEPLOYMENT_HOSTS $CUMIN_MASTERS)',
    }

    backup::set { 'srv-org-wikimedia': }
}
