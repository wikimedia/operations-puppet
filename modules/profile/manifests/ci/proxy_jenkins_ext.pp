# SPDX-License-Identifier: Apache-2.0
# == Class contint::proxy_jenkins_ext
#
# A proxy in front of Jenkins
# when running on an external machine behind envoy.
#
# [*tls_port*]
# port for envoy terminating TLS. Example: 1443
#
# [*prefix*]
# The HTTP path used to reach the Jenkins instance. Must have a leading slash.
# Example: /jenkins
#
# [*host]
# The external host where envoy and jenkins are running.
# Example: jenkins.discovery.wmnet
# 
class profile::ci::proxy_jenkins_ext (
    Stdlib::Port $tls_port = lookup('profile::ci::proxy_jenkins_ext::tls_port'),
    String $prefix = lookup('profile::ci::proxy_jenkins_ext::prefix'),
    Stdlib::Fqdn $host = lookup('profile::ci::proxy_jenkins_ext::host'),
) {

  file {
    '/etc/apache2/jenkins_proxy_ext':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('contint/apache/proxy_jenkins_ext.erb'),
  }

}
