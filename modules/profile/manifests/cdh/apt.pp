# == Class profile::cdh::apt
#
# Set Cloudera's apt repository to the host. 
#
class profile::cdh::apt {
    apt::repository { 'thirdparty-cloudera':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/cloudera',
    }
}
