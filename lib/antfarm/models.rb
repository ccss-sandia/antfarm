#ActiveRecord::Base.configurations[:test] = {
#  :adapter => 'sqlite3',
#  :database => 'db/test.db'
#}

#ActiveRecord::Base.establish_connection(
#  ActiveRecord::Base.configurations[:test]
#)

#unless File.exists?('db/test.db')
#  load 'antfarm/schema.rb'
#end

require 'antfarm/models/ethernet_interface'
require 'antfarm/models/ip_interface'
require 'antfarm/models/layer2_interface'
require 'antfarm/models/layer3_interface'
require 'antfarm/models/node'
