#!/usr/bin/env ruby
# Copyright (c) 2016 Giuseppe Lavagetto, Wikimedia Foundation
# Loosely based on https://github.com/ripienaar/mcollective-choria/blob/master/lib/mcollective/util/choria.rb
require 'json'
require 'logger'
require 'net/http'
require 'openssl'
require 'optparse'
require 'yaml'

require 'puppet'
require 'puppet/ssl/certificate_authority'
require 'puppet/util/command_line'

OpenSSL::PKey::EC.send(:alias_method, :private?, :private_key?)

class PuppetECDSAGenError < StandardError
end

args = {
  configfile: nil,
  cert_dir: '/var/lib/puppet/ssl/certs',
  key_dir: '/var/lib/puppet/ssl/private_keys',
  organization: 'Wikimedia Foundation, Inc',
  country: 'US',
  state: 'California',
  locality: 'San Francisco',
  puppetca: 'puppet',
  altnames: [],
  asn1_oid: 'prime256v1'
}


Log = Logger.new(STDOUT)

Log.level = Logger::INFO
Log.formatter = proc do |severity, datetime, progname, msg|
  date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
  progname = "puppet-ecdsacert"
  if severity == "INFO" or severity == "WARN"
    "[#{date_format}] #{severity}  (#{progname}): #{msg}\n"
  else
    "[#{date_format}] #{severity} (#{progname}): #{msg}\n"
  end
end


# Ecdsa certificates generator class
# Generates the cert, the CSR, and sends the signing request to the puppetmaster
class PuppetECDSAGen
  class << self; attr_accessor :confkeys; end
  @confkeys = [:cert_dir, :key_dir, :organization, :country,
               :state, :locality, :puppetca, :asn1_oid]

  def initialize(args)
    @config = {}
    self.class.confkeys.each do |key|
      @config[key] = args[key]
    end

    parse_config args[:configfile] if args[:configfile]

    @common_name = args[:common_name]
    @dns_alt_names = args[:altnames].map { |domain| "DNS:#{domain}" }
    # We need the CN in the SAN if we want to validate against it
    @dns_alt_names << "DNS:#{@common_name}"
    Log.info "Creating and signing ECDSA certificate for #{@common_name}"
    Log.info "DNS subjectAltNames: #{@dns_alt_names}"
    Log.info "Using NIST curve #{@config[:asn1_oid]}"
  end

  def parse_config(filename)
    data = File.read filename
    conffile = YAML.load(data)
    conffile.each do |key, val|
      k = key.to_sym
      @config[k] = val if self.class.confkeys.include? k
    end
  end

  # Generates and writes out the private key
  def generate_ecdsa_key
    ec_domain_key = OpenSSL::PKey::EC.new(@config[:asn1_oid])
    ec_domain_key.generate_key

    private_key_file = File.join @config[:key_dir], "#{@common_name}.key"
    Log.info "Storing the private key in #{private_key_file}"
    File.open(private_key_file, 'w', 0o0640) { |f| f.write(ec_domain_key.to_pem) }
    ec_domain_key
  end

  def csr_path
    File.join '/tmp', "#{@common_name}.csr.pem"
  end

  # Generates and writes out the CSR
  def generate_csr(ec_domain_key)
    ec_public = OpenSSL::PKey::EC.new(@config[:asn1_oid])
    ec_public.public_key = ec_domain_key.public_key
    csr = OpenSSL::X509::Request.new
    csr.version = 0
    csr.subject = subject
    csr.public_key = ec_public
    csr_alt_names csr
    csr.sign ec_domain_key, OpenSSL::Digest::SHA256.new
    Log.info "Generated CSR at #{csr_path}"
    File.open(csr_path, "w", 0o0644) {|f| f.write(csr.to_pem)}
  end

  def subject
    subject = OpenSSL::X509::Name.new [
      ['CN', @common_name],
      ['O', @config[:organization]],
      ['C', @config[:country]],
      ['ST', @config[:state]],
      ['L', @config[:locality]]
    ]
    subject
  end

  def csr_alt_names(csr)
    extensions = [
      OpenSSL::X509::ExtensionFactory.new.create_extension(
        'subjectAltName', @dns_alt_names.join(',')
      )
    ]
    # add SAN extension to the CSR
    attribute_values = OpenSSL::ASN1::Set [OpenSSL::ASN1::Sequence(extensions)]
    [
      OpenSSL::X509::Attribute.new('extReq', attribute_values),
      OpenSSL::X509::Attribute.new('msExtReq', attribute_values)
    ].each do |attribute|
      csr.add_attribute attribute
    end
  end

  def https
    http = Net::HTTP.new(@config[:puppetca], 8140)
    http.use_ssl = true

    # TODO: fix this
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    http
  end

  def sign
    req = Net::HTTP::Put.new("/production/certificate_request/#{@common_name}",
                             'Content-Type' => 'text/plain')
    req.body = File.read csr_path
    Log.info "Submitting CSR for signing to #{@config[:puppetca]}"
    resp, _ = https.request(req)
    fail(PuppetECDSAGenError,
         format('Signing request to %s failed with code %s: %s',
                @config[:puppetca], resp.code, resp.body)
        ) unless resp.code == '200'
    Log.info "CSR request succeeded"
  end

  def cleanup
    Log.debug "Removing file #{csr_path} if present"
    File.delete csr_path if File.exists? csr_path
  end
end

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


OptionParser.new do |opts|
  opts.banner = "Usage: puppetecdsamanager [-c configfile] [-a SAN1,SAN2] common-name "
  opts.on('-c', '--configfile CONF', 'Location of the config file') do |conf|
    args[:configfile] = conf
  end
  opts.on('-a', '--alt-names ALT1,ALT2', 'Subjective alt names') do |altnames|
    args[:altnames] = altnames.split(/,\s*/).map
  end
end.parse!

args[:common_name] = ARGV.shift || ''

fail(PuppetECDSAGenError, 'You must provide a common name') unless args[:common_name] != ''

begin
  manager = PuppetECDSAGen.new args
  ecdsa_key = manager.generate_ecdsa_key
  manager.generate_csr(ecdsa_key)
  manager.sign
rescue PuppetECDSAGenError => e
  Log.error "#{e.message}"
  manager.cleanup
  exit 1
else
  manager.cleanup unless manager.nil?
end

Log.info "Now signing the certificate"
# Now sign the cert using puppet's own commandline interpreter
Puppet::Util::CommandLine.new('cert', ['sign', args[:common_name]]).execute
