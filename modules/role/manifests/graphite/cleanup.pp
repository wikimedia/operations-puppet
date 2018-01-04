class role::graphite::cleanup {
    # Cleanup stale labs instances data - T143405
    graphite::whisper_cleanup { 'graphite-labs-instances':
        directory => "${storage_dir}/whisper/instances",
    }

    # Cleanup eventstreams rdkafka stale data - T160644
    graphite::whisper_cleanup { 'graphite-eventstreams':
        directory => "${storage_dir}/whisper/eventstreams/rdkafka",
        keep_days => 5,
    }

    # Cleanup zuul data
    graphite::whisper_cleanup { 'graphite-zuul':
        directory => "${storage_dir}/whisper/zuul",
    }
    # Zuul also generates metrics related to Gerrit
    graphite::whisper_cleanup { 'graphite-zuul-gerrit':
        directory => "${storage_dir}/whisper/gerrit",
    }

    # Nodepool, which has several metrics for each of the Jenkins jobs
    graphite::whisper_cleanup { 'graphite-nodepool':
        directory => "${storage_dir}/whisper/nodepool",
        keep_days => 15,
    }

    # Cassandra metrics - T179057
    graphite::whisper_cleanup { 'graphite-cassandra':
        directory => "${storage_dir}/whisper/cassandra",
        keep_days => 182,
    }

    # ORES metrics - T169969
    graphite::whisper_cleanup { 'graphite-ores':
        directory => "${storage_dir}/whisper/ores",
        keep_days => 30,
    }
}
