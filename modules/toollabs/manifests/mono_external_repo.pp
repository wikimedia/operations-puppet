class toolforge::mono_external_repo {
   apt::repository { "mono-external-${::lsbdistcodename}":
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => "thirdparty/mono-project-${::lsbdistcodename}",
   }
}

