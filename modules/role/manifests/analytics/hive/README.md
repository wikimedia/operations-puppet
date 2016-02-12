# role/analytics/hive.pp
#
# Role classes for Analytics Hive client and server nodes.
# These role classes will configure Hive properly in either
# Labs or Production environments.
#
# If you are using these in Labs, you must include role::analytics::hive::server
# on your primary Hadoop NameNode.
#
# role::analytics::hive::client requires role::analytics::hadoop::client,
# and will install Hadoop client pacakges and configs.  In Labs,
# you must set appropriate Hadoop client global parameters.  See
# role/analytics/hadoop.pp documentation for more info.
