require 'spec_helper'

describe 'kmod::alias', :type => :define do
  let(:title) { 'foo' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge( {:augeasversion => '1.2.0'} )
      end

      let(:default_params) do { :source =>'bar', :file => '/baz' } end

      context 'when a file is specified' do
        let(:params) do default_params end
        it { should contain_kmod__alias('foo') }
        it { should contain_kmod__setting('kmod::alias foo') .with({
          'ensure'    => 'present',
          'module'    => 'foo',
          'file'      => '/baz',
          'category'  => 'alias',
          'option'    => 'modulename',
          'value'     => 'bar'
        }) }
      end

      context 'when a file is specified and an aliasname' do
        let(:params) do default_params.merge!({ :aliasname => 'tango' }) end
        it { should contain_kmod__alias('foo') }
        it { should contain_kmod__setting('kmod::alias foo') .with({
          'ensure'    => 'present',
          'module'    => 'tango',
          'file'      => '/baz',
          'category'  => 'alias',
          'option'    => 'modulename',
          'value'     => 'bar'
        }) }
      end

    end
  end
end
