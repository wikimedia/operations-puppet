Introduction
============

A module used to populate a Debian/Ubuntu package building environment. Meant to
be used in the Wikimedia Labs environment but could be adapted for other
environments as well.

How to use
==========

Include the package\_builder class in your machine. That can be done with whatever
ENC you have puppet working with but in Wikimedia Labs you should create a
puppet group, then add the class in the puppet group and just configure your VM
with that class

After puppet is done you just either download a ready package and either:

    export DIST=jessie
    sudo -E pbuilder build dh-virtualenv_0.9-1.dsc

or if you are developing a package and are in the package directory:

    DIST=jessie pdebuild

Feel free to change jessie for precise, trusty or sid

Also ARCH=amd64, or ARCH=i386 is supported if you feel like building for
different architecture versions.

To use packages from the wikimedia repos to satisfy build dependencies during
building you can use WIKIMEDIA=yes. There is also the approach of appending
-wikimedia to the DIST variable and pbuilderrc will do what you want.

Examples:

    DIST=jessie-wikimedia pdebuild
    WIKIMEDIA=yes DIST=jessie pdebuild

Each commands above are equivalents and will both build a package for the
jessie distribution with Wikimedia apt repository.

git-buildpackage
================

git-pbuilder can be used by git-buildpackage to leverage all of the above. The
trick is to use GIT\_PBUILDER\_AUTOCONF=no i.e.:

    GIT_PBUILDER_AUTOCONF=no DIST=trusty WIKIMEDIA=yes git-buildpackage -us -uc --git-builder=git-pbuilder
