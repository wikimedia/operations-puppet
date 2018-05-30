<?php
# WARNING: This file is publicly viewable on the web. Do not put private data here.

if ( !defined( 'DBO_DEFAULT' ) ) {
	define( 'DBO_DEFAULT', 16 );
}

# $wgReadOnly = "Wikimedia Sites are currently read-only during maintenance, please try again soon.";

$wmgParserCacheDBs = [
	'10.64.0.12'   => '10.64.0.12',   # pc1004, A3 2.4TB 256GB
	'10.64.32.72'  => '10.64.32.72',  # pc1005, C7 2.4TB 256GB
	'10.64.48.128' => '10.64.48.128', # pc1006, D3 2.4TB 256GB
];

$wmgOldExtTemplate = [
	'10.64.0.7'    => 1, # es1012, A2 11TB 128GB
	'10.64.32.185' => 1, # es1016, C2 11TB 128GB
	'10.64.48.115' => 1, # es1018, D1 11TB 128GB
];

$wgLBFactoryConf = [

'class' => 'LBFactoryMulti',

'sectionsByDB' => [
	# s1: enwiki
	'enwiki'       => 's1',

	# s2: large wikis
	'bgwiki'       => 's2',
	'bgwiktionary' => 's2',
	'cswiki'       => 's2',
	'enwikiquote'  => 's2',
	'enwiktionary' => 's2',
	'eowiki'       => 's2',
	'fiwiki'       => 's2',
	'idwiki'       => 's2',
	'itwiki'       => 's2',
	'nlwiki'       => 's2',
	'nowiki'       => 's2',
	'plwiki'       => 's2',
	'ptwiki'       => 's2',
	'svwiki'       => 's2',
	'thwiki'       => 's2',
	'trwiki'       => 's2',
	'zhwiki'       => 's2',

	# s3 (default)

	# s4: commons
	'commonswiki'  => 's4',

	# s5: dewiki
	'dewiki'       => 's5',

	# s6: large wikis
	'frwiki'       => 's6',
	'jawiki'       => 's6',
	'ruwiki'       => 's6',

	# s7: large wikis, centralauth
	'eswiki'       => 's7',
	'huwiki'       => 's7',
	'hewiki'       => 's7',
	'ukwiki'       => 's7',
	'frwiktionary' => 's7',
	'metawiki'     => 's7',
	'arwiki'       => 's7',
	'centralauth'  => 's7',
	'cawiki'       => 's7',
	'viwiki'       => 's7',
	'fawiki'       => 's7',
	'rowiki'       => 's7',
	'kowiki'       => 's7',

	# s8: wikidata
	'wikidatawiki' => 's8',

	# labs-related wikis
	'labswiki'     => 'wikitech',
	'labtestwiki'  => 'wikitech',
],

# Load lists
#
# Masters should be in slot [0].
#
# All servers for which replication lag matters should be in the load
# list, not commented out, because otherwise maintenance scripts such
# as compressOld.php won't wait for those servers when they lag.
#
# Conversely, all servers which are down or do not replicate should be
# removed, not set to load zero, because there are certain situations
# when load zero servers will be used, such as if the others are lagged.
# Servers which are down should be removed to avoid a timeout overhead
# per invocation.
#
# Additionally, if a server should not to be lagged (for example,
# an api node, or a recentchanges node, set the load to at least 1.
# This will make the node be taken into account on the wait for lag
# function (the master is not included, as by definition has lag 0).

'sectionLoads' => [
	's1' => [
		'db1052' => 0,      # B3 2.8TB  96GB, master
		'db1067' => 50,     # C6 2.8TB 160GB, old master # candidate master
		'db1080' => 200,    # A2 3.6TB 512GB, api
		'db1083' => 500,    # B1 3.6TB 512GB
		'db1089' => 500,    # C3 3.6TB 512GB
		'db1099:3311' => 1, # B2 3.6TB 512GB # rc, log: s1 and s8
		'db1105:3311' => 1, # C3 3.6TB 512GB # rc, log: s1 and s2
		'db1106' => 50,     # D3 3.6TB 512GB, vslow, dump # master for db1095 (sanitarium)
		'db1114' => 200,    # D4 3.6TB 512GB, api # MariaDB 10.1
		'db1119' => 200,    # B8 3.6TB 512GB, api # MariaDB 10.1
	],
	's2' => [
		'db1054' => 0,      # A3 2.8TB  96GB, master
		'db1066' => 50,     # A6 2.8TB 160GB # candidate master
		'db1074' => 300,    # A2 3.6TB 512GB, api # master for for db1102
		'db1076' => 500,    # B1 3.6TB 512GB
		'db1090:3312' => 1, # C3 3.6TB 512GB, vslow, dump: s2 and s7
		'db1122' => 500,    # D6 3.6TB 512GB, api
		'db1103:3312' => 1, # A3 3.6TB 512GB # rc, log: s2 and s4
		'db1105:3312' => 1, # C3 3.6TB 512GB # rc, log: s1 and s2
	],
	/* s3 */ 'DEFAULT' => [
		'db1075' => 0,      # A2 3.6TB 512GB, master
		'db1077' => 400,    # B1 3.6TB 512GB, rc, log # master for db1095
		'db1078' => 500,    # C3 3.6TB 512GB # candidate master
		'db1123' => 100,    # D8 3.6TB 512GB, vslow, dump
	],
	's4' => [
		'db1068' => 0,      # D1 2.8TB 160GB, master
		'db1081' => 100,    # A2 3.6TB 512GB, api # candidate master
		'db1084' => 300,    # B1 3.6TB 512GB, api
		'db1091' => 500,    # D2 3.6TB 512GB
		'db1097:3314' => 1, # D1 3.6TB 512GB # rc, log: s4 and s5
		'db1103:3314' => 1, # A3 3.6TB 512GB # rc, log: s2 and s4
		'db1121' => 1,      # C6 3.6TB 512GB, vslow, dump # master for db1102
	],
	's5' => [
		'db1070' => 0,      # D1 2.8TB 160GB, master
		'db1082' => 300,    # A2 3.6TB 512GB, api # master for db1095
		'db1096:3315' => 1, # A6 3.6TB 512GB # rc, log: s5 and s6
		'db1097:3315' => 1, # D1 3.6TB 512GB # rc, log: s4 and s5
		'db1100' => 50,     # C2 3.6TB 512GB, old master #api # candidate master
		'db1110' => 500,    # C3 3.6TB 512GB
		'db1113:3315' => 1, # B8 3.6TB 512GB # vslow, dump: s5 and s6
	],
	's6' => [
		'db1061' => 0,      # C3 2.8TB 128GB, master
		'db1085' => 300,    # B3 3.6TB 512GB, api #master for db1102 (sanitarium 3)
		'db1088' => 500,    # C2 3.6TB 512GB
		'db1093' => 500,    # D2 3.6TB 512GB, api # candidate master
		'db1096:3316' => 1, # A6 3.6TB 512GB # rc, log: s5 and s6
		'db1098:3316' => 1, # B5 3.6TB 512GB # rc, log: s6 and s7
		'db1113:3316' => 1, # B8 3.6TB 512GB # vslow, dump: s5 and s6
	],
	's7' => [
		'db1062' => 0,      # D4 2.8TB 128GB, master
		'db1079' => 300,    # A2 3.6TB 512GB, api #master for db1102 (sanitarium 3)
		'db1086' => 100,    # B3 3.6TB 512GB, api # candidate master
		'db1090:3317' => 1, # C3 3.6TB 512GB, vslow, dump: s2 and s7, old master
		'db1094' => 500,    # D2 3.6TB 512GB
		'db1098:3317' => 1, # B5 3.6TB 512GB # rc, log: s6 and s7
		'db1101:3317' => 1, # C2 3.6TB 512GB # rc, log: s7 and s8
	],
	's8' => [
		'db1071' => 0,      # D1 2.8TB 160GB, master
		'db1087' => 1,      # C2 3.6TB 512GB, vslow, dump # master for db1095
		'db1092' => 100,    # D2 3.6TB 512GB, api
		'db1099:3318' => 1, # B2 3.6TB 512GB # rc, log: s1 and s8
		'db1101:3318' => 1, # C2 3.6TB 512GB # rc, log: s7 and s8
		'db1104' => 300,    # B3 3.6TB 512GB, api # candidate master
		'db1109' => 500,    # D8 3.6TB 512GB
	],

	'wikitech' => [
		// Use the FQDN so that `sql labswiki` will work from hosts where the
		// default DNS search path is not eqiad.wmnet (e.g. labweb1001)
		'db1073' => 1, # B3
	],
],

'serverTemplate' => [
	'dbname'	  => $wgDBname,
	'user'		  => $wgDBuser,
	'password'	  => $wgDBpassword,
	'type'		  => 'mysql',
	'flags'		  => DBO_DEFAULT,
	'max lag'	  => 6, // should be safely less than $wgCdnReboundPurgeDelay
	'variables'   => [
		'innodb_lock_wait_timeout' => 15
	]
],

'templateOverridesBySection' => [
	's1' => [
		'lagDetectionMethod' => 'pt-heartbeat',
		'lagDetectionOptions' => [
			'conds' => [ 'shard' => 's1', 'datacenter' => $wmfMasterDatacenter ]
		],
		'useGTIDs' => true
	],
	's2' => [
		'lagDetectionMethod' => 'pt-heartbeat',
		'lagDetectionOptions' => [
			'conds' => [ 'shard' => 's2', 'datacenter' => $wmfMasterDatacenter ]
		],
		'useGTIDs' => true
	],
	'DEFAULT' /* s3 */  => [
		'lagDetectionMethod' => 'pt-heartbeat',
		'lagDetectionOptions' => [
			'conds' => [ 'shard' => 's3', 'datacenter' => $wmfMasterDatacenter ]
		],
		'useGTIDs' => true
	],
	's4' => [
		'lagDetectionMethod' => 'pt-heartbeat',
		'lagDetectionOptions' => [
			'conds' => [ 'shard' => 's4', 'datacenter' => $wmfMasterDatacenter ]
		],
		'useGTIDs' => true
	],
	's5' => [
		'lagDetectionMethod' => 'pt-heartbeat',
		'lagDetectionOptions' => [
			'conds' => [ 'shard' => 's5', 'datacenter' => $wmfMasterDatacenter ]
		],
		'useGTIDs' => true
	],
	's6' => [
		'lagDetectionMethod' => 'pt-heartbeat',
		'lagDetectionOptions' => [
			'conds' => [ 'shard' => 's6', 'datacenter' => $wmfMasterDatacenter ]
		],
		'useGTIDs' => true
	],
	's7' => [
		'lagDetectionMethod' => 'pt-heartbeat',
		'lagDetectionOptions' => [
			'conds' => [ 'shard' => 's7', 'datacenter' => $wmfMasterDatacenter ]
		],
		'useGTIDs' => true
	],
	's8' => [
		'lagDetectionMethod' => 'pt-heartbeat',
		'lagDetectionOptions' => [
			'conds' => [ 'shard' => 's8', 'datacenter' => $wmfMasterDatacenter ]
		],
		'useGTIDs' => true
	],
],

'groupLoadsBySection' => [
	's1' => [
		'watchlist' => [
			'db1099:3311' => 1,
			'db1105:3311' => 1,
		],
		'recentchanges' => [
			'db1099:3311' => 1,
			'db1105:3311' => 1,
		],
		'recentchangeslinked' => [
			'db1099:3311' => 1,
			'db1105:3311' => 1,
		],
		'contributions' => [
			'db1099:3311' => 1,
			'db1105:3311' => 1,
		],
		'logpager' => [
			'db1099:3311' => 1,
			'db1105:3311' => 1,
		],
		'dump' => [
			'db1106' => 1,
		],
		'vslow' => [
			'db1106' => 1,
		],
		'api' => [
			'db1080' => 1,
			'db1114' => 1,
			'db1119' => 1,
		],
	],
	's2' => [
		'vslow' => [
			'db1090:3312' => 1,
		],
		'dump' => [
			'db1090:3312' => 1,
		],
		'api' => [
			'db1074' => 10,
			'db1122' => 1,
		],
		'watchlist' => [
			'db1103:3312' => 1,
			'db1105:3312' => 1,
		],
		'recentchanges' => [
			'db1103:3312' => 1,
			'db1105:3312' => 1,
		],
		'recentchangeslinked' => [
			'db1103:3312' => 1,
			'db1105:3312' => 1,
		],
		'contributions' => [
			'db1103:3312' => 1,
			'db1105:3312' => 1,
		],
		'logpager' => [
			'db1103:3312' => 1,
			'db1105:3312' => 1,
		],
	],
	/* s3 */ 'DEFAULT' => [
		'vslow' => [
			'db1123' => 1,
		],
		'dump' => [
			'db1123' => 1,
		],
		'watchlist' => [
			'db1077' => 1,
		],
		'recentchanges' => [
			'db1077' => 1,
		],
		'recentchangeslinked' => [
			'db1077' => 1,
		],
		'contributions' => [
			'db1077' => 1,
		],
		'logpager' => [
			'db1077' => 1,
		],
	],
	's4' => [
		'vslow' => [
			'db1121' => 1,
		],
		'dump' => [
			'db1121' => 1,
		],
		'api' => [
			'db1081' => 3,
			'db1084' => 1,
		],
		'watchlist' => [
			'db1097:3314' => 1,
			'db1103:3314' => 1,
		],
		'recentchanges' => [
			'db1097:3314' => 1,
			'db1103:3314' => 1,
		],
		'recentchangeslinked' => [
			'db1097:3314' => 1,
			'db1103:3314' => 1,
		],
		'contributions' => [
			'db1097:3314' => 1,
			'db1103:3314' => 1,
		],
		'logpager' => [
			'db1097:3314' => 1,
			'db1103:3314' => 1,
		],
	],
	's5' => [
		'vslow' => [
			'db1113:3315' => 1,
		],
		'dump' => [
			'db1113:3315' => 1,
		],
		'api' => [
			'db1082' => 1,
			'db1100' => 3,
		],
		'watchlist' => [
			'db1096:3315' => 1,
			'db1097:3315' => 1,
		],
		'recentchanges' => [
			'db1096:3315' => 1,
			'db1097:3315' => 1,
		],
		'recentchangeslinked' => [
			'db1096:3315' => 1,
			'db1097:3315' => 1,
		],
		'contributions' => [
			'db1096:3315' => 1,
			'db1097:3315' => 1,
		],
		'logpager' => [
			'db1096:3315' => 1,
			'db1097:3315' => 1,
		],
	],
	's6' => [
		'vslow' => [
			'db1113:3316' => 1,
		],
		'dump' => [
			'db1113:3316' => 1,
		],
		'api' => [
			'db1085' => 10,
			'db1093' => 1,
		],
		'watchlist' => [
			'db1096:3316' => 1,
			'db1098:3316' => 1,
		],
		'recentchanges' => [
			'db1096:3316' => 1,
			'db1098:3316' => 1,
		],
		'recentchangeslinked' => [
			'db1096:3316' => 1,
			'db1098:3316' => 1,
		],
		'contributions' => [
			'db1096:3316' => 1,
			'db1098:3316' => 1,
		],
		'logpager' => [
			'db1096:3316' => 1,
			'db1098:3316' => 1,
		],
	],
	's7' => [
		'vslow' => [
			'db1090:3317' => 1,
		],
		'dump' => [
			'db1090:3317' => 1,
		],
		'api' => [
			'db1079' => 10,
			'db1086' => 1,
		],
		'watchlist' => [
			'db1098:3317' => 1,
			'db1101:3317' => 1,
		],
		'recentchanges' => [
			'db1098:3317' => 1,
			'db1101:3317' => 1,
		],
		'recentchangeslinked' => [
			'db1098:3317' => 1,
			'db1101:3317' => 1,
		],
		'contributions' => [
			'db1098:3317' => 1,
			'db1101:3317' => 1,
		],
		'logpager' => [
			'db1098:3317' => 1,
			'db1101:3317' => 1,
		],
	],
	's8' => [
		'vslow' => [
			'db1087' => 1,
		],
		'dump' => [
			'db1087' => 1,
		],
		'api' => [
			'db1092' => 3,
			'db1104' => 1,
		],
		'watchlist' => [
			'db1099:3318' => 1,
			'db1101:3318' => 1,
		],
		'recentchanges' => [
			'db1099:3318' => 1,
			'db1101:3318' => 1,
		],
		'recentchangeslinked' => [
			'db1099:3318' => 1,
			'db1101:3318' => 1,
		],
		'contributions' => [
			'db1099:3318' => 1,
			'db1101:3318' => 1,
		],
		'logpager' => [
			'db1099:3318' => 1,
			'db1101:3318' => 1,
		],
	],
],

'groupLoadsByDB' => [],

# Hosts settings
# Do not remove servers from this list ever
# Removing a server from this list does not remove the server from rotation,
# it just breaks the site horribly.
'hostsByName' => [
	'db1052' => '10.64.16.77', # do not remove or comment out
	'db1054' => '10.64.0.206', # do not remove or comment out
	'db1061' => '10.64.32.227', # do not remove or comment out
	'db1062' => '10.64.48.15', # do not remove or comment out
	'db1064' => '10.64.48.19', # do not remove or comment out
	'db1066' => '10.64.0.110', # do not remove or comment out
	'db1067' => '10.64.32.64', # do not remove or comment out
	'db1068' => '10.64.48.23', # do not remove or comment out
	'db1069' => '10.64.0.108', # do not remove or comment out
	'db1070' => '10.64.48.25', # do not remove or comment out
	'db1071' => '10.64.48.26', # do not remove or comment out
	'db1073' => '10.64.16.79', # do not remove or comment out
	'db1074' => '10.64.0.204', # do not remove or comment out
	'db1075' => '10.64.0.205', # do not remove or comment out
	'db1076' => '10.64.16.190', # do not remove or comment out
	'db1077' => '10.64.16.191', # do not remove or comment out
	'db1078' => '10.64.32.136', # do not remove or comment out
	'db1079' => '10.64.0.91', # do not remove or comment out
	'db1080' => '10.64.0.92', # do not remove or comment out
	'db1081' => '10.64.0.93', # do not remove or comment out
	'db1082' => '10.64.0.94', # do not remove or comment out
	'db1083' => '10.64.16.101', # do not remove or comment out
	'db1084' => '10.64.16.102', # do not remove or comment out
	'db1085' => '10.64.16.103', # do not remove or comment out
	'db1086' => '10.64.16.104', # do not remove or comment out
	'db1087' => '10.64.32.113', # do not remove or comment out
	'db1088' => '10.64.32.114', # do not remove or comment out
	'db1089' => '10.64.32.115', # do not remove or comment out
	'db1090:3312' => '10.64.32.116:3312', # do not remove or comment out
	'db1090:3317' => '10.64.32.116:3317', # do not remove or comment out
	'db1091' => '10.64.48.150', # do not remove or comment out
	'db1092' => '10.64.48.151', # do not remove or comment out
	'db1093' => '10.64.48.152', # do not remove or comment out
	'db1094' => '10.64.48.153', # do not remove or comment out
	'db1096:3315' => '10.64.0.163:3315', # do not remove or comment out
	'db1096:3316' => '10.64.0.163:3316', # do not remove or comment out
	'db1097:3314' => '10.64.48.11:3314', # do not remove or comment out
	'db1097:3315' => '10.64.48.11:3315', # do not remove or comment out
	'db1098:3316' => '10.64.16.83:3316', # do not remove or comment out
	'db1098:3317' => '10.64.16.83:3317', # do not remove or comment out
	'db1099:3311' => '10.64.16.84:3311', # do not remove or comment out
	'db1099:3318' => '10.64.16.84:3318', # do not remove or comment out
	'db1100' => '10.64.32.197', # do not remove or comment out
	'db1101:3317' => '10.64.32.198:3317', # do not remove or comment out
	'db1101:3318' => '10.64.32.198:3318', # do not remove or comment out
	'db1103:3312' => '10.64.0.164:3312', # do not remove or comment out
	'db1103:3314' => '10.64.0.164:3314', # do not remove or comment out
	'db1104' => '10.64.16.85', # do not remove or comment out
	'db1105:3311' => '10.64.32.222:3311', # do not remove or comment out
	'db1105:3312' => '10.64.32.222:3312', # do not remove or comment out
	'db1106' => '10.64.48.13', # do not remove or comment out
	'db1109' => '10.64.48.172', # do not remove or comment out
	'db1110' => '10.64.32.73', # do not remove or comment out
	'db1113:3315' => '10.64.16.11:3315', # do not remove or comment out
	'db1113:3316' => '10.64.16.11:3316', # do not remove or comment out
	'db1114' => '10.64.48.173', # do not remove or comment out
	'db1119' => '10.64.16.13', # do not remove or comment out
	'db1121' => '10.64.32.12', # do not remove or comment out
	'db1122' => '10.64.48.34', # do not remove or comment out
	'db1123' => '10.64.48.35', # do not remove or comment out
	'db2033' => '10.192.32.4', # do not remove or comment out
	'db2034' => '10.192.0.87', # do not remove or comment out
	'db2035' => '10.192.16.73', # do not remove or comment out
	'db2036' => '10.192.32.7', # do not remove or comment out
	'db2037' => '10.192.32.8', # do not remove or comment out
	'db2038' => '10.192.32.9', # do not remove or comment out
	'db2039' => '10.192.48.114', # do not remove or comment out
	'db2040' => '10.192.0.39', # do not remove or comment out
	'db2041' => '10.192.32.12', # do not remove or comment out
	'db2043' => '10.192.32.103', # do not remove or comment out
	'db2045' => '10.192.16.74', # do not remove or comment out
	'db2046' => '10.192.32.106', # do not remove or comment out
	'db2047' => '10.192.32.107', # do not remove or comment out
	'db2048' => '10.192.0.99', # do not remove or comment out
	'db2049' => '10.192.32.109', # do not remove or comment out
	'db2050' => '10.192.32.110', # do not remove or comment out
	'db2051' => '10.192.16.22', # do not remove or comment out
	'db2052' => '10.192.48.4', # do not remove or comment out
	'db2053' => '10.192.48.5', # do not remove or comment out
	'db2054' => '10.192.48.6', # do not remove or comment out
	'db2055' => '10.192.48.7', # do not remove or comment out
	'db2056' => '10.192.48.8', # do not remove or comment out
	'db2057' => '10.192.48.9', # do not remove or comment out
	'db2058' => '10.192.48.10', # do not remove or comment out
	'db2059' => '10.192.48.11', # do not remove or comment out
	'db2060' => '10.192.48.12', # do not remove or comment out
	'db2061' => '10.192.48.13', # do not remove or comment out
	'db2062' => '10.192.16.195', # do not remove or comment out
	'db2063' => '10.192.48.15', # do not remove or comment out
	'db2065' => '10.192.48.17', # do not remove or comment out
	'db2066' => '10.192.48.18', # do not remove or comment out
	'db2067' => '10.192.48.19', # do not remove or comment out
	'db2068' => '10.192.48.20', # do not remove or comment out
	'db2069' => '10.192.48.21', # do not remove or comment out
	'db2070' => '10.192.32.5', # do not remove or comment out
	'db2071' => '10.192.0.4', # do not remove or comment out
	'db2072' => '10.192.16.37', # do not remove or comment out
	'db2073' => '10.192.32.167', # do not remove or comment out
	'db2074' => '10.192.48.84', # do not remove or comment out
	'db2075' => '10.192.0.5', # do not remove or comment out
	'db2076' => '10.192.16.38', # do not remove or comment out
	'db2077' => '10.192.32.168', # do not remove or comment out
	'db2079' => '10.192.0.6', # do not remove or comment out
	'db2080' => '10.192.32.169', # do not remove or comment out
	'db2081' => '10.192.0.7', # do not remove or comment out
	'db2082' => '10.192.16.39', # do not remove or comment out
	'db2083' => '10.192.32.170', # do not remove or comment out
	'db2084:3314' => '10.192.48.86:3314', # do not remove or comment out
	'db2084:3315' => '10.192.48.86:3315', # do not remove or comment out
	'db2085:3311' => '10.192.0.8:3311', # do not remove or comment out
	'db2085:3318' => '10.192.0.8:3318', # do not remove or comment out
	'db2086:3318' => '10.192.16.40:3318', # do not remove or comment out
	'db2086:3317' => '10.192.16.40:3317', # do not remove or comment out
	'db2087:3316' => '10.192.32.171:3316', # do not remove or comment out
	'db2087:3317' => '10.192.32.171:3317', # do not remove or comment out
	'db2088:3311' => '10.192.48.87:3311', # do not remove or comment out
	'db2088:3312' => '10.192.48.87:3312', # do not remove or comment out
	'db2089:3315' => '10.192.0.9:3315', # do not remove or comment out
	'db2089:3316' => '10.192.0.9:3316', # do not remove or comment out
	'db2090' => '10.192.32.172', # do not remove or comment out
	'db2091:3312' => '10.192.0.10:3312', # do not remove or comment out
	'db2091:3314' => '10.192.0.10:3314', # do not remove or comment out
	'db2092' => '10.192.16.41', # do not remove or comment out
],

'externalLoads' => [
	# Recompressed stores
	'rc1' => $wmgOldExtTemplate,

	# Former Ubuntu dual-purpose stores
	'cluster3' => $wmgOldExtTemplate,
	'cluster4' => $wmgOldExtTemplate,
	'cluster5' => $wmgOldExtTemplate,
	'cluster6' => $wmgOldExtTemplate,
	'cluster7' => $wmgOldExtTemplate,
	'cluster8' => $wmgOldExtTemplate,
	'cluster9' => $wmgOldExtTemplate,
	'cluster10' => $wmgOldExtTemplate,
	'cluster20' => $wmgOldExtTemplate,
	'cluster21' => $wmgOldExtTemplate,

	# Clusters required for T24624
	'cluster1' => $wmgOldExtTemplate,
	'cluster2' => $wmgOldExtTemplate,

	# Old dedicated clusters
	'cluster22' => $wmgOldExtTemplate,
	'cluster23' => $wmgOldExtTemplate,

	# es2
	'cluster24' => [
		'10.64.0.6'    => 0, # es1011, A2 11TB 128GB, master
		'10.64.16.186' => 1, # es1013, B1 11TB 128GB
		'10.64.32.184' => 1, # es1015, C2 11TB 128GB
	],
	# es3
	'cluster25' => [
		'10.64.16.187' => 0, # es1014, B1 11TB 128GB, master
		'10.64.48.114' => 1, # es1017, D1 11TB 128GB
		'10.64.48.116' => 1, # es1019, D8 11TB 128GB
	],
	# ExtensionStore shard1
	'extension1' => [
		'10.64.0.108' => 0, # db1069, A1 2.8TB 160GB # master
		'10.64.48.19' => 1, # db1064, D1 2.8TB 160GB
	],
],

'masterTemplateOverrides' => [],

'externalTemplateOverrides' => [
	'flags' => 0, // No transactions
],

'templateOverridesByCluster' => [
	'rc1'		=> [ 'is static' => true ],
	'cluster1'	=> [ 'blobs table' => 'blobs_cluster1', 'is static' => true ],
	'cluster2'	=> [ 'blobs table' => 'blobs_cluster2', 'is static' => true ],
	'cluster3'	=> [ 'blobs table' => 'blobs_cluster3', 'is static' => true ],
	'cluster4'	=> [ 'blobs table' => 'blobs_cluster4', 'is static' => true ],
	'cluster5'	=> [ 'blobs table' => 'blobs_cluster5', 'is static' => true ],
	'cluster6'	=> [ 'blobs table' => 'blobs_cluster6', 'is static' => true ],
	'cluster7'	=> [ 'blobs table' => 'blobs_cluster7', 'is static' => true ],
	'cluster8'	=> [ 'blobs table' => 'blobs_cluster8', 'is static' => true ],
	'cluster9'	=> [ 'blobs table' => 'blobs_cluster9', 'is static' => true ],
	'cluster10'	=> [ 'blobs table' => 'blobs_cluster10', 'is static' => true ],
	'cluster20'	=> [ 'blobs table' => 'blobs_cluster20', 'is static' => true ],
	'cluster21'	=> [ 'blobs table' => 'blobs_cluster21', 'is static' => true ],
	'cluster22'	=> [ 'blobs table' => 'blobs_cluster22', 'is static' => true ],
	'cluster23'	=> [ 'blobs table' => 'blobs_cluster23', 'is static' => true ],
	'cluster24'	=> [ 'blobs table' => 'blobs_cluster24' ],
	'cluster25'	=> [ 'blobs table' => 'blobs_cluster25' ],
],

# This key must exist for the master switch script to work, which means comment and uncomment
# the individual shards, but leave the 'readOnlyBySection' => [ ], alone.
#
# When going read only, please change the comment to something appropiate (like a brief idea
# of what is happening, with a wiki link for further explanation. Avoid linking to external
# infrastructure if possible (IRC, other webpages) or infrastructure not prepared to absorve
# large traffic (phabricator) because they tend to collapse. A meta page would be appropiate.
#
# Also keep these read only messages if eqiad is not the active dc, to prevent accidental writes
# getting trasmmitted from codfw to eqiad when the master dc is eqiad.
'readOnlyBySection' => [
	# 's1'      => 'This request is served by a passive datacenter. If you see this something is really wrong.',
	# 's2'      => 'This request is served by a passive datacenter. If you see this something is really wrong.',
	# 'DEFAULT' => 'This request is served by a passive datacenter. If you see this something is really wrong.', # s3
	# 's4'      => 'This request is served by a passive datacenter. If you see this something is really wrong.',
	# 's5'      => 'This request is served by a passive datacenter. If you see this something is really wrong.',
	# 's6'      => 'This request is served by a passive datacenter. If you see this something is really wrong.',
	# 's7'      => 'This request is served by a passive datacenter. If you see this something is really wrong.',
	# 's8'      => 'This request is served by a passive datacenter. If you see this something is really wrong.',
],

];

$wgDefaultExternalStore = [
	'DB://cluster24',
	'DB://cluster25',
];

# $wgLBFactoryConf['readOnlyBySection']['s2'] =
# 'Scheduled maintenance, s2 wikis in read-only mode for a few minutes';
# $wgLBFactoryConf['readOnlyBySection']['s2a'] =
# 'Emergency maintenance, need more servers up, new estimate ~18:30 UTC';
