# -*- coding: utf-8 -*-
"""
  pyglet -- a Pygments micro-service

  Copyright 2015 Ori Livneh <ori@wikimedia.org>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

"""
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

import argparse

import flask
import gevent.wsgi
import pygments
import pygments.formatters
import pygments.lexers


ap = argparse.ArgumentParser(description='a syntax-highlighting web service')
ap.add_argument('--listen-port', type=int, default=31337)
args = ap.parse_args()
addr = ('127.0.0.1', args.listen_port)

app = flask.Flask(__name__)
formatter = pygments.formatters.HtmlFormatter(encoding='utf-8')
lexer_fields = ('name', 'aliases', 'filename_patterns', 'mime_types')
lexers = [dict(zip(lexer_fields, descriptor)) for descriptor
          in pygments.lexers.get_all_lexers()]


@app.route('/highlight', methods=['POST'])
def highlight_code():
    options = {k: v for k, v in flask.request.form.items()}
    lexer = pygments.lexers.get_lexer_by_name(options.pop('lexer'))
    source = options.pop('source')
    formatter = pygments.formatters.HtmlFormatter(**options)
    return pygments.highlight(source, lexer, formatter)


@app.route('/lexers')
def list_lexers():
    return flask.jsonify(data=lexers)


http_server = gevent.wsgi.WSGIServer(addr, app)
http_server.serve_forever()
