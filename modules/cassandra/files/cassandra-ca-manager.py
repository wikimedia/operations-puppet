#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Cassandra certificate management

First, you need a manifest that specifies the Certificate Authority, and
each of the keystores.  For example:

    # The top-level working directory
    base_directory: /path/to/base/directory

    # The Certificate Authority
    authority:
      key:
        size: 2048
      cert:
        subject:
          organization: WMF
          country: US
          unit: Services
        valid: 365
      password: qwerty

    # Java keystores
    keystores:
      - name: restbase1001-a
        key:
          size: 2048
        cert:
          subject:
            organization: WMF
            country: US
            unit: Services
          valid: 365
        password: qwerty

      - name: restbase1001-b
        key:
          size: 2048
        cert:
          subject:
            organization: WMF
            country: US
            unit: Services
          valid: 365
        password: qwerty

      - name: restbase1002-a
        key:
          size: 2048
        cert:
          subject:
            organization: WMF
            country: US
            unit: Services
          valid: 365
        password: qwerty

Next, run the script with the manifest as its only argument:

    $ cassandra-ca manifest.yaml
    $ tree /path/to/base/directory
    /path/to/base/directory
    ├── restbase1001-a
    │   ├── restbase1001-a.crt
    │   └── restbase1001-a.csr
    │   └── restbase1001-a.kst
    ├── restbase1001-b
    │   ├── restbase1001-b.crt
    │   └── restbase1001-b.csr
    │   └── restbase1001-b.kst
    ├── restbase1002-a
    │   ├── restbase1002-a.crt
    │   └── restbase1002-a.csr
    │   └── restbase1002-a.kst
    ├── rootCa.crt
    ├── rootCa.key
    ├── rootCa.srl
    └── truststore

    3 directories, 13 files


