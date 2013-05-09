require 'spec_helper'

describe 'cron::install' do
  it do
    should contain_package( 'cron' ).with( 'ensure' => 'installed' )
  end
end

