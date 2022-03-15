require_relative '../../../../rake_modules/spec_helper'

describe 'rsync::server::module', :type => :define do
  let :title do
    'foobar'
  end

  let :pre_condition do
    'class { "rsync::server": }'
  end

  let :fragment_file do
    "/etc/rsync.d/frag-foobar"
  end

  let :mandatory_params do
    { :path => '/some/path' }
  end

  let :params do
    mandatory_params
  end

  describe "when using default class parameters" do
    it { should contain_file(fragment_file).with_content(/^\[ foobar \]$/) }
    it { should contain_file(fragment_file).with_content(%r{^path\s*=\s*/some/path$}) }
    it { should contain_file(fragment_file).with_content(/^read only\s*=\s*yes$/) }
    it { should contain_file(fragment_file).with_content(/^write only\s*=\s*no$/) }
    it { should contain_file(fragment_file).with_content(/^list\s*=\s*yes$/) }
    it { should contain_file(fragment_file).with_content(/^uid\s*=\s*0$/) }
    it { should contain_file(fragment_file).with_content(/^gid\s*=\s*0$/) }
    it { should contain_file(fragment_file).with_content(/^use chroot\s*=\s*yes$/) }
    it { should contain_file(fragment_file).with_content(/^max connections\s*=\s*0$/) }
    it { should_not contain_file(fragment_file).with_content(/^incoming chmod\s*=/) }
    it { should_not contain_file(fragment_file).with_content(/^outgoing chmod\s*=/) }
    it { should_not contain_file(fragment_file).with_content(/^lock file\s*=.*$/) }
    it { should_not contain_file(fragment_file).with_content(/^secrets file\s*=.*$/) }
    it { should_not contain_file(fragment_file).with_content(/^auth users\s*=.*$/) }
    it { should_not contain_file(fragment_file).with_content(/^hosts allow\s*=.*$/) }
    it { should_not contain_file(fragment_file).with_content(/^hosts deny\s*=.*$/) }
  end

  describe "when overriding max connections" do
    let :params do
      mandatory_params.merge({ :max_connections => 1 })
    end
    it { should contain_file(fragment_file).with_content(/^max connections\s*=\s*1$/) }
    it { should contain_file(fragment_file).with_content(%r{^lock file\s*=\s*/var/run/rsyncd\.lock$}) }
  end

  {
    :comment        => 'super module !',
    :read_only      => 'no',
    :write_only     => 'yes',
    :list           => 'no',
    :uid            => '4682',
    :gid            => '4682',
    :incoming_chmod => '0777',
    :outgoing_chmod => '0777',
    :secrets_file   => '/path/to/secrets',
    :hosts_allow    => ['localhost', '169.254.42.51'].join(' '),
    :hosts_deny     => ['some-host.example.com', '10.0.0.128'].join(' '),
  }.each do |k, v|
    describe "when overriding #{k}" do
      let :params do
        mandatory_params.merge({ k => v })
      end
      it { should contain_file(fragment_file).with_content(/^#{k.to_s.gsub('_', ' ')}\s*=\s*#{v}$/)}
    end
  end

  describe "when overriding auth_users" do
    let :params do
      mandatory_params.merge({ :auth_users => ['me', 'you', 'them'] })
    end
    it { should contain_file(fragment_file).with_content(/^auth users\s*=\s*me, you, them$/)}
  end
  describe "when overriding chroot" do
    let :params do
      mandatory_params.merge(chroot: false)
    end
    it { should contain_file(fragment_file).with_content(/^use chroot\s*=\s*no$/)}
  end
end
