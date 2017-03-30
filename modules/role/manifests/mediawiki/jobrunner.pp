# filtertags: labs-project-deployment-prep
class role::mediawiki::jobrunner {
    system::role { 'role::mediawiki::jobrunner': }

    # Parent role (we don't use inheritance by choice)
    include ::role::mediawiki::common

    # These should really be profiles
    include ::role::prometheus::apache_exporter
    include ::role::prometheus::hhvm_exporter

    include ::profile::mediawiki::jobrunner
}
