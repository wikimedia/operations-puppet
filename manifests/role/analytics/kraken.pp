# == Class role::analytics::kraken
# Includes common analytics Kraken client classes:
# - hadoop
# - hive
# - oozie
# - pig
# - sqoop
#
class role::analytics::kraken {
    include role::analytics::hadoop::client,
        role::analytics::hive::client,
        role::analytics::oozie::client,
        role::analytics::pig,
        role::analytics::sqoop
}
