# encoding: UTF-8

require 'spec_helper'

describe Puppet::Type.type(:user) do
  let(:provider_class) do
    described_class.provide(:simple) do
      has_features :manages_expiry, :manages_password_age, :manages_passwords, :manages_solaris_rbac, :manages_shell
      mk_resource_methods

      def create; end

      def delete; end

      def exists?
        get(:ensure) != :absent
      end

      def flush; end

      def self.instances
        []
      end
    end
  end

  before :each do
    allow(described_class).to receive(:defaultprovider).and_return provider_class
  end

  describe 'when purging ssh keys' do
    it 'does not accept a keyfile with a relative path' do
      expect {
        described_class.new(name: 'a', purge_ssh_keys: 'keys')
      }.to raise_error(Puppet::Error, %r{Paths to keyfiles must be absolute, not keys})
    end

    context 'with a home directory specified' do
      it 'accepts true' do
        described_class.new(name: 'a', home: '/tmp', purge_ssh_keys: true)
      end

      it 'accepts the ~ wildcard' do
        described_class.new(name: 'a', home: '/tmp', purge_ssh_keys: '~/keys')
      end

      it 'accepts the %h wildcard' do
        described_class.new(name: 'a', home: '/tmp', purge_ssh_keys: '%h/keys')
      end

      it 'raises when given a relative path' do
        expect {
          described_class.new(name: 'a', home: '/tmp', purge_ssh_keys: 'keys')
        }.to raise_error(Puppet::Error, %r{Paths to keyfiles must be absolute})
      end
    end

    if Puppet.version.start_with?('6')
      context 'with no home directory specified' do
        before(:each) do
          allow(Dir).to receive(:home).with('a').and_return('/home/a')
        end

        it 'does accept true' do
          described_class.new(name: 'a', purge_ssh_keys: true)
        end

        it 'does accept the ~ wildcard' do
          described_class.new(name: 'a', purge_ssh_keys: '~/keys')
        end

        it 'does accept the %h wildcard' do
          described_class.new(name: 'a', purge_ssh_keys: '%h/keys')
        end
      end
    end

    context 'with a valid parameter' do
      subject do
        res = described_class.new(name: 'test', purge_ssh_keys: paths)
        res.catalog = Puppet::Resource::Catalog.new
        res
      end

      before(:each) do
        allow(Dir).to receive(:home).with('test').and_return('/home/test')
      end

      let(:paths) do
        ['/dev/null', '/tmp/keyfile'].map { |path| File.expand_path(path) }
      end

      it 'does not just return from generate' do
        expect(subject).to receive(:find_unmanaged_keys)
        subject.generate
      end

      it 'checks each keyfile for readability' do
        paths.each do |path|
          expect(File).to receive(:readable?).with(path)
        end
        subject.generate
      end
    end

    describe 'generated keys' do
      subject do
        res = described_class.new(name: 'test_user_name', purge_ssh_keys: purge_param)
        res.catalog = Puppet::Resource::Catalog.new
        res
      end

      before(:each) do
        allow(Dir).to receive(:home).with('test_user_name').and_return('/home/test_user_name')
      end

      context 'when purging is disabled' do
        let(:purge_param) { false }

        it 'has an empty generate' do
          expect(subject.generate).to be_empty
        end
      end

      context 'when purging is enabled' do
        let(:purge_param) { File.expand_path(my_fixture('authorized_keys')) }
        let(:resources) { subject.generate }

        it 'contains a resource for each key' do
          names = resources.map { |res| res.name }
          expect(names).to include('key1 name')
          expect(names).to include('keyname2')
        end

        it 'does not include keys in comment lines' do
          names = resources.map { |res| res.name }
          expect(names).not_to include('keyname3')
        end

        it 'generates names for unnamed keys' do
          names = resources.map { |res| res.name }
          fixture_path = File.expand_path(File.join(my_fixture_dir, 'authorized_keys'))
          expect(names).to include("#{fixture_path}:unnamed-1")
        end

        it 'has a value for the user property on each resource' do
          resource_users = resources.map { |res| res[:user] }.reject { |user_name| user_name == 'test_user_name' }
          expect(resource_users).to be_empty
        end
      end
    end
  end
end
