# Class: misc::mwlib

# Installs needed packages for pediapress/mwlib.
class misc::mwlib::packages {

	package { [ "dvipng", "g++", "gcc", "git-core", "imagemagick", "libfreetype6-dev", "libjpeg-dev",
			"liblcms-dev", "libxml2-dev", "libxslt-dev", "libz-dev", "make", "ocaml-nox", "pdftk",
			"ploticus", "python", "python-dev", "python-greenlet", "python-imaging", "python-lxml",
			"python-pyparsing", "python-pypdf", "python-virtualenv", "texlive-latex-recommended" ]:
		ensure   => 'installed',
	}

}

class misc::mwlib::users {
	systemuser { "pp": name => "pp", home => "/opt/pp", shell => "/bin/bash" }
}
