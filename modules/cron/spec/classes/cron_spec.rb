require 'spec_helper'

describe 'cron' do
  it { should include_class( 'cron::install' ) }
end

