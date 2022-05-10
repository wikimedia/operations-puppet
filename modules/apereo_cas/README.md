<!-- SPDX-License-Identifier: Apache-2.0 -->
# Apereo Cas module

Acceptance testing can be performed with the following command

`BEAKER_set="debian10" bundle exec rake beaker`

Cas is bundled with a set of default settings which are listed in the `application.properties` file.  A fresh copy of the applications.properties file can be optained by unpacking the war file

```
# cd cas-overlay-template
# ./gradlew build
# unzip build/libs/cas.war WEB-INF/classes/application.properties
# cp WEB-INF/classes/application.properties /your/git/puppet/modules/apereo_cas/
```
