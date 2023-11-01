-- SPDX-License-Identifier: Apache-2.0

CREATE ROLE IF NOT EXISTS mediawiki_services_mobileapps
    WITH PASSWORD = '<%= @application_password %>' AND LOGIN = true AND SUPERUSER = false;

GRANT SELECT ON pregenerated_cache.media_list   TO 'mediawiki_services_mobileapps';
GRANT SELECT ON pregenerated_cache.mobile_html  TO 'mediawiki_services_mobileapps';
GRANT SELECT ON pregenerated_cache.page_summary TO 'mediawiki_services_mobileapps';
GRANT MODIFY ON pregenerated_cache.media_list   TO 'mediawiki_services_mobileapps';
GRANT MODIFY ON pregenerated_cache.mobile_html  TO 'mediawiki_services_mobileapps';
GRANT MODIFY ON pregenerated_cache.page_summary TO 'mediawiki_services_mobileapps';
