# vim: set noet :

class role::lucene {
    class configuration {
        $nodes = {
            'production' => {
                'pmtpa' => {
                    'front_ends' => {},
                    'indexers' => {}
                },
                'eqiad' => {
                    'front_ends' => {
                        # enwiki
                        'pool1' => {
                            'search1001' => ['enwiki.nspart1.sub1', 'enwiki.nspart1.sub2', 'enwiki.spell'],
                            'search1002' => ['enwiki.nspart1.sub1', 'enwiki.nspart1.sub2'],
                            'search1003' => ['enwiki.nspart1.sub1', 'enwiki.nspart1.sub2', 'enwiki.nspart2*'],
                            'search1004' => ['enwiki.nspart1.sub1.hl', 'enwiki.nspart1.sub2.hl'],
                            'search1005' => ['enwiki.nspart1.sub1.hl', 'enwiki.nspart1.sub2.hl'],
                            'search1006' => ['enwiki.nspart2*', 'enwiki.spell'],
                        },
                        # de,fr,jawiki
                        'pool2' => {
                            'search1007' => ['frwiki.nspart1', 'frwiki.nspart2', 'jawiki.nspart1', 'jawiki.nspart2', 'dewiki.nspart1', 'dewiki.nspart2'],
                            'search1008' => ['frwiki.nspart1', 'frwiki.nspart2', 'jawiki.nspart1', 'jawiki.nspart2', 'dewiki.nspart1', 'dewiki.nspart2'],
                            'search1009' => ['dewiki.nspart1.hl', 'dewiki.nspart2.hl', 'frwiki.nspart1.hl', 'frwiki.nspart2.hl', 'frwiki.spell', 'dewiki.spell'],
                            'search1010' => ['dewiki.nspart1.hl', 'dewiki.nspart2.hl', 'frwiki.nspart1.hl', 'frwiki.nspart2.hl', 'frwiki.spell', 'dewiki.spell'],
                        },
                        # it,nl,ru,sv,pl,pt,es,zhwiki
                        'pool3' => {
                            'search1011' => ['eswiki itwiki.nspart1', 'ruwiki.nspart1', 'nlwiki.nspart1',
                                'svwiki.nspart1', 'plwiki.nspart1', 'ptwiki.nspart1', 'zhwiki.nspart1', 'eswiki.hl'],
                            'search1012' => ['eswiki itwiki.nspart1', 'ruwiki.nspart1', 'nlwiki.nspart1',
                                'svwiki.nspart1', 'plwiki.nspart1', 'ptwiki.nspart1', 'zhwiki.nspart1', 'eswiki.hl'],
                            'search1013' => ['itwiki.nspart1.hl', 'itwiki.nspart2.hl', 'nlwiki.nspart1.hl', 'nlwiki.nspart2.hl', 'ruwiki.nspart1.hl', 'ruwiki.nspart2.hl',
                                'itwiki.spell', 'nlwiki.spell', 'ruwiki.spell', 'svwiki.spell', 'plwiki.spell', 'ptwiki.spell', 'eswiki.spell'],
                            'search1014' => ['itwiki.nspart1.hl', 'itwiki.nspart2.hl', 'nlwiki.nspart1.hl', 'nlwiki.nspart2.hl', 'ruwiki.nspart1.hl', 'ruwiki.nspart2.hl',
                                'itwiki.spell', 'nlwiki.spell', 'ruwiki.spell', 'svwiki.spell', 'plwiki.spell', 'ptwiki.spell', 'eswiki.spell'],
                            'search1023' => ['svwiki.nspart1.hl', 'svwiki.nspart2.hl', 'plwiki.nspart1.hl', 'plwiki.nspart2.hl', 'ptwiki.nspart1.hl', 'ptwiki.nspart2.hl',
                                'itwiki.nspart2', 'nlwiki.nspart2', 'ruwiki.nspart2', 'svwiki.nspart2', ' plwiki.nspart2', 'ptwiki.nspart2', 'zhwiki.nspart2'],
                            'search1024' => ['svwiki.nspart1.hl', 'svwiki.nspart2.hl', 'plwiki.nspart1.hl', 'plwiki.nspart2.hl', 'ptwiki.nspart1.hl', 'ptwiki.nspart2.hl',
                                'itwiki.nspart2', 'nlwiki.nspart2', 'ruwiki.nspart2', 'svwiki.nspart2', ' plwiki.nspart2', 'ptwiki.nspart2', 'zhwiki.nspart2'],
                        },
                        # everything else
                        'pool4' => {
                            'search1015' => ['*?'],
                            'search1016' => ['*?'],
                            'search1019' => ['commonswiki.nspart1', 'commonswiki.nspart1.hl', 'commonswiki.nspart2', 'commonswiki.nspart2.hl',
                                'wikidatawiki', 'metawiki', 'enwiktionary',
                                '(?!(enwiki.|dewiki.|frwiki.|itwiki.|nlwiki.|ruwiki.|svwiki.|plwiki.|eswiki.|ptwiki.))*.spell'],
                            'search1020' => ['commonswiki.nspart1', 'commonswiki.nspart1.hl', 'commonswiki.nspart2', 'commonswiki.nspart2.hl',
                                'wikidatawiki', 'metawiki', 'enwiktionary',
                                '(?!(enwiki.|dewiki.|frwiki.|itwiki.|nlwiki.|ruwiki.|svwiki.|plwiki.|eswiki.|ptwiki.))*.spell'],
                            'search1021' => ['(?!(enwiki.|dewiki.|frwiki.|itwiki.|nlwiki.|ruwiki.|svwiki.|plwiki.|eswiki.|ptwiki.|jawiki.|zhwiki.))*.hl'],
                            'search1022' => ['(?!(enwiki.|dewiki.|frwiki.|itwiki.|nlwiki.|ruwiki.|svwiki.|plwiki.|eswiki.|ptwiki.|jawiki.|zhwiki.))*.hl'],
                        },
                        # prefix hosts for all pools
                        'prefix' => {
                            'search1017' => ['*.prefix'],
                            'search1018' => ['*.prefix'],
                        },
                        # assigned to fake host to disable them
                        'disabled' => {
                            'search1000x' => ['*tspart1', '*tspart2', 'en-titles*', 'de-titles*', 'ja-titles*', 'it-titles*',
                                'sv-titles*', 'pl-titles*', 'pt-titles*', 'es-titles*', 'zh-titles*', 'nl-titles*', 'ru-titles*', 'fr-titles*',
                                'commonswiki.spell', 'commonswiki.nspart1.hl', 'commonswiki.nspart1', 'commonswiki.nspart2.hl', 'commonswiki.nspart2',
                                '*.related', 'jawiki.nspart1.hl', 'jawiki.nspart2.hl', 'zhwiki.nspart1.hl', 'zhwiki.nspart2.hl'],
                        }
                    },
                    'indexers' => {
                        'searchidx1001' => ['*']
                    }
                }
            }
        }

