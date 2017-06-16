require_relative '../../spec_helper'
require_relative '../../../lib/puppet/provider/package/scap3'

provider_class = Puppet::Type.type(:package).provider(:scap3)

describe provider_class do
  before do
    @resource = Puppet::Type.type(:package).new(name: 'foo/deploy')
    @provider = provider_class.new(@resource)
    @resource.provider = @provider
    @resource[:install_options] = [{ 'owner' => 'mwdeploy' }]

    # Stub all filesystem operations
    allow(FileUtils).to receive(:chown_R)
    allow(FileUtils).to receive(:makedirs)
    allow(FileUtils).to receive(:rm_rf)

    # Stub our mwdeploy user
    allow(Etc).to receive(:getpwnam).with('mwdeploy').and_return(OpenStruct.new(uid: 666))

    # Stub the existance of our deploy-local command
    allow(@provider.class).to receive(:command)
      .with(:scap)
      .and_return('/usr/bin/scap')
  end

  describe '#install' do
    it 'should specify the right repo' do
      allow(FileUtils).to receive(:cd)
      expect(@provider).to receive(:execute)
        .with(['/usr/bin/scap', 'deploy-local', '--repo', 'foo/deploy', '-D', 'log_json:False'],
              uid: 666, failonfail: true)
      @provider.install
    end
  end

  describe '#query' do
    subject { @provider.query }

    context 'when the package is installed' do
      before do
        expect(@provider).to receive(:git)
          .with('-C', '/srv/deployment/foo/deploy', 'tag', '--points-at', 'HEAD')
          .and_return(tag)
      end

      context 'and the tag exists' do
        let(:tag) { 'scap/sync/2016-02-06/0001' }

        it 'returns ensure: {tag} where {tag} is the scap tag for HEAD' do
          expect(subject).to eq({ ensure: tag, name: 'foo/deploy' })
        end
      end

      context 'but the tag does not exist' do
        let(:tag) { '' }

        it 'returns ensure: :installed' do
          expect(subject).to eq({ ensure: :installed, name: 'foo/deploy' })
        end
      end
    end

    context 'when the package is not installed' do
      before do
        expect(@provider).to receive(:git) { raise Puppet::ExecutionFailure, 'fail' }
      end

      it 'returns ensure: absent' do
        expect(subject).to eq({ ensure: :absent, name: 'foo/deploy' })
      end
    end
  end

  describe '#uninstall' do
    it 'should delete the entire parent directory' do
      expect(FileUtils).to receive(:rm_rf).with('/srv/deployment/foo')
      @provider.uninstall
    end
  end

  describe '#install_option' do
    subject { @provider.install_option('owner', 'root') }

    it { is_expected.to eq('mwdeploy') }
  end
end
