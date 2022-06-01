# SPDX-License-Identifier: Apache-2.0
# == Define: sysctl::conffile
#
# Represents a file with sysctl kernel parameters in /etc/sysctl.d.
#
# === Parameters
#
# [*content*]
#   The content of the file provided as a string. Either this or
#   'source' must be specified.
#
# [*source*]
#   The content of the file provided as a puppet:/// file reference.
#   Either this or 'content' must be specified.
#
# [*priority*]
#   A numeric value in range 60 - 99. In case of conflict, files with a
#   higher priority override files with a lower priority. Debian
#   reserves 0 - 59 for sysctl settings that are bundled with individual
#   packages. The default is 70. Values in 60 - 69 should be reserved
#   for cluster-wide defaults that should always have a lower priority
#   than role-specific customizations.
#
#   If you're not sure, leave this unspecified. The default value of 60
#   should suit most cases.
#
# === Examples
#
#  sysctl::conffile { 'hadoop':
#    content  => template('hadoop/hadoop.conf.erb'),
#    priority => 90,
#  }
#
define sysctl::conffile(
    Wmflib::Ensure $ensure   = present,
    Optional[String] $content  = undef,
    Optional[String] $source   = undef,
    Integer[0, 99] $priority = 70
) {
    include ::sysctl

    $basename = regsubst($title, '\W', '-', 'G')
    $filename = sprintf('/etc/sysctl.d/%02d-%s.conf', $priority, $basename)

    file { $filename:
        ensure  => $ensure,
        content => $content,
        source  => $source,
        notify  => Exec['update_sysctl'],
    }
}
