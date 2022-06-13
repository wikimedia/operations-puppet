# SPDX-License-Identifier: Apache-2.0
# == Define: alternatives::java
#
# Debian's alternatives system uses symlinks to refer generic commands
# to a particular implementation. This Puppet resource lets you specify
# a value for a particular alternative in the specific case of the JVM
# (several binaries are shipped with openjdk for example, it is better
# to keep them all aligned with /usr/bin/java).
#
# Note: when checking if a Java version is already set correctly, we need
# to fall back to update-alternatives, since update-java-alternatives provides
# only a -l method to list available options, not the one currently set.
#
# === Parameters
#
# [*title*]
#   The number of the Java version to set as default.
#
# === Examples
#
#  alternatives::java { '11': }
#
define alternatives::java {

    # The following two paths are needed since update-alternatives lists
    # the java paths using the java-$version format, meanwhile
    # update-java-alternatives follows the java-1.$version.0 format.
    # There seems to be no way to use update-java-alternatives to get
    # the current path set as default, hence we need to use update-alternatives.
    $update_alternatives_path = "/usr/lib/jvm/java-${title}-openjdk-amd64"
    $update_java_alternatives_path = "/usr/lib/jvm/java-1.${title}.0-openjdk-amd64"

    exec { "update_java_alternatives_${title}":
        command => "/usr/sbin/update-java-alternatives -s ${update_java_alternatives_path}",
        unless  => "/usr/bin/update-alternatives --query java | /bin/grep 'Value: ${update_alternatives_path}'",
    }
}
