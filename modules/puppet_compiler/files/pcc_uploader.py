#!/usr/bin/python3
"""Simple flask application"""
import os

from pathlib import Path

import magic
import werkzeug.exceptions

from flask import Flask, jsonify, request
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.config.from_json('pcc_uploader.json')


@app.route("/", methods=['POST'])
def upload():
    """upload file"""
    if 'file' not in request.files:
        raise werkzeug.exceptions.NotImplemented("'file' required")
    upload_file = request.files['file']
    # 2048 is recommended by upstream docs
    mime_type = magic.detect_from_content(upload_file.stream.read(2048))
    upload_file.stream.seek(0)
    if mime_type.mime_type != 'application/x-xz':
        raise werkzeug.exceptions.UnsupportedMediaType(mime_type.name)
    if upload_file:
        filename = secure_filename(upload_file.filename)
        upload_file.save(Path(app.config['UPLOAD_FOLDER'], filename))
        return jsonify(result=True)
    raise werkzeug.exceptions.NotImplemented('Unknown Error')


application = app
if __name__ == '__main__':
    if not Path(app.config['UPLOAD_FOLDER']).is_dir() or not os.access(
        app.config['UPLOAD_FOLDER'], os.W_OK
    ):
        raise SystemExit(f"unable to write to {app.config['UPLOAD_FOLDER']}")
    app.run(debug=True)
