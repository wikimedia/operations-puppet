# SPDX-License-Identifier: Apache-2.0
from flask import Flask, request
app = Flask(__name__)


@app.route("/")
def root():
    return '<br />'.join(['{}={}'.format(k, v) for k, v in request.environ.items()])


application = app
