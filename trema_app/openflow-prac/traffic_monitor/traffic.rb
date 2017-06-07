#!/usr/bin/ruby

require "active_record"
require "gli"
include GLI::App

ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3",
  "database" =>"./traffic.db"
)

class Mac_traffic < ActiveRecord::Base
  self.table_name = 'mac_traffics'
end
class Switch_traffic < ActiveRecord::Base
  self.table_name = 'switch_traffics'
end


program_desc "Traffic Monitor - get traffic amount"
version 1.0
subcommand_option_handling :normal

module Traffic
  
  command :get_most_host do |c|
    c.desc 'most send data host'
    c.action do |_global_options, _options, _args|
      result = Mac_traffic.select.maximum('byte')
      puts result.mac
    end
  end
  
end
exit run(ARGV)
  