"""

import logging
import os
import os.path
import subprocess

import yaml    # PyYAML (python-yaml)


logging.basicConfig(level=logging.DEBUG)


class Subject(object):
    def __init__(self, common_name, **kwargs):
        self.common_name = common_name
        self.organization = kwargs.get("organization", "WMF")
        self.country = kwargs.get("country", "US")
        self.unit = kwargs.get("unit", "Services")

    def __repr__(self):
        return "%s(cn=%s, o=%s, c=%s, u=%s)" \
            % (self.__class__.__name__, self.common_name,
               self.organization, self.country, self.unit)


class KeytoolSubject(Subject):
    def __str__(self):
        return "cn=%s, ou=%s, o=%s, c=%s" \
            % (self.common_name, self.unit, self.organization, self.country)


class Keystore(object):
    def __init__(self, path, authority, **kwargs):
        name = kwargs.get("name")
        password = kwargs.get("password")

        if name is None:
            raise RuntimeError("corrupt keystore entry; missing keystore name")
        if password is None:
            raise RuntimeError("corrupt keystore entry; missing keystore password")

        key = kwargs.get("key", dict(size=2048))
        size = int(key.get("size", 2048))
        cert = kwargs.get("cert", dict(valid=365))

        self.base = os.path.abspath(path)
        self.name = name
        self.authority = authority
        self.filename = os.path.join(self.base, name, "%s.kst" % self.name)
        self.csr = os.path.join(self.base, name, "%s.csr" % name)
        self.crt = os.path.join(self.base, name, "%s.crt" % name)
        self.password = password
        self.size = size
        self.subject = KeytoolSubject(self.name, **cert["subject"])
        self.valid = int(cert.get("valid", 365))

        mkdirs(os.path.join(self.base, name))

    def generate(self):
        if os.path.exists(self.filename):
            logging.warn("%s already exists, skipping keystore generation...", self.filename)
            return

        # Generate the node key
        #
        # It looks as though a key password is required (if you do not pass the
        # argument, then keytool prompts for the password on STDIN).  Cassandra
        # it seems, depends upon the key and store passwords being identical, (and
        # indeed, keytool itself will attempt to use the -storepass when -keypass
        # is omitted).  So much WTF.
        command = [
            "keytool",
            "-genkeypair",
            "-dname",     str(self.subject),
            "-keyalg",    "RSA",
            "-alias",     self.name,
            "-validity",  str(self.valid),
            "-storepass", self.password,
            "-keypass",   self.password,
            "-keystore",  self.filename
        ]
        if not run_command(command):
            raise RuntimeError("CA key generation failed")

        # Generate a certificate signing request.
        command = [
            "keytool",
            "-certreq",
            "-dname",     str(self.subject),
            "-alias",     self.name,
            "-file",      self.csr,
            "-keypass",   self.password,
            "-storepass", self.password,
            "-keystore",  self.filename
        ]
        if not run_command(command):
            raise RuntimeError("signing request generation failed")

        # Sign (and verify).
        command = [
            "openssl",
            "x509",
            "-req",
            "-CAcreateserial",
            "-in",    self.csr,
            "-CA",    self.authority.certificate.filename,
            "-CAkey", self.authority.key.filename,
            "-days",  str(self.valid),
            "-out",   self.crt
        ]
        if not run_command(command):
            raise RuntimeError("certificate signing failed")

        command = [
            "openssl",
            "verify",
            "-CAfile", self.authority.certificate.filename,
            self.crt
        ]
        if not run_command(command):
            raise RuntimeError("certificate verification failed")

        # Before we can import the signed certificate, the signer must be trusted,
        # either with a trust entry in this keystore, or with one in the system
        # truststore, aka 'cacerts', (provided -trustcacerts is passed).
        command = [
            "keytool",
            "-importcert",
            "-noprompt",
            "-file",      self.authority.certificate.filename,
            "-storepass", self.password,
            "-keystore",  self.filename
        ]
        if not run_command(command):
            raise RuntimeError("import of CA cert failed")

        # Import the CA signed certificate.
        command = [
            "keytool",
            "-importcert",
            "-noprompt",
            "-file",      self.crt,
            "-alias",     self.name,
            "-storepass", self.password,
            "-keystore",  self.filename
        ]
        if not run_command(command):
            raise RuntimeError("import of CA-signed cert failed")

    def __repr__(self):
        return "%s(name=%s, filename=%s, size=%s, subject=%s)" \
            % (self.__class__.__name__, self.name, self.filename, self.size, self.subject)


class OpensslSubject(Subject):
    def __str__(self):
        return "/CN=%s/OU=%s/O=%s/C=%s/" \
            % (self.common_name, self.unit, self.organization, self.country)


class OpensslCertificate(object):
    def __init__(self, name, path, key, password, **kwargs):
        self.name = name
        self.base = os.path.abspath(path)
        self.filename = os.path.join(self.base, "%s.crt" % self.name)
        self.truststore = os.path.join(self.base, "truststore")
        self.key = key
        self.password = password
        self.subject = OpensslSubject(name, **kwargs["subject"])
        self.valid = int(kwargs.get("valid", 365))

    def generate(self):
        if os.path.exists(self.filename):
            logging.warn("%s already exists, skipping certificate generation...", self.filename)
            return

        # Generate the CA certificate
        command = [
            "openssl",
            "req",
            "-x509",
            "-new",
            "-nodes",
            "-subj", str(self.subject),
            "-days", str(self.valid),
            "-key", self.key.filename,
            "-out", self.filename
        ]
        if not run_command(command):
            raise RuntimeError("CA certificate generation failed")

        if os.path.exists(self.truststore):
            logging.warn("%s already exists, skipping truststore generation...", self.filename)
            return

        # Import the CA certificate to a Java truststore
        # FIXME: -storepass should use :file or :env specifier to avoid exposing
        # password to process list
        command = [
            "keytool",
            "-importcert",
            "-v",
            "-noprompt",
            "-trustcacerts",
            "-alias", "rootCa",
            "-file", self.filename,
            "-storepass", self.password,
            "-keystore", self.truststore
        ]
        if not run_command(command):
            raise RuntimeError("CA truststore generation failed")

    def __repr__(self):
        return "%s(name=%s, filename=%s, subject=%s, valid=%d)" \
            % (self.__class__.__name__, self.name, self.filename, self.subject, self.valid)


class OpensslKey(object):
    def __init__(self, name, path, **kwargs):
        self.name = name
        self.base = os.path.abspath(path)
        self.filename = os.path.join(self.base, "%s.key" % self.name)
        self.size = kwargs.get("size", 2048)

        mkdirs(self.base)

    def generate(self):
        if os.path.exists(self.filename):
            logging.warn("%s already exists, skipping key generation...", self.filename)
            return

        if not run_command(["openssl", "genrsa", "-out", self.filename, str(self.size)]):
            raise RuntimeError("CA key generation failed")

    def __repr__(self):
        return "%s(name=%s, filename=%s, size=%s)" \
            % (self.__class__.__name__, self.name, self.filename, self.size)


class Authority(object):
    def __init__(self, base_directory, **kwargs):
        self.password = kwargs.get("password")
        if self.password is None:
            raise RuntimeError("authority is missing mandatory password entry")

        self.base_directory = base_directory
        self.key = OpensslKey("rootCa", self.base_directory, **(kwargs.get("key", dict())))
        self.certificate = OpensslCertificate(
                "rootCa", self.base_directory, self.key, self.password,
                **(kwargs.get("cert", dict())))

    def generate(self):
        self.key.generate()
        self.certificate.generate()

    def __repr__(self):
        return "%s(key=%s, certifcate=%s)" % (self.__class__.__name__, self.key, self.certificate)


def read_manifest(manifest):
    with open(manifest, 'r') as f:
        return yaml.safe_load(f.read())


def run_command(command):
    try:
        output = subprocess.check_output(command, stderr=subprocess.STDOUT)
        for ln in output.splitlines():
            logging.debug(ln)
        logging.debug("command succeeded: %s", " ".join(command))
    except subprocess.CalledProcessError as error:
        for ln in error.output.splitlines():
            logging.error(ln)
        logging.error("command returned status %d: %s", error.returncode, " ".join(command))
        return False
    return True


def mkdirs(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Manage a certificate authority')
    parser.add_argument("manifest", type=str,
                        help="YAML specification of managed keys and certificates")
    parser.add_argument("--base_directory", type=str, default=None,
                        help="Override base_directory from manifest")
    args = parser.parse_args()

    manifest = read_manifest(args.manifest)

    base_directory = args.base_directory or manifest.get("base_directory")
    if base_directory is None:
        parser.error("base_directory not specified")

    authority = Authority(base_directory, **(manifest.get("authority")))

    authority.generate()

    entities = manifest.get("keystores")

    for entity in entities:
        Keystore(base_directory, authority, **entity).generate()
