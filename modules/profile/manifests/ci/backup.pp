class profile::ci::backup {
    require ::profile::backup::host

    backup::set {'var-lib-jenkins-config': }
    backup::set { 'contint' : }
}
