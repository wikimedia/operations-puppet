# Mediawiki Deployment Server (prod)
class role::deployment_server {
    include ::standard
    include ::base::firewall
    include ::profile::mediawiki::deployment::server
    include ::profile::backup::host
    include ::role::deployment::mediawiki
    include ::profile::releases::mediawiki::security
    include ::profile::releases::upload
    include ::profile::kubernetes::deployment_server
    backup::set {'home': }

    rsync::quickdatacopy { 'deploy-srv':
      ensure      => present,
      auto_sync   => false,
      source_host => 'tin.eqiad.wmnet',
      dest_host   => 'deploy1001.eqiad.wmnet',
      module_path => '/srv',
    }
}
