# = Class: elasticsearch
#
# This class installs/configures/manages the elasticsearch service.
#
# == Parameters:
# - $cluster_name:  name of the cluster for this elasticsearch instance to join
# - $heap_memory:   amount of memory to allocate to elasticsearch.  Defaults to
#       "2G".  Should be set to about half of ram or a 30G, whichever is
#       smaller.
#
# == Sample usage:
#
#   class { "elasticsearch":
#       cluster_name = 'labs-search'
#   }
#
class elasticsearch($cluster_name, $heap_memory = "2G") {
    include elasticsearch::install,
        elasticsearch::service

    class { "elasticsearch::config":
        cluster_name => $cluster_name,
        heap_memory => $heap_memory
    }
}

class elasticsearch::install {
    # Get a jdk on which to run elasticsearch
    package { "openjdk-7-jdk":
        ensure => present,
    }
    package { "elasticsearch":
        ensure => present,
        require => Package["openjdk-7-jdk"]
    }
}

class elasticsearch::service {
    service { "elasticsearch":
        ensure => running,
        enable => true,
        require => Package["elasticsearch"]
    }
}

class elasticsearch::config($cluster_name, $heap_memory) {
    file { "/etc/elasticsearch/elasticsearch.yml":
        ensure  => file,
        content => template("elasticsearch/elasticsearch.yml.erb"),
        notify  => Service["elasticsearch"],
    }
    file { "/etc/elasticsearch/logging.yml":
        ensure  => file,
        content => template("elasticsearch/logging.yml.erb"),
        notify  => Service["elasticsearch"],
    }
    file { "/etc/default/elasticsearch":
        ensure  => file,
        content => template("elasticsearch/elasticsearch.erb"),
        notify  => Service["elasticsearch"],
    }
}
