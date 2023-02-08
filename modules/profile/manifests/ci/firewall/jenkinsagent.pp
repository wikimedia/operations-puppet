# SPDX-License-Identifier: Apache-2.0
# Allow inbound ssh connection from Jenkins controller
class profile::ci::firewall::jenkinsagent (
    Array[Stdlib::Fqdn] $jenkins_master_hosts = lookup('jenkins_master_hosts'),
) {
    $jenkins_master_hosts_ferm = join($jenkins_master_hosts, ' ')
    ferm::service { 'jenkins_masters_ssh':
        proto  => 'tcp',
        port   => '22',
        srange => "@resolve((${jenkins_master_hosts_ferm}))",
    }
}
