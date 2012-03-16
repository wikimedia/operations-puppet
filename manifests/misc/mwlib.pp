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


class misc::mwlib::users inherits misc::mwlib::groups{

  user { "pp":
    name => "pp",
    home => "/opt/pp",
    shell => "/bin/bash",
    ensure => "present",
    groups => "pp",
    allowdupe => false,
    system => true,
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

