# -*- python -*-

# Copyright (C) 1998,1999,2000 by the Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


"""This is the module which takes your site-specific settings.

From a raw distribution it should be copied to mm_cfg.py.  If you
already have an mm_cfg.py, be careful to add in only the new settings
you want.  The complete set of distributed defaults, with annotation,
are in ./Defaults.  In mm_cfg, override only those you want to
change, after the

  from Defaults import *

line (see below).

Note that these are just default settings - many can be overridden via the
admin and user interfaces on a per-list or per-user basis.

Note also that some of the settings are resolved against the active list
setting by using the value as a format string against the
list-instance-object's dictionary - see the distributed value of
DEFAULT_MSG_FOOTER for an example."""


#######################################################
#    Here's where we get the distributed defaults.    #

from Defaults import *

##############################################################
# Put YOUR site-specific configuration below, in mm_cfg.py . #
# See Defaults.py for explanations of the values.            #

#-------------------------------------------------------------
# The name of the list Mailman uses to send password reminders
# and similar. Don't change if you want mailman-owner to be
# a valid local part.
MAILMAN_SITE_LIST = 'mailman'

#-------------------------------------------------------------
# If you change these, you have to configure your http server
# accordingly (Alias and ScriptAlias directives in most httpds)
DEFAULT_URL_PATTERN = 'https://%s/mailman/'
PRIVATE_ARCHIVE_URL = '/mailman/private'
IMAGE_LOGOS = '/images/mailman/'

#-------------------------------------------------------------
# Default domain for email addresses of newly created MLs
DEFAULT_EMAIL_HOST = 'lists.wikimedia.org'
#-------------------------------------------------------------
# Default host for web interface of newly created MLs
DEFAULT_URL_HOST = 'lists.wikimedia.org'
#-------------------------------------------------------------
# Required when setting any of its arguments.
add_virtualhost(DEFAULT_URL_HOST, DEFAULT_EMAIL_HOST)

#-------------------------------------------------------------
# The default language for this server.
DEFAULT_SERVER_LANGUAGE = 'en'

#-------------------------------------------------------------
# Iirc this was used in pre 2.1, leave it for now
USE_ENVELOPE_SENDER = 0              # Still used?

#-------------------------------------------------------------
# Unset send_reminders on newly created lists
DEFAULT_SEND_REMINDERS = 0

#-------------------------------------------------------------
# Uncomment this if you configured your MTA such that it
# automatically recognizes newly created lists.
# (see /usr/share/doc/mailman/README.{EXIM,...})
# MTA=None   # Misnomer, suppresses alias output on newlist
MTA = None

#-------------------------------------------------------------
# Uncomment if you use Postfix virtual domains, but be sure to
# read /usr/share/doc/mailman/README.POSTFIX first.
# MTA='Postfix'

#-------------------------------------------------------------
# Uncomment if you want to filter mail with SpamAssassin. For
# more information please visit this website:
# http://www.daa.com.au/~james/articles/mailman-spamassassin/
# GLOBAL_PIPELINE.insert(1, 'SpamAssassin')

# Note - if you're looking for something that is imported from mm_cfg, but you
# didn't find it above, it's probably in /usr/lib/mailman/Mailman/Defaults.py.

# Set Reply-To to the list by default
DEFAULT_REPLY_GOES_TO_LIST = 1

# Htdig integration
#HTDIG_RUNDIG_PATH = "/usr/bin/rundig"
#HTDIG_HTSEARCH_PATH = "/usr/lib/cgi-bin/htsearch"
#USE_HTDIG = 1

# Customization
SHORTCUT_ICON = 'favicon.png'

#Limiting the size of message to prevent archrunner from dying...
MAX_MESSAGE_SIZE = 5120

# we put footers etc. and hence invalidate DKIM signatures
# although they shouldn't theoretically hurt, remove them to avoid confusion
REMOVE_DKIM_HEADERS = Yes

# use https for mailman archive links instead of the default http
PUBLIC_ARCHIVE_URL = 'https://%(hostname)s/pipermail/%(listname)s/'

# see T48049
SENDER_HEADERS = ('from')
