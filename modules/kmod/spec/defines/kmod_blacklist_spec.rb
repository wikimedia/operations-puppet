require 'spec_helper'

describe 'kmod::blacklist', :type => :define do
  let(:title) { 'foo' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({
          :augeasversion => '1.2.0',
        })
      end

      context 'when ensure is set to present' do
        let(:params) do { :ensure => 'present', :file => '/bar/baz' } end
        it { should contain_kmod__blacklist('foo') }
        it { should contain_kmod__setting('kmod::blacklist foo').with({
          'ensure'     => 'present',
          'category'   => 'blacklist',
          'module'     => 'foo',
          'file'       => '/bar/baz'
        }) }
      end


      context 'when file is not specified' do
        let(:params) do { :ensure => 'present' } end
        it { should contain_kmod__blacklist('foo') }
        it { should contain_kmod__setting('kmod::blacklist foo').with({
          'ensure'     => 'present',
          'category'   => 'blacklist',
          'module'     => 'foo',
          'file'       => '/etc/modprobe.d/blacklist.conf'
        }) }
      end

      context 'when ensure is set to absent' do
        let(:params) do { :ensure => 'absent', :file => '/bar/baz' } end
        it { should contain_kmod__blacklist('foo') }
        it { should contain_kmod__setting('kmod::blacklist foo').with({
          'ensure'     => 'absent',
          'category'   => 'blacklist',
          'module'     => 'foo',
          'file'       => '/bar/baz'
        }) }
      end
    end
  end
end
