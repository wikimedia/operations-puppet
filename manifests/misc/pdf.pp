# classes for PDF servers

# installs (requested) font packages
class misc::pdf::fonts {

    # dejavu: meta for all DejaVu variants - http://dejavu.sourceforge.net/
    # indic-fonts: meta for all free Indian language fonts - <debian-in-workers@lists.alioth.debian.org>

    package { [
        'ttf-dejavu',
        'ttf-indic-fonts',
        ]: ensure => latest;
    }

}

#install mediawiki-math package
class misc::pdf::math {
  package { 'mediawiki-math':
    ensure => latest;
  }
}

# tool for manipulating PDF - http://packages.ubuntu.com/search?keywords=pdftk
class misc::pdf::pdftk {
    package { 'pdftk':
        ensure => latest;
    }
}
