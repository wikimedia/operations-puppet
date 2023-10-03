# SPDX-License-Identifier: Apache-2.0
# == Define bigtop::spark::shuffler
#
# This defined type creates an XML file fragment that configures a spark shuffler service
# for yarn.
#
# == Parameters
# $version          - The minor version of spark. Currently must be 3.x where x is any integer
# $port             - The port number on which this shuffler service will be accessible.
# $config_directory - The path of a hadoop configuration directory.
#
#
# == Usage
# bigtop::spark::shuffler { '3.1':
#   version          => "3.1",
#   port             => 7001,
#   config_directory => "/etc/hadoop/conf.analytics-hadoop",
# }
#

define bigtop::spark::shuffler (
  Bigtop::Spark::Version $version,
  Stdlib::Port           $port,
  Stdlib::UnixPath       $config_directory,
) {
    $spark_shuffler_config_directory = sprintf('spark_shuffle_%s_config', $version.regsubst('\.','_'))

    file { "${config_directory}/${spark_shuffler_config_directory}":
        ensure => directory,
    }
    file { "${config_directory}/${spark_shuffler_config_directory}/spark-shuffle-site.xml":
        content => template('bigtop/spark/spark-shuffle-site.xml.erb'),
    }
}
