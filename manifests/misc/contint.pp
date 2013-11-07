# vim: set ts=2 sw=2 et :
# continuous integration (CI)

# CI test server as per RT #1204
class misc::contint::test {

  # Creates placeholders for slave-scripts. This need to be moved out to a
  # better place under contint module.
  class jenkins {

    # As of October 2013, the slave scripts are installed with
    # contint::slave-scripts and land under /srv/jenkins.
    # FIXME: clean up Jenkins jobs to no more refer to the paths below:
    file {
      '/var/lib/jenkins/.git':
        ensure => directory,
        mode   => '2775',  # group sticky bit
        group  => 'jenkins';
      '/var/lib/jenkins/bin':
        ensure => directory,
        owner  => 'jenkins',
        group  => 'wikidev',
        mode   => '0775';
    }

  }

}
