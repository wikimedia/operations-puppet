require 'spec_helper'

describe 'kmod::setting', :type => :define do
  let(:title) { 'foo' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({
          :augeasversion => '1.2.0',
        })
      end

      let(:default_params) do { :file => 'modprobe.conf'  } end
      let(:params) do default_params end

      context 'add an alias' do
        let(:params) do default_params.merge({ :category => 'alias', :option => 'modulename', :value => 'tango' }) end
        it { should contain_kmod__setting('foo')}
        it { should contain_augeas('kmod::setting foo foo').with({
          'incl'    => 'modprobe.conf',
          'lens'    => 'Modprobe.lns',
          'changes' => [ "set alias[. = 'foo'] foo", "set alias[. = 'foo']/modulename tango" ],
          'require' => 'File[modprobe.conf]'
        })}
      end
      context 'add a blacklist' do
        let(:params) do { :file => '/etc/modprobe.d/blacklist.conf', :category => 'blacklist'  } end
        it { should contain_kmod__setting('foo')}
        it { should contain_augeas('kmod::setting foo foo').with({
          'incl'    => '/etc/modprobe.d/blacklist.conf',
          'lens'    => 'Modprobe.lns',
          'changes' => [ "set blacklist[. = 'foo'] foo" ],
          'require' => 'File[/etc/modprobe.d/blacklist.conf]'
        })}
      end

    end
  end
end
