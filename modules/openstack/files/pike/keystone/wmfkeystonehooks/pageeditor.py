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
import mwclient
import logging

from wmfkeystoneauth import wikitechclient

from oslo_config import cfg


LOG = logging.getLogger('nova.%s' % __name__)

wiki_opts = [
    cfg.StrOpt('wiki_host',
               default='deployment.wikimedia.beta.wmflabs.org',
               help='Mediawiki host to receive updates.'),
    cfg.StrOpt('wiki_page_prefix',
               default='InstanceStatus_',
               help='Created pages will have form <prefix>_<instancename>.'),
    cfg.StrOpt('wiki_consumer_token',
               default='',
               help='oauth consumer token for wikitech access'),
    cfg.StrOpt('wiki_consumer_secret',
               default='',
               help='oauth consumer secret for wikitech access'),
    cfg.StrOpt('wiki_access_token',
               default='',
               help='oauth access token for wikitech access'),
    cfg.StrOpt('wiki_access_secret',
               default='',
               help='oauth access secret for wikitech access')]


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

    def _get_site(self):
        with self.site_lock:
            if self._site is None:
                client = wikitechclient.WikitechClient(
                    self.host,
                    CONF.wiki_consumer_token,
                    CONF.wiki_consumer_secret,
                    CONF.wiki_access_token,
                    CONF.wiki_access_secret)
                self._site = client.site
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

                pText = page.text()
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
