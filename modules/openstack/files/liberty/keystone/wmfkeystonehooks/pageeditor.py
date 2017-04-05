# Copyright 2014 Andrew Bogott for the Wikimedia Foundation
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import threading
import time
import mwclient
import logging

from oslo_config import cfg


LOG = logging.getLogger('nova.%s' % __name__)

wiki_opts = [
    cfg.StrOpt('wiki_host',
               default='deployment.wikimedia.beta.wmflabs.org',
               help='Mediawiki host to receive updates.'),
    cfg.StrOpt('wiki_domain',
               default='labs',
               help='wiki domain to receive updates.'),
    cfg.StrOpt('wiki_page_prefix',
               default='InstanceStatus_',
               help='Created pages will have form <prefix>_<instancename>.'),
    cfg.StrOpt('wiki_instance_region',
               default='Unknown',
               help='Hard-coded region name for wiki page.  A bit of a hack.'),
    cfg.StrOpt('wiki_instance_dns_domain',
               default='',
               help='Hard-coded domain for wiki page. E.g. pmtpa.wmflabs'),
    cfg.StrOpt('wiki_login',
               default='login',
               help='Account used to edit wiki pages.'),
    cfg.StrOpt('wiki_password',
               default='password',
               help='Password for wiki_login.')]


CONF = cfg.CONF
CONF.register_opts(wiki_opts)


begin_comment = "<!-- autostatus begin -->"
end_comment = "<!-- autostatus end -->"


class PageEditor():
    """Utility class to maintain a mediawiki session and
       edit pages
    """

    def __init__(self):
        self.host = CONF.wiki_host
        self.site_lock = threading.Lock()
        self._site = None

    @staticmethod
    def _wiki_login(host):
        site = mwclient.Site(("https", host),
                             retry_timeout=10,
                             max_retries=3)
        if site:
            # Races kills a fair number of these logins, so give it a few tries.
            for count in reversed(xrange(3)):
                try:
                    site.login(CONF.wiki_login, CONF.wiki_password,
                               domain=CONF.wiki_domain)
                    return site
                except mwclient.APIError:
                    LOG.exception(
                        "mwclient login failed, %d more tries" % count)
                    time.sleep(20)
            raise mwclient.MaximumRetriesExceeded()
        else:
            LOG.warning("Unable to reach %s.  We'll keep trying, "
                        "but pages will be out of sync in the meantime."
                        % host)
            return None

    def _get_site(self):
        with self.site_lock:
            if self._site is None:
                self._site = self._wiki_login(self.host)
            return self._site

    def edit_page(self, text, resource_name, delete_page=False,
                  template='Nova Resource', second_try=False):
        site = self._get_site()
        pagename = "%s%s" % (CONF.wiki_page_prefix, resource_name)
        LOG.debug("Writing wiki page http://%s/wiki/%s" %
                  (self.host, pagename))

        page = site.Pages[pagename]
        failed = False
        try:
            if delete_page:
                page.delete(reason='Resource deleted')
            else:

                page_string = "%s\n{{%s%s}}\n%s" % (begin_comment,
                                                    template,
                                                    text,
                                                    end_comment)

                pText = page.edit()
                start_replace_index = pText.find(begin_comment)
                if start_replace_index == -1:
                    # Just stick new text at the top.
                    newText = "%s\n%s" % (page_string, pText)
                else:
                    # Replace content between comment tags.
                    end_replace_index = pText.find(end_comment,
                                                   start_replace_index)
                    if end_replace_index == -1:
                        end_replace_index = (start_replace_index +
                                             len(begin_comment))
                    else:
                        end_replace_index += len(end_comment)
                    newText = "%s%s%s" % (pText[:start_replace_index],
                                          page_string,
                                          pText[end_replace_index:])
                page.save(newText, "Auto update of instance info.")
        except (mwclient.errors.InsufficientPermission,
                mwclient.errors.LoginError):
            LOG.exception(
                "Failed to update wiki page..."
                " trying to re-login next time.")
            with self.site_lock:
                self._site = None
            failed = True

        if failed and not second_try:
            self.edit_page(page_string, resource_name, delete_page,
                           second_try=True)
