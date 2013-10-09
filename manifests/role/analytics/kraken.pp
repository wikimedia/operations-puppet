# == Class role::analytics::kraken
# Deployment for Kraken repository and versioned .jars
# only Analytics nodes, and eventually into HDFS.
class role::analytics::kraken {
    deployment::target { 'analytics-kraken': }
}
