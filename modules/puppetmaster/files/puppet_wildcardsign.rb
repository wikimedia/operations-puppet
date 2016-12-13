#!/usr/bin/env ruby
# Copyright (c) 2016 Giuseppe Lavagetto, Wikimedia Foundation
# Shameful hack to allow signing certs with wildcard SANs when we want it
# Useful for issuing internal certificates for exposing services.
require 'puppet'
require 'puppet/ssl/certificate_authority'
require 'puppet/util/command_line'
module Puppet
  module SSL
    # Extend the signing checks
    module CertificateAuthorityExtensions
      def check_internal_signing_policies(hostname, csr, _allow_dns_alt_names)
        super(hostname, csr, true)
      rescue Puppet::SSL::CertificateAuthority::CertificateSigningError => e
        if e.message.start_with?("CSR '#{csr.name}' subjectAltName contains a wildcard")
          true
        else
          raise
        end
      end
    end
    # Extend the base class
    class CertificateAuthority
      prepend Puppet::SSL::CertificateAuthorityExtensions
    end
  end
end

name = ARGV.shift || fail('The name of the certificate to sign must be provided.')
Puppet::Util::CommandLine.new('cert', ['sign', name]).execute
