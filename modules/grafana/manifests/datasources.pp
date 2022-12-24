# SPDX-License-Identifier: Apache-2.0
# @summary installs a Grafana data source configuration file,
#  see https://grafana.com/docs/grafana/latest/administration/provisioning/#datasources
define grafana::datasources (
  Wmflib::Ensure               $ensure  = present,
  Optional[Stdlib::Filesource] $source  = undef,
  Optional[String]             $content = undef,
) {
  file { "/etc/grafana/provisioning/datasources/${title}.yaml":
    ensure  => stdlib::ensure($ensure, 'file'),
    source  => $source,
    content => $content,
    owner   => 'root',
    group   => 'grafana',
    mode    => '0440',
    require => Package['grafana'],
    notify  => Service['grafana-server'],
  }
}
