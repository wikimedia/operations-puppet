require 'net/http'
require 'openssl'
require 'yaml'
require 'optparse'
require 'json'

OpenSSL::PKey::EC.send(:alias_method, :private?, :private_key?)

class PuppetECDSAGenError < StandardError
end

# Ecdsa
class PuppetECDSAGen
  class << self; attr_accessor :confkeys; end
  @confkeys = [:cert_dir, :key_dir, :organization, :country, :state, :locality, :puppetca]

  def initialize(args)
    @config = {}
    self.class.confkeys.each do |key|
      @config[key] = args[key]
    end

    parse_config args[:configfile] if args[:configfile]

    @common_name = args[:common_name]
    @dns_alt_names = args[:altnames]
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
    ec_domain_key = OpenSSL::PKey::EC.new('secp521r1')
    ec_domain_key.generate_key

    private_key_file = File.join @config[:key_dir], "#{@common_name}.key"
    File.open(private_key_file, 'w', 0o0640) { |f| f.write(ec_domain_key.to_pem) }
    ec_domain_key
  end

  def csr_path
    File.join '/tmp', "#{@common_name}.csr.pem"
  end

  # Generates and writes out the CSR
  def generate_csr(ec_domain_key)
    ec_public = OpenSSL::PKey::EC.new('secp521r1')
    ec_public.public_key = ec_domain_key.public_key
    csr = OpenSSL::X509::Request.new
    csr.version = 0
    csr.subject = subject
    csr.public_key = ec_public
    csr_alt_names csr
    csr.sign ec_domain_key, OpenSSL::Digest::SHA256.new
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
    san_list = @dns_alt_names.map { |domain| "DNS:#{domain}" }
    extensions = [
      OpenSSL::X509::ExtensionFactory.new.create_extension(
        'subjectAltName', san_list.join(',')
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
    resp, data = https.request(req)
    fail(PuppetECDSAGenError,
         format('Signing request to %s failed with code %s: %s',
                @config[:puppetca], resp.code, resp.body)
        ) unless resp.code == '200'
    puts resp.message
  end
end

args = {
  configfile: nil,
  cert_dir: '/var/lib/puppet/ssl/certs',
  key_dir: '/var/lib/puppet/ssl/private_keys',
  organization: 'Wikimedia Foundation',
  country: 'US',
  state: 'CA',
  locality: 'San Francisco',
  puppetca: 'puppet',
  altnames: []
}

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

fail(PuppetECDSAGenError, 'You must provide a common name') unless args[:common_name]

begin
  manager = PuppetECDSAGen.new args
  ecdsa_key = manager.generate_ecdsa_key
  manager.generate_csr(ecdsa_key)
  manager.sign
rescue PuppetECDSAGenError => e
  puts "Error: #{e.message}"
  exit 1
end
