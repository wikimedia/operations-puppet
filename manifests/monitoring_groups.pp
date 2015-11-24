# This file contains virtual resources for setting up monitoring groups
# This needs to be directly 'imported' for now and hence is in a separate
# file.
# Please keep this list alphabetically ordered!

# Analytics
@monitoring::group { 'analytics_eqiad': description => 'analytics servers in eqiad' }

# Analytics Query Service
@monitoring::group { 'aqs_eqiad': description => 'Analytics Query Service eqiad' }
@monitoring::group { 'aqs_codfw': description => 'Analytics Query Service codfw' }

# Cache
@monitoring::group { 'cache_text_codfw': description => 'codfw text Varnish' }
@monitoring::group { 'cache_text_eqiad': description => 'eqiad text Varnish' }
@monitoring::group { 'cache_text_esams': description => 'esams text Varnish' }
@monitoring::group { 'cache_text_ulsfo': description => 'ulsfo text Varnish' }
@monitoring::group { 'cache_upload_codfw': description => 'codfw upload Varnish' }
@monitoring::group { 'cache_upload_eqiad': description => 'eqiad upload Varnish' }
@monitoring::group { 'cache_upload_esams': description => 'esams upload Varnish' }
@monitoring::group { 'cache_upload_ulsfo': description => 'ulsfo upload Varnish' }
@monitoring::group { 'cache_mobile_codfw': description => 'codfw mobile Varnish' }
@monitoring::group { 'cache_mobile_eqiad': description => 'eqiad mobile Varnish' }
@monitoring::group { 'cache_mobile_esams': description => 'esams mobile Varnish' }
@monitoring::group { 'cache_mobile_ulsfo': description => 'ulsfo mobile Varnish' }
@monitoring::group { 'cache_parsoid_eqiad': description => 'Parsoid caches eqiad' }
@monitoring::group { 'cache_parsoid_codfw': description => 'Parsoid caches codfw' }
@monitoring::group { 'cache_misc_eqiad': description => 'Misc caches eqiad' }
@monitoring::group { 'cache_maps_eqiad': description => 'Maps caches eqiad' }

# Elasticsearch
@monitoring::group { 'elasticsearch_eqiad': description => 'eqiad elasticsearch servers' }
@monitoring::group { 'elasticsearch_codfw': description => 'codfw elasticsearch servers' }
@monitoring::group { 'elasticsearch_esams': description => 'esams elasticsearch servers' }
@monitoring::group { 'elasticsearch_ulsfo': description => 'ulsfo elasticsearch servers' }

# Etcd
@monitoring::group { 'etcd_eqiad': description => 'eqiad Etcd' }

# Ganeti
@monitoring::group { 'ganeti_eqiad': description => 'Ganeti virt cluster eqiad' }
@monitoring::group { 'ganeti_codfw': description => 'Ganeti virt cluster codfw' }

# Labs OpenStack Nova (labvirt***)
@monitoring::group { 'virt_eqiad': description => 'eqiad virt servers' }
@monitoring::group { 'virt_codfw': description => 'codfw virt servers' }

# LVS
@monitoring::group { 'lvs': description => 'LVS' }
@monitoring::group { 'lvs_eqiad': description => 'eqiad LVS servers' }
@monitoring::group { 'lvs_codfw': description => 'codfw LVS servers' }
@monitoring::group { 'lvs_ulsfo': description => 'ulsfo LVS servers' }
@monitoring::group { 'lvs_esams': description => 'esams LVS servers' }

# Logstash
@monitoring::group { 'logstash_eqiad': description => 'eqiad logstash' }

# Maps
@monitoring::group { 'maps_eqiad': description => 'eqiad maps servers' }
@monitoring::group { 'maps_codfw': description => 'codfw maps servers' }

# MediaWiki
@monitoring::group { 'appserver_eqiad':     description => 'eqiad application servers' }
@monitoring::group { 'api_appserver_eqiad': description => 'eqiad API application servers' }
@monitoring::group { 'imagescaler_eqiad':   description => 'eqiad image scalers' }
@monitoring::group { 'jobrunner_eqiad':     description => 'eqiad jobrunner application servers' }
@monitoring::group { 'videoscaler_eqiad':   description => 'eqiad video scaler' }

@monitoring::group { 'appserver_codfw':     description => 'codfw application servers' }
@monitoring::group { 'api_appserver_codfw': description => 'codfw API application servers' }
@monitoring::group { 'imagescaler_codfw':   description => 'codfw image scalers' }
@monitoring::group { 'jobrunner_codfw':     description => 'codfw jobrunner application servers' }
@monitoring::group { 'videoscaler_codfw':   description => 'codfw video scaler' }

# Memcached
@monitoring::group { 'memcached_eqiad': description => 'eqiad memcached' }
@monitoring::group { 'memcached_codfw': description => 'codfw memcached' }

# MySQL
@monitoring::group { 'es_eqiad': description => 'eqiad External Storage' }
@monitoring::group { 'mysql_eqiad': description => 'eqiad mysql core' }
@monitoring::group { 'mysql_codfw': description => 'codfw mysql core' }

# OCG
@monitoring::group { 'ocg_eqiad': description => 'offline content generator eqiad' }

# OpenLDAP (Corp IT)
@monitoring::group { 'openldap_corp_mirror_eqiad': description => 'Corp OIT LDAP Mirror' }
@monitoring::group { 'openldap_corp_mirror_codfw': description => 'Corp OIT LDAP Mirror codfw' }

# Parsoid
@monitoring::group { 'parsoid_eqiad': description => 'eqiad parsoid servers' }
@monitoring::group { 'parsoid_codfw': description => 'codfw parsoid servers' }

# RCStream
@monitoring::group { 'rcstream_eqiad': description => 'eqiad rcstream' }

# RedisDB
@monitoring::group { 'redis_eqiad': description => 'eqiad Redis' }
@monitoring::group { 'redis_codfw': description => 'codfw Redis' }

# RESTBase
@monitoring::group { 'restbase_eqiad': description => 'Restbase eqiad' }
@monitoring::group { 'restbase_codfw': description => 'Restbase codfw' }

# Service Clusters
@monitoring::group { 'sca_eqiad': description => 'Service Cluster A servers' }
@monitoring::group { 'scb_eqiad': description => 'Service Cluster B servers' }

# Swift
@monitoring::group { 'swift': description => 'swift servers' }

# Wikidata Query Service
@monitoring::group{ 'wdqs_eqiad': description => 'Wikidata Query Service (eqiad)' }

# Zotero
@monitoring::group { 'zotero_eqiad': description => 'Zotero eqiad' }
@monitoring::group { 'zotero_codfw': description => 'Zotero codfw' }
