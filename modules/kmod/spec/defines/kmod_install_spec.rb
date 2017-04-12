require 'spec_helper'

describe 'kmod::install', :type => :define do
  let(:title) { 'foo' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({
          :augeasversion => '1.2.0',
        })
      end

      let(:params) do { :ensure => 'present', :command => '/bin/true', :file => '/etc/modprobe.d/modprobe.conf' } end
      it { should contain_kmod__install('foo') }
      it { should contain_kmod__setting('kmod::install foo').with({
        'ensure'    => 'present',
        'category'  => 'install',
        'module'    => 'foo',
        'option'    => 'command',
        'value'     => '/bin/true',
        'file'      => '/etc/modprobe.d/modprobe.conf'
      }) }
    end
  end
end
