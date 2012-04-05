# Class: misc::mwlib

# Installs needed packages for pediapress/mwlib.
class misc::mwlib::packages {

	package { [ "gcc", "g++", "make", "python", "python-dev", "python-virtualenv", "libjpeg-dev", "libz-dev", "libfreetype6-dev", "liblcms-dev", "libxml2-dev", "libxslt-dev", "ocaml-nox", "git-core", "python-imaging", "python-lxml", "texlive-latex-recommended", "ploticus", "dvipng", "imagemagick", "pdftk" ]:
		ensure   => 'installed',
	}

}

class misc::mwlib::users {
	systemuser { "pp": name => "pp", home => "/opt/pp", shell => "/bin/bash" }
}
