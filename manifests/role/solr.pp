# = Class: role::solr
#
# This class manages a Solr service in a WMF-specific way
#
# == Parameters:
#
# $schema::               Schema file for Solr (only one schema per instance supported)
# $replication_master::   Replication master, if this is current hostname, this server will be a master
# $average_request_time:: Average request time check threshold, the format is
#                         "warning threshold:error threshold", or simply "error threshold"
# $max_heap::             Maximum size of the JVM heap that Solr will use.  Use Xmx and Xms valid
#                         parameters like 4G, 512M, etc.  Defaults to 4G.
class role::solr(
    $schema               = undef,
    $replication_master   = undef,
    $average_request_time = '400:600',
    $max_heap             = '4G',
) {
    class { '::solr':
        schema             => $schema,
        replication_master => $replication_master,
        max_heap           => $max_heap,
    }

    $check_command = $replication_master ? {
        undef   => 'check_solr',
        default => 'check_replicated_solr',
    }
    monitor_service { 'Solr':
        description   => 'Solr',
        check_command => "$check_command!$average_request_time!5",
    }
}

# == Class: role::solr::ttm
#
# TTMServer is a translation memory server that comes with the Translate
# extension. The Translate extension turns MediaWiki into a tool for
# doing collaborative translation work. This Puppet class configures a
# Solr back-end for translation lookups.
#
# See <http://www.mediawiki.org/wiki/Help:Extension:Translate/Translation_memories#Solr_backend>.
#
class role::solr::ttm {
    system::role { 'solr':
        description => 'ttm solr backend',
    }

    class { 'role::solr':
        schema               => 'puppet:///modules/solr/schema-ttmserver.xml',
        average_request_time => '5000:8000', # Translate uses fairly slow queries
        max_heap             => '1G',
    }
}
