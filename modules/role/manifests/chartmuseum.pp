# == Class: role::chartmuseum
#
# ChartMuseum, a Helm chart repository server
class role::chartmuseum {
    system::role { 'chartmuseum': description => 'ChartMuseum Helm chart repository server' }

    include ::profile::base::production
    include ::profile::firewall
    include ::profile::chartmuseum
}