        # hash for lsearch-global configuration template
        $lsearch_global = {
            'production' => {
                'alldblist' => '/a/search/conf/all.dblist',
                'initialisesettings' => '/a/search/conf/InitialiseSettings.php',
            },
            'labs' => {
                'alldblist' => '/a/search/conf/all-labs.dblist',
                'initialisesettings' => '/a/search/conf/mw-beta-context.php',
            }
        }

        # lucene.jobs.sh tweaking
        # java_heap_size_initial => -Xms
        # java_heap_size_maximum  => -Xmx
        $lucene_jobs = {
            'production' => {
                'importer' => {
                    'java_heap_size_initial' => '128m',
                    'java_heap_size_maximum' => '2000m',
                },
                'prefixindexbuilder' => {
                    'java_heap_size_initial' => '',
                    'java_heap_size_maximum' => '4000m',
                },
                'relatedbuilder' => {
                    'java_heap_size_initial' => '',
                    'java_heap_size_maximum' => '4000m',
                },
                'suggestbuilder' => {
                    'java_heap_size_initial' => '',
                    'java_heap_size_maximum' => '8000m',
                },
            },
            'labs' => {
                'importer' => {
                    'java_heap_size_initial' => '128m',
                    'java_heap_size_maximum' => '2000m',
                },
                'prefixindexbuilder' => {
                    'java_heap_size_initial' => '',
                    'java_heap_size_maximum' => '4000m',
                },
                'relatedbuilder' => {
                    'java_heap_size_initial' => '',
                    'java_heap_size_maximum' => '4000m',
                },
                'suggestbuilder' => {
                    'java_heap_size_initial' => '',
                    'java_heap_size_maximum' => '8000m',
                },
            },
        }
    }

    class beta {
        mount { '/a':
            ensure  => mounted,
            device  => '/dev/vdb',
            fstype  => 'auto',
            options => 'defaults,nobootwait,comment=cloudconfig',
        }
    }

    class indexer {
        system::role { 'role::lucene::indexer':
            description => 'Lucene search indexer',
        }

        if $::realm == 'labs' {
            require role::lucene::beta
        }

        # Include packages needed for MW maintenance scripts
        include standard
        include mediawiki
        include mediawiki::php

        # dependency for wikimedia-task-appserver
        service { 'apache':
            ensure => stopped,
            name   => 'apache2',
            enable => false,
        }

        class { 'lucene::server':
            indexer    => true,
            udplogging => false,
        }
    }

    class front_end {
        class common($search_pool) {
            system::role { 'role::lucene::front-end':
                description => 'Front end lucene search server',
            }

            include lvs::configuration
            class { 'lvs::realserver':
                realserver_ips => [ $lvs::configuration::lvs_service_ips[$::realm][$search_pool][$::site] ],
            }

            include standard

            $updloggingpool = $search_pool ? {
                'search_prefix' => false,
                default         => true
            }

            class { 'lucene::server':
                udplogging => $updloggingpool,
            }
        }
        class pool1 {
            class { 'role::lucene::front_end::common':
                search_pool => 'search_pool1',
            }
        }
        class pool2 {
            class { 'role::lucene::front_end::common':
                search_pool => 'search_pool2',
            }
        }
        class pool3 {
            class { 'role::lucene::front_end::common':
                search_pool => 'search_pool3',
            }
        }
        class pool4 {
            class { 'role::lucene::front_end::common':
                search_pool => 'search_pool4',
            }
        }
        class pool5 {
            class { 'role::lucene::front_end::common':
                search_pool => 'search_pool5',
            }
        }
        # Search frontend for the beta cluster
        class poolbeta {
            if $::realm == 'labs' {
                require role::lucene::beta
            }
            class { 'role::lucene::front_end::common':
                search_pool => 'search_poolbeta',
            }
        }
        class prefix {
            class { 'role::lucene::front_end::common':
                search_pool => 'search_prefix',
            }
        }
    }
}
