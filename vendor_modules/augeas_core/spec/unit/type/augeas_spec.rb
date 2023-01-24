require 'spec_helper'

augeas = Puppet::Type.type(:augeas)

describe augeas do
  describe 'when augeas is present', if: Puppet.features.augeas? do
    it 'has a default provider inheriting from Puppet::Provider' do
      expect(augeas.defaultprovider.ancestors).to be_include(Puppet::Provider)
    end

    it 'has a valid provider' do
      expect(augeas.new(name: 'foo').provider.class.ancestors).to be_include(Puppet::Provider)
    end
  end

  describe 'basic structure' do
    it 'is able to create an instance' do
      provider_class = Puppet::Type::Augeas.provider(Puppet::Type::Augeas.providers[0])
      expect(Puppet::Type::Augeas).to receive(:defaultprovider).and_return provider_class
      expect(augeas.new(name: 'bar')).not_to be_nil
    end

    it 'has a parse_commands feature' do
      expect(augeas.provider_feature(:parse_commands)).not_to be_nil
    end

    it 'has a need_to_run? feature' do
      expect(augeas.provider_feature(:need_to_run?)).not_to be_nil
    end

    it 'has an execute_changes feature' do
      expect(augeas.provider_feature(:execute_changes)).not_to be_nil
    end

    properties = [:returns]
    params = [:name, :context, :onlyif, :changes, :root, :load_path, :type_check, :show_diff]

    properties.each do |property|
      it "has a #{property} property" do
        expect(augeas.attrclass(property).ancestors).to be_include(Puppet::Property)
      end

      it "has documentation for its #{property} property" do
        expect(augeas.attrclass(property).doc).to be_instance_of(String)
      end
    end

    params.each do |param|
      it "has a #{param} parameter" do
        expect(augeas.attrclass(param).ancestors).to be_include(Puppet::Parameter)
      end

      it "has documentation for its #{param} parameter" do
        expect(augeas.attrclass(param).doc).to be_instance_of(String)
      end
    end
  end

  describe 'default values' do
    before(:each) do
      provider_class = augeas.provider(augeas.providers[0])
      allow(augeas).to receive(:defaultprovider).and_return provider_class
    end

    it 'is blank for context' do
      expect(augeas.new(name: :context)[:context]).to eq('')
    end

    it 'is blank for onlyif' do
      expect(augeas.new(name: :onlyif)[:onlyif]).to eq('')
    end

    it 'is blank for load_path' do
      expect(augeas.new(name: :load_path)[:load_path]).to eq('')
    end

    it 'is / for root' do
      expect(augeas.new(name: :root)[:root]).to eq('/')
    end

    it 'is false for type_check' do
      expect(augeas.new(name: :type_check)[:type_check]).to eq(:false)
    end
  end

  describe 'provider interaction' do
    it 'returns 0 if it does not need to run' do
      provider = instance_double('Puppet::Provider::Augeas', need_to_run?: false)
      resource = instance_double('Puppet::Type::Augeas', provider: provider, line: nil, file: nil)
      changes = augeas.attrclass(:returns).new(resource: resource)
      expect(changes.retrieve).to eq(0)
    end

    it 'returns :need_to_run if it needs to run' do
      provider = instance_double('Puppet::Provider::Augeas', need_to_run?: true)
      resource = instance_double('Puppet::Type::Augeas', provider: provider, line: nil, file: nil)
      changes = augeas.attrclass(:returns).new(resource: resource)
      expect(changes.retrieve).to eq(:need_to_run)
    end
  end

  describe 'loading specific files' do
    it 'requires lens when incl is used' do
      expect { augeas.new(name: :no_lens, incl: '/etc/hosts') }.to raise_error(Puppet::Error)
    end

    it 'requires incl when lens is used' do
      expect { augeas.new(name: :no_incl, lens: 'Hosts.lns') }.to raise_error(Puppet::Error)
    end

    it 'sets the context when a specific file is used' do
      fake_provider = class_double('Puppet::Provider::Augeas')
      allow(augeas).to receive(:defaultprovider).and_return fake_provider
      expect(augeas.new(name: :no_incl, lens: 'Hosts.lns', incl: '/etc/hosts')[:context]).to eq('/files/etc/hosts')
    end
  end
end
