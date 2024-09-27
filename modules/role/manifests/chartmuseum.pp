# == Class: role::chartmuseum
#
# ChartMuseum, a Helm chart repository server
class role::chartmuseum {
    include profile::base::production
    include profile::firewall
    include profile::chartmuseum
}
