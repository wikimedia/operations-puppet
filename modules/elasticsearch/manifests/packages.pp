# == Class: elasticsearch::packages
#
# Provisions Elasticsearch package and dependencies.
#
class elasticsearch::packages {
    package { [ 'openjdk-7-jdk', 'elasticsearch', 'curl' ]: }
}
