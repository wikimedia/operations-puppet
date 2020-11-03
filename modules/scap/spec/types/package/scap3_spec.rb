require_relative '../../../../../rake_modules/spec_helper'
require_relative '../../../lib/puppet/provider/package/scap3'

provider_class = Puppet::Type.type(:package).provider(:scap3)

describe provider_class do
  before do
    @resource = Puppet::Type.type(:package).new(name: 'foo/deploy')
    @provider = provider_class.new(@resource)
    @resource.provider = @provider
    @resource[:install_options] = [{ 'owner' => 'mwdeploy' }]

    # Stub all filesystem operations
    FileUtils.stubs(:chown_R)
    FileUtils.stubs(:makedirs)
    FileUtils.stubs(:rm_rf)

    # Stub our mwdeploy user
    Etc.stubs(:getpwnam).with('mwdeploy').returns(OpenStruct.new(uid: 666))

    # Stub the existance of our deploy-local command
    @provider.class.stubs(:command).with(:scap).returns('/usr/bin/scap')
  end

  describe '#install' do
    it 'should specify the right repo' do
      FileUtils.stubs(:cd)
      @provider.expects(:execute).with(
        ['/usr/bin/scap', 'deploy-local', '--repo', 'foo/deploy', '-D', 'log_json:False'],
        uid: 666, failonfail: true
      )
      @provider.install
    end
  end

  describe '#query' do
    subject { @provider.query }

    context 'when the package is installed' do
      before do
        @provider.expects(:git).with(
          '-C', '/srv/deployment/foo/deploy', 'tag', '--points-at', 'HEAD'
        ).returns(tag)
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
        @provider.stubs(:git).raises(Puppet::ExecutionFailure, 'fail')
      end

      it 'returns ensure: absent' do
        expect(subject).to eq({ ensure: :absent, name: 'foo/deploy' })
      end
    end
  end

  describe '#uninstall' do
    it 'should delete the entire parent directory' do
      FileUtils.expects(:rm_rf).with('/srv/deployment/foo')
      @provider.uninstall
    end
  end

  describe '#install_option' do
    subject { @provider.install_option('owner', 'root') }

    it { is_expected.to eq('mwdeploy') }
  end
end
