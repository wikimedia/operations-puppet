# == Class profile::analytics::refinery::job::druid_load
#
# Installs spark jobs to load data sets to Druid.
#
class profile::analytics::refinery::job::druid_load {
    require ::profile::analytics::refinery

    # Update this when you want to change the version of the refinery job jar
    # being used for the druid load jobs.
    $refinery_version = '0.0.83'

    # Use this value as default refinery_job_jar.
    Profile::Analytics::Refinery::Job::Eventlogging_to_druid_job {
        refinery_job_jar => "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}.jar"
    }

    # Load event.NavigationTiming
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'navigationtiming':
        job_config => {
            dimensions    => 'event.action,event.isAnon,event.isOversample,event.mediaWikiVersion,event.mobileMode,event.namespaceId,event.netinfoEffectiveConnectionType,event.originCountry,recvFrom,revision,useragent.browser_family,useragent.browser_major,useragent.device_family,useragent.is_bot,useragent.os_family,useragent.os_major,wiki',
            time_measures => 'event.connectEnd,event.connectStart,event.dnsLookup,event.domComplete,event.domInteractive,event.fetchStart,event.firstPaint,event.loadEventEnd,event.loadEventStart,event.redirecting,event.requestStart,event.responseEnd,event.responseStart,event.secureConnectionStart,event.unload,event.gaps,event.mediaWikiLoadEnd,event.RSI',
        },
    }

    # Load event.ReadingDepth
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'readingdepth':
        job_config => {
            dimensions    => 'event.action,event.default_sample,event.isAnon,event.namespaceId,event.skin,revision,useragent.browser_family,useragent.browser_major,useragent.browser_minor,useragent.device_family,useragent.is_bot,useragent.os_family,useragent.os_major,useragent.os_minor,wiki,event.page_issues_a_sample,event.page_issues_b_sample',
            time_measures => 'event.domInteractiveTime,event.firstPaintTime,event.totalLength,event.visibleLength',
        },
    }

    # Load event.PageIssues
    # Deactivated for now until new experiment.
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'pageissues':
        ensure     => 'absent',
        job_config => {
            dimensions => 'event.action,event.editCountBucket,event.isAnon,event.issuesSeverity,event.issuesVersion,event.namespaceId,event.sectionNumbers,revision,wiki,useragent.browser_family,useragent.browser_major,useragent.browser_minor,useragent.device_family,useragent.is_bot,useragent.os_family,useragent.os_major,useragent.os_minor',
        },
    }
}
