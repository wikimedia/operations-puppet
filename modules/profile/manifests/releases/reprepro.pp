# server hosting Mediawiki releases
# https://releases.wikimedia.org/mediawiki/
class profile::releases::reprepro(
    $active_server = hiera('releases_server'),
    $passive_server = hiera('releases_server_failover'),
){

  class { '::releases::reprepro': }

  # ssh-based uploads from deployment servers
  ferm::rule { 'deployment_package_upload':
      ensure => present,
      rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
  }

    rsync::quickdatacopy { 'srv-org-wikimedia-reprepro':
      ensure      => present,
      auto_sync   => true,
      source_host => $active_server,
      dest_host   => $passive_server,
      module_path => '/srv/org/wikimedia/reprepro',
    }

    if $::fqdn == $active_server {
        $motd_content = "#!/bin/sh\necho \"This is the active releases server and the rsync source for other servers.\nThis is the right place to upload.\""
    } else {
        $motd_content = "#!/bin/sh\necho \"This is the NOT the active releases server and an rsync destination.\nDO NOT UPLOAD HERE. Go to ${active_server} instead.\""
    }

    @motd::script { 'releases':
        ensure   => present,
        priority => 6,
        content  => $motd_content,
        tag      => 'releases-motd',
    }
}
