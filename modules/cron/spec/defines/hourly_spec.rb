require 'spec_helper'

describe 'cron::hourly' do
  let( :title )  { 'mysql_backup' }
  let( :params ) {{
    :minute      => '59',
    :environment => [],
    :user        => 'root',
    :command     => 'mysqldump -u root test_db >some_file'
  }}

  it do
    should contain_cron__job( title ).with(
      'minute'      => params[:minute],
      'hour'        => '*',
      'date'        => '*',
      'month'       => '*',
      'weekday'     => '*',
      'user'        => params[:user],
      'environment' => params[:environment],
      'command'     => params[:command]
    )
  end
end

