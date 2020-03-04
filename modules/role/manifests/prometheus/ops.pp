# lint:ignore:wmf_styleguide
# This should be converted to a profile

# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::ops {
    include profile::standard
    include profile::base::firewall
    include profile::prometheus::ops
    include profile::prometheus::ops_mysql
    include prometheus::swagger_exporter  # lint:ignore:wmf_styleguide
    include prometheus::blackbox_exporter  # lint:ignore:wmf_styleguide
}
# lint:endignore
