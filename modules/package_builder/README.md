Introduction
============

A module used to populate a Debian/Ubuntu package building environment. Meant to
be used in the Wikimedia Labs environment but could be adapted for other
environments as well.

Setting it up
=============

Include the package\_builder class in your machine. That can be done with whatever
ENC you have puppet working with but in Wikimedia Labs you should create a
puppet group, then add the class in the puppet group and just configure your VM
with that class

After puppet is done you will have 8 pristine cowbuilder environments. Those
would be:

 * precise-amd64
 * trusty-amd64
 * jessie-amd64
 * sid-amd64
 * precise-i386
 * trusty-i386
 * jessie-i386
 * sid-i386

See more below on how to use those

Building packages
=================

You just either download a ready package:

    dget http://http.debian.net/debian/pool/main/d/dh-virtualenv/dh-virtualenv_0.10-1.dsc
    export DIST=jessie
    sudo -E cowbuilder --build dh-virtualenv_0.10-1.dsc

or if you are developing a package and are in the package directory:

    DIST=jessie pdebuild

Feel free to change jessie for precise, trusty or sid

Architectures
=============

ARCH=amd64, or ARCH=i386 is supported if you feel like building for
different architecture versions.

Wikimedia repos
===============

Aside from sid, the rest of the distributions allow for satisfying build time
dependencies via the wikimedia repos.

To use packages from the wikimedia repos to satisfy build dependencies during
building you can use WIKIMEDIA=yes. There is also the approach of appending
-wikimedia to the DIST variable and pbuilderrc will do what you want.

Examples:

    DIST=jessie-wikimedia pdebuild
    WIKIMEDIA=yes DIST=jessie pdebuild

The commands above are equivalent and will both build a package for the
jessie distribution using the Wikimedia apt repository.

git-buildpackage
================

git-pbuilder can be used by git-buildpackage to leverage all of the above. The
trick is to use GIT\_PBUILDER\_AUTOCONF=no i.e.:

    GIT_PBUILDER_AUTOCONF=no DIST=trusty WIKIMEDIA=yes git-buildpackage -us -uc --git-builder=git-pbuilder

The GIT\_PBUILDER\_AUTOCONF tells git-pbuilder to forego all attempts to discover the base path, tarball, or
configuration file to set up the pbuilder options but rather instead rely on the settings in .pbuilderrc

Results
=======

The resulting deb files should be in /var/cache/pbuilder/result/${DIST}-${ARCH} like:

    /var/cache/pbuilder/result/trusty-amd64/

Notes
=====

If you are getting confused over the naming of pbuilder/cowbuilder, here's some
info to help you. pbuilder is the actual base software, cowbuilder is an
extension to allow pbuilder to use COW (copy on write) instead of slow .tar.gz
base files. For all intents and purposes this should be transparent to you as
cowbuilder is the default pbuilder builder.

Networking
==========

cowbuilder/pbuilder block networking using namespaces and unshare in the above
environments. If your package requires internet access to build successfully, it
will not work. First, try to fix the package. If that is impossible/undesirable,
USENETWORK=yes in /etc/pbuilderrc or .pbuilderrc can be used to override that
behaviour. Make sure that the building host has internet access though, or else
your change will not be useful
I
