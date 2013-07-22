# == Class role::analytics::common
# Includes common analytics classes:
# - hadoop
# - hive
# - oozie
# - pig
# - sqoop
#
class role::analytics::common {
    include role::analytics::hadoop::client,
        role::analytics::hive::client,
        role::analytics::oozie::client,
        role::analytics::pig,
        role::analytics::sqoop
}
