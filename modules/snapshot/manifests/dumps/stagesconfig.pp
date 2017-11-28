class snapshot::dumps::stagesconfig {
    $confsdir = $snapshot::dumps::dirs::confsdir

    $firststage_args = '--cutoff {STARTDATE} --date {STARTDATE}'
    $rest_args = '--date {STARTDATE} --onepass --prereqs'
    $wikiargs = '/bin/bash ./worker --skipdone --exclusive --log'

    $args_smallwikis = "${wikiargs} --configfile ${confsdir}/wikidump.conf.dumps"
    $args_bigwikis = "${wikiargs} --configfile ${confsdir}/wikidump.conf.dumps:bigwikis"
    $args_enwiki = "${wikiargs} --configfile ${confsdir}/wikidump.conf.dumps:en"
    $args_wikidatawiki = "${wikiargs} --configfile ${confsdir}/wikidump.conf.dumps:wd"

    $jobs_to_skip = join(['metahistorybz2dump',
                          'metahistorybz2dumprecombine',
                          'metahistory7zdump',
                          'metahistory7zdumprecombine',
                          'xmlflowhistorydump'], ',')

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

    snapshot::dumps::stagesconf { 'stages_full':
        stagestype => 'full',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_partial':
        stagestype => 'partial',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_full_enwiki':
        stagestype => 'full_enwiki',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_partial_enwiki':
        stagestype => 'partial_enwiki',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_full_wikidatawiki':
        stagestype => 'full_wikidatawiki',
        stages     => $stages,
    }
    snapshot::dumps::stagesconf { 'stages_partial_wikidatawiki':
        stagestype => 'partial_wikidatawiki',
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
