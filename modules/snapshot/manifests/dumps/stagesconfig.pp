class snapshot::dumps::stagesconfig {

    include ::snapshot::dumps::dirs
    $confsdir = $snapshot::dumps::dirs::confsdir

    $firststage_args = '--cutoff {STARTDATE} --date {STARTDATE}'
    $rest_args = '--date {STARTDATE} --onepass --prereqs'
    $wikiargs = '/bin/bash ./worker --skipdone --exclusive --log'

    $args_smallwikis = "${wikiargs} --configfile ${confsdir}/wikidump.conf"
    $args_bigwikis = "${wikiargs} --configfile ${confsdir}/wikidump.conf.bigwikis"
    $args_enwiki = "${wikiargs} --configfile ${confsdir}/wikidump.conf.enwiki"
    $args_wikidatawiki = "${wikiargs} --configfile ${confsdir}/wikidump.conf.wikidatawiki"

    $jobs_to_skip = join(['metahistorybz2dump',
                          'metahistorybz2dumprecombine',
                          'metahistory7zdump',
                          'metahistory7zdumprecombine'], ',')

    $stages = {
        smallwikis   => {
            firststage => "${args_smallwikis} ${firststage_args}",
            rest       => "${args_smallwikis} ${rest_args}",
        },
        bigwikis     => {
            firststage => "${args_bigwikis} ${firststage_args}",
            rest       => "${args_bigwikis} ${rest_args}",
        },
        enwiki       => {
            firststage => "${args_enwiki} ${firststage_args}",
            rest       => "${args_enwiki} ${rest_args}",
        },
        wikidatawiki => {
            firststage => "${args_wikidatawiki} ${firststage_args}",
            rest       => "${args_wikidatawiki} ${rest_args}",
        },
        skipjob_args => "--skipjobs ${jobs_to_skip}",
    }

    snapshot::dumps::stagesconf { 'stages_normal':
        stagestype => 'normal',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_partial':
        stagestype => 'partial',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_normal_nocreate':
        stagestype => 'normal_nocreate',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_partial_nocreate':
        stagestype => 'partial_nocreate',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_normal_enwiki':
        stagestype => 'normal_enwiki',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_partial_enwiki':
        stagestype => 'partial_enwiki',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_normal_nocreate_enwiki':
        stagestype => 'normal_nocreate_enwiki',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_partial_nocreate_enwiki':
        stagestype => 'partial_nocreate_enwiki',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_normal_wikidatawiki':
        stagestype => 'normal_wikidatawiki',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_partial_wikidatawiki':
        stagestype => 'partial_wikidatawiki',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_normal_nocreate_wikidatawiki':
        stagestype => 'normal_nocreate_wikidatawiki',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_partial_nocreate_wikidatawiki':
        stagestype => 'partial_nocreate_wikidatawiki',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_create':
        stagestype => 'create',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_create_smallwikis':
        stagestype => 'create_small',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_create_bigwikis':
        stagestype => 'create_big',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_create_enwiki':
        stagestype => 'create_enwiki',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_create_wikidatawiki':
        stagestype => 'create_wikidatawiki',
        stages     => $stages,
    }
}
