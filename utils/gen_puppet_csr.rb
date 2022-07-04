#!/usr/bin/env ruby
# SPDX-License-Identifier: Apache-2.0
# This script can be used to generate a a new CSR for the puppet master.
# It should be run from one of the puppet frontend masters
require 'openssl'

cert = '/var/lib/puppet/server/ssl/ca/ca_crt.pem'
key = '/var/lib/puppet/server/ssl/ca/ca_key.pem'

root_cert = OpenSSL::X509::Certificate.new(File.read(cert))
ca_key = OpenSSL::PKey::RSA.new(File.read(key))
csr = OpenSSL::X509::Request.new

csr.version = 0
csr.subject = root_cert.subject
csr.public_key = root_cert.public_key

ef = OpenSSL::X509::ExtensionFactory.new

extensions = [ef.create_extension("keyUsage", "cRLSign, keyCertSign", true),
              ef.create_extension("basicConstraints", "CA:TRUE", true)]

subject_key_identifier = root_cert.extensions.select {|ext| ext.oid == 'subjectKeyIdentifier' }

if subject_key_identifier.any?
  extensions << ef.create_extension("subjectKeyIdentifier", subject_key_identifier[0].value)
end

ext_req = OpenSSL::X509::Attribute.new("extReq",
                                       OpenSSL::ASN1::Set([OpenSSL::ASN1::Sequence(extensions)]))

csr.add_attribute(ext_req)
csr.sign(ca_key, OpenSSL::Digest::SHA256.new)

File.open("req.pem", "w") do |f|
  f.write(csr.to_s)
end
puts csr.to_s
