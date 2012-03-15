# Class: misc::mwlib::packages

# Installs needed packages for pediapress/mwlib.
class misc::mwlib::packages {

  package { [ "gcc", "g++", "make", "python", "python-dev", "python-virtualenv", "libjpeg-dev", "libz-dev", "libfreetype6-dev", "liblcms-dev", "libxml2-dev", "libxslt-dev", "ocaml-nox", "git-core", "python-imaging", "python-lxml", "texlive-latex-recommended", "ploticus", "dvipng", "imagemagick", "pdftk" ]:
    ensure   => 'installed',
  }

  #package { 'bleh':
  #  provider => 'pip',
  #  ensure => 'installed',
  #}

}


class misc::mwlib::users {

  user { "pp":
    name => "pp",
    groups => [ "pp" ],
    home => "/opt/pp",
    shell => "/bin/sh",
    ensure => "present",
    membership => "minimum",
    manages_homedir => false,
    allowdupe => false,
    system => true,
    require => misc::mwlib::groups,
  }

}


class misc::mwlib::groups {

  group { "pp":
    name => "pp",
    ensure => "present",
    allowdupe => false,
    system => true,
  }

}

