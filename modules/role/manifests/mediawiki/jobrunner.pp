# filtertags: labs-project-deployment-prep
class role::mediawiki::jobrunner {
    system::role { 'mediawiki::jobrunner': }

    # Parent role (we don't use inheritance by choice)
    include ::role::mediawiki::common

    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter

    include ::profile::mediawiki::jobrunner

    # TODO: change role used in beta
    if hiera('has_lvs', true) {
        include ::profile::mediawiki::jobrunner_tls
    }

}
