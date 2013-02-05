Jenkins module
==============

To install Jenkins:

 include 'jenkins'

To have it made publicly available through an Apache Proxy:

 include 'jenkins'
 include 'jenkins::webserver'

That second use case requireis the global Wikimedia manifest "webserver".
