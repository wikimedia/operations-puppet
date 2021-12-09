#!/usr/bin/python3
"""Simple flask application"""
import os

from pathlib import Path
from time import time

import magic
import werkzeug.exceptions

from flask import Flask, jsonify, request

app = Flask(__name__)
app.config.from_json('pcc_uploader.json')


def get_save_dir() -> Path:
    """Return the directory used to save files.

    This function parses the form parameter raising errors as needed.
    if all is ok return a path to save files

    Returns:
        save_dir: A destination directory to save uploaded files to

    """
    if 'file' not in request.files:
        raise werkzeug.exceptions.NotImplemented("'file' required")
    if 'realm' not in request.form:
        raise werkzeug.exceptions.NotImplemented("'realm' required")
    realm = request.form['realm']
    if realm not in app.config['REALMS']:
        raise werkzeug.exceptions.Forbidden
    # TODO: probably need to use IPaddr to compare ipv6 addrs properly
    if request.remote_addr not in app.config['REALMS'][realm]:
        raise werkzeug.exceptions.Forbidden
    save_dir = Path(app.config['UPLOAD_FOLDER'], realm)
    if not save_dir.is_dir():
        raise werkzeug.exceptions.Forbidden
    return save_dir


@app.route("/", methods=['POST'])
def upload():
    """upload file"""
    save_dir = get_save_dir()
    upload_file = request.files['file']
    # 2048 is recommended by upstream docs
    mime_type = magic.detect_from_content(upload_file.stream.read(2048))
    # Need to seek back to the beginning to save
    upload_file.stream.seek(0)
    if mime_type.mime_type != 'application/x-xz':
        raise werkzeug.exceptions.UnsupportedMediaType(mime_type.name)
    if upload_file:
        # TODO: possibly check the upload_file.filename matches something?
        # however this is file is public so doesn't really add much security
        filename = f'{time()}.facts.tar.xz'
        # TODO: no need to cast when on bullseye
        upload_file.save(str(save_dir / filename))
        return jsonify(result=True)
    raise werkzeug.exceptions.NotImplemented('Unknown Error')


application = app
if __name__ == '__main__':
    if not Path(app.config['UPLOAD_FOLDER']).is_dir() or not os.access(
        app.config['UPLOAD_FOLDER'], os.W_OK
    ):
        raise SystemExit(f"unable to write to {app.config['UPLOAD_FOLDER']}")
    app.run(debug=True)
