# filtertags: labs-project-deployment-prep
class role::mediawiki::videoscaler {
    system::role { 'mediawiki::videoscaler': }

    include ::role::mediawiki::common

    # Profiles
    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter
    include ::profile::mediawiki::jobrunner
    include ::profile::mediawiki::videoscaler
    include ::base::firewall
}
