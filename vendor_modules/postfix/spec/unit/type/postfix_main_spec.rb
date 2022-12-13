require 'spec_helper'

describe Puppet::Type.type(:postfix_main) do
  it 'has :name & :setting as its keyattributes' do
    expect(described_class.key_attributes).to eq([:name, :setting])
  end

  describe 'when validating attributes' do
    [:name, :setting, :target].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:ensure, :value].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'autorequire' do
    let(:catalog) do
      Puppet::Resource::Catalog.new
    end

    it 'autorequires the targeted file' do
      file = Puppet::Type.type(:file).new(name: '/etc/postfix/main.cf')
      catalog.add_resource file
      key = described_class.new(name: 'inet_interfaces', target: '/etc/postfix/main.cf', value: 'localhost', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(1)
    end
    it 'autorequires the service by name' do
      service = Puppet::Type.type(:postfix_master).new(name: 'bounce/unix')
      catalog.add_resource service
      key = described_class.new(name: 'bounce_service_name', value: 'bounce', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(1)
    end
    it 'autorequires the service by setting' do
      service = Puppet::Type.type(:postfix_master).new(name: 'dovecot/unix')
      catalog.add_resource service
      key = described_class.new(name: 'dovecot_destination_recipient_limit', value: '1', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(1)
    end
    it 'autorequires other settings' do
      setting1 = Puppet::Type.type(:postfix_main).new(name: 'foo', value: 'foo')
      catalog.add_resource setting1
      setting2 = Puppet::Type.type(:postfix_main).new(name: 'bar', value: 'bar')
      catalog.add_resource setting2
      setting3 = Puppet::Type.type(:postfix_main).new(name: 'baz', value: 'baz')
      catalog.add_resource setting3
      key = described_class.new(name: 'quux', value: '$foo $(bar) ${baz}', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(3)
    end
    it 'autorequires another setting and file' do
      file = Puppet::Type.type(:file).new(name: '/etc/postfix/mynetworks')
      catalog.add_resource file
      setting = Puppet::Type.type(:postfix_main).new(name: 'config_directory', value: '/etc/postfix')
      catalog.add_resource setting
      key = described_class.new(name: 'mynetworks', value: '$config_directory/mynetworks', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(2)
    end
    it 'autorequires a hash lookup table' do
      file = Puppet::Type.type(:file).new(name: '/etc/postfix/network_table.db')
      catalog.add_resource file
      key = described_class.new(name: 'mynetworks', value: 'hash:/etc/postfix/network_table', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(1)
    end
    it 'autorequires a cdb lookup table' do
      file = Puppet::Type.type(:file).new(name: '/etc/postfix/network_table.cdb')
      catalog.add_resource file
      key = described_class.new(name: 'mynetworks', value: 'cdb:/etc/postfix/network_table', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(1)
    end
    it 'autorequires a dbm lookup table' do
      ['dir', 'pag'].each do |ext|
        file = Puppet::Type.type(:file).new(name: "/etc/postfix/network_table.#{ext}")
        catalog.add_resource file
      end
      key = described_class.new(name: 'mynetworks', value: 'dbm:/etc/postfix/network_table', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(2)
    end
    it 'autorequires a lmdb lookup table' do
      file = Puppet::Type.type(:file).new(name: '/etc/postfix/network_table.lmdb')
      catalog.add_resource file
      key = described_class.new(name: 'mynetworks', value: 'lmdb:/etc/postfix/network_table', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(1)
    end
    it 'autorequires an ldap lookup table' do
      file = Puppet::Type.type(:file).new(name: '/etc/postfix/ldap-aliases.cf')
      catalog.add_resource file
      key = described_class.new(name: 'mynetworks', value: 'hash:/etc/aliases, ldap:/etc/postfix/ldap-aliases.cf', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(1)
    end
    it 'autorequires a proxymap lookup table' do
      file = Puppet::Type.type(:file).new(name: '/etc/postfix/ldap-aliases.cf')
      catalog.add_resource file
      key = described_class.new(name: 'mynetworks', value: 'hash:/etc/aliases, proxy:ldap:/etc/postfix/ldap-aliases.cf', ensure: :present)
      catalog.add_resource key
      expect(key.autorequire.size).to eq(1)
    end
  end
end
