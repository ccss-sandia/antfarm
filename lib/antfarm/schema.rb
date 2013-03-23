ActiveRecord::Schema.define(:version => 7) do
  create_table 'nodes', :force => true do |t|
    t.float  'certainty_factor', :null => false
    t.string 'name'
    t.string 'device_type'
    t.string 'custom'
  end

  create_table 'layer2_interfaces', :force => true do |t|
    t.integer 'node_id',          :null => false
    t.float   'certainty_factor', :null => false
    t.string  'media_type'
    t.string  'custom'
  end

  create_table 'ethernet_interfaces', :force => true do |t|
    t.integer 'layer2_interface_id', :null => false
    t.string  'address',             :null => false
    t.string  'custom'
  end

  create_table 'layer3_interfaces', :force => true do |t|
    t.integer 'layer2_interface_id', :null => false
    t.integer 'layer3_network_id'
    t.float   'certainty_factor',    :null => false
    t.string  'protocol'
    t.string  'custom'
  end

  create_table 'ip_interfaces', :force => true do |t|
    t.integer 'layer3_interface_id',        :null => false
    t.string  'address',                    :null => false
    t.boolean 'virtual', :default => false, :null => false
    t.string  'custom'
  end

  create_table 'layer3_networks', :force => true do |t|
    t.float  'certainty_factor', :null => false
    t.string 'protocol'
    t.string 'custom'
  end

  create_table 'ip_networks', :force => true do |t|
    t.integer 'layer3_network_id',                    :null => false
    t.integer 'private_network_id'
    t.string  'address',                              :null => false
    t.boolean 'private',           :default => false, :null => false
    t.string  'custom'
  end

  create_table 'private_networks', :force => true do |t|
    t.string 'description'
    t.string 'custom'
  end

  create_table 'actions', :force => true do |t|
    t.string 'tool'
    t.string 'description'
    t.string 'start'
    t.string 'end'
    t.string 'custom'
  end

  create_table 'operating_systems', :force => true do |t|
    t.integer 'action_id'
    t.integer 'node_id',          :null => false
    t.float   'certainty_factor', :null => false
    t.text    'fingerprint'
    t.string  'custom'
  end

  create_table 'services', :force => true do |t|
    t.integer 'action_id'
    t.integer 'node_id',          :null => false
    t.float   'certainty_factor', :null => false
    t.string  'protocol'
    t.integer 'port'
    t.text    'name'
    t.string  'custom'
  end

  create_table 'connections', :force => true do |t|
    t.integer 'source_layer3_interface_id', :null => false
    t.integer 'target_layer3_interface_id', :null => false
    t.string  'description'
    t.integer 'port'
    t.string  'timestamp'
    t.string  'custom'
  end

  create_table 'tags', :force => true do |t|
    t.string  'name',          :null => false
    t.integer 'taggable_id',   :null => false
    t.string  'taggable_type', :null => false
  end
end
