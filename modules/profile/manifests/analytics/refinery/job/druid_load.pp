# == Class profile::analytics::refinery::job::druid_load
#
# Installs spark jobs to load data sets to Druid.
#
class profile::analytics::refinery::job::druid_load {
    require ::profile::analytics::refinery

    # Update this when you want to change the version of the refinery job jar
    # being used for the druid load jobs.
    $refinery_version = '0.0.78'

    # Use this value as default refinery_job_jar.
    Profile::Analytics::Refinery::Job::Eventlogging_to_druid_job {
        refinery_job_jar => "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}.jar"
    }

    # Load event.NavigationTiming
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'navigationtiming':
        job_config => {
            dimensions    => 'event_action,event_isAnon,event_isOversample,event_mediaWikiVersion,event_mobileMode,event_namespaceId,event_netinfoEffectiveConnectionType,event_originCountry,recvFrom,revision,userAgent_browser_family,userAgent_browser_major,userAgent_device_family,userAgent_is_bot,userAgent_os_family,userAgent_os_major,wiki',
            time_measures => 'event_connectEnd,event_connectStart,event_dnsLookup,event_domComplete,event_domInteractive,event_fetchStart,event_firstPaint,event_loadEventEnd,event_loadEventStart,event_redirecting,event_requestStart,event_responseEnd,event_responseStart,event_secureConnectionStart,event_unload,event_gaps,event_mediaWikiLoadEnd,event_RSI',
        },
    }

    # Load event.ReadingDepth
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'readingdepth':
        job_config => {
            dimensions    => 'event_action,event_default_sample,event_isAnon,event_namespaceId,event_skin,revision,userAgent_browser_family,userAgent_browser_major,userAgent_browser_minor,userAgent_device_family,userAgent_is_bot,userAgent_os_family,userAgent_os_major,userAgent_os_minor,wiki,event_page-issues-a_sample,event_page-issues-b_sample',
            time_measures => 'event_domInteractiveTime,event_firstPaintTime,event_totalLength,event_visibleLength',
        },
    }

    # Load event.PageIssues
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'pageissues':
        job_config => {
            dimensions    => 'event_action,event_editCountBucket,event_isAnon,event_issuesSeverity,event_issuesVersion,event_namespaceId,event_sectionNumbers,revision,wiki,userAgent_browser_family,userAgent_browser_major,userAgent_browser_minor,userAgent_device_family,userAgent_is_bot,userAgent_os_family,userAgent_os_major,userAgent_os_minor',
        },
    }

}
