#!/usr/bin/env python
# -*- coding: utf8 -*-
"""
  Create an anonymous user in Grafana

  This script will check if a user named 'Anonymous' exists in Grafana.
  If the user does not exist, this script will create it.

"""
from __future__ import print_function

import sys

from sqlalchemy import create_engine
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session
from sqlalchemy.sql import exists, func


if len(sys.argv) != 2 or sys.argv[1] not in ('--check', '--create'):
    print('Usage: %s [--check / --create]' % __file__, file=sys.stderr)
    sys.exit(1)

engine = create_engine('sqlite:////var/lib/grafana/grafana.db')
Base = automap_base()
Base.prepare(engine, reflect=True)
User = Base.classes.user
session = Session(engine)

anon_exists = session.query(exists().where(User.name == 'Anonymous')).scalar()

if sys.argv[1] == '--check':
    sys.exit(0 if anon_exists else 1)

if anon_exists:
    print('Nothing to do -- user already exists.', file=sys.stderr)
    sys.exit(0)

print('Creating anonymous user... ', end='', file=sys.stderr)
session.add(User(
  version=0,
  login='Anonymous',
  email='wikitech@wikimedia.org',
  name='Anonymous',
  org_id=1,
  is_admin=0,
  email_verified=0,
  created=func.now(),
  updated=func.now(),
))
session.commit()
print('done!', file=sys.stderr)
sys.exit(0)
