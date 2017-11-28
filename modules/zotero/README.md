Introduction
============

Zotero is a service based on running the Zotero Firefox extension via xpcshell
and JavaScript wrappers. It is meant to scrape URLs provided to it and return
metadata. This is the puppet module for managing it.

Zotero is a free and open-source reference management software
for bibliographic data and related research materials.
See <https://en.wikipedia.org/wiki/Zotero>.

Prerequisites
=============

* xulrunner 24. Exists on jessie and trusty-wikimedia

Usage
=====
include zotero

