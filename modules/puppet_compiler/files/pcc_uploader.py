#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Simple flask application"""
import cryptography.exceptions
import os

from base64 import b64decode
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.serialization import load_pem_public_key
from pathlib import Path
from time import time

import magic
import werkzeug.exceptions

from flask import Flask, jsonify, request

app = Flask(__name__)
app.config.from_json('pcc_uploader.json')


def verify_sigiture(upload, signature, pkey):
    """Verify that the signature

    Arguments:
        upload: the upload stream
        signature: the uploaded signature
        pkey: the public key used to verify the signature

    Returns:
        bool: indicate if the signature verifies

    """
    signature = b64decode(signature)
    pkey = load_pem_public_key(pkey.encode(), default_backend())
    pkey.verify(
        signature,
        upload.stream.read(),
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH,
        ),
        hashes.SHA256(),
    )


def get_save_dir() -> Path:
    """Return the directory used to save files.

    This function parses the form parameter raising errors as needed.
    if all is ok return a path to save files

    Returns:
        save_dir: A destination directory to save uploaded files to

    """
    if 'file' not in request.files:
        raise werkzeug.exceptions.NotImplemented("'file' required")
    for param in ['realm', 'signature', 'hostname']:
        if param not in request.form:
            raise werkzeug.exceptions.NotImplemented(f"'{param}' required")
    realm = request.form['realm']
    if realm not in app.config['REALMS']:
        raise werkzeug.exceptions.Forbidden(f'unknown realm: {realm}')
    hostname = request.form['hostname']
    if hostname not in app.config['REALMS'][realm]:
        raise werkzeug.exceptions.Forbidden(f"unknown host: {hostname}")
    try:
        verify_sigiture(
            request.files['file'],
            request.form['signature'],
            app.config['REALMS'][realm][hostname],
        )
    except cryptography.exceptions.InvalidSignature as error:
        raise werkzeug.exceptions.Forbidden(f"invalid signature: {error}")
    save_dir = Path(app.config['UPLOAD_FOLDER'], realm)
    if not save_dir.is_dir():
        raise werkzeug.exceptions.FailedDependency(f'{save_dir} not found')
    return save_dir


@app.route("/", methods=['POST'])
def upload():
    """upload file"""
    save_dir = get_save_dir()
    upload_file = request.files['file']
    upload_file.stream.seek(0)
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
