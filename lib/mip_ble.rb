#!/usr/bin/env ruby
require 'ble'

# Selecter adapter
adapter = BLE::Adapter.new('hci0')
puts "Info: #{adapter.iface} #{adapter.address} #{adapter.name}"

# Run discovery
adapter.start_discovery
sleep(4)
adapter.stop_discovery

# Get device and connect to it
device = adapter['1C:37:8D:FB:20:87']
device.connect

device.services.each {|s| puts s + "  -- " + device.characteristics(s).join(' ') }

device.disconnect

__END__


00001801-0000-1000-8000-00805f9b34fb  -- 
0000180a-0000-1000-8000-00805f9b34fb  -- 00002a23-0000-1000-8000-00805f9b34fb 00002a26-0000-1000-8000-00805f9b34fb 00002a29-0000-1000-8000-00805f9b34fb
0000ffe0-0000-1000-8000-00805f9b34fb  -- 0000ffe4-0000-1000-8000-00805f9b34fb
0000ffe5-0000-1000-8000-00805f9b34fb  -- 0000ffe9-0000-1000-8000-00805f9b34fb
0000ffa0-0000-1000-8000-00805f9b34fb  -- 0000ffa1-0000-1000-8000-00805f9b34fb 0000ffa2-0000-1000-8000-00805f9b34fb
0000ff90-0000-1000-8000-00805f9b34fb  -- 0000ff91-0000-1000-8000-00805f9b34fb 0000ff92-0000-1000-8000-00805f9b34fb 0000ff94-0000-1000-8000-00805f9b34fb 0000ff95-0000-1000-8000-00805f9b34fb 0000ff97-0000-1000-8000-00805f9b34fb 0000ff98-0000-1000-8000-00805f9b34fb
0000ff00-0000-1000-8000-00805f9b34fb  -- 0000ff01-0000-1000-8000-00805f9b34fb 0000ff02-0000-1000-8000-00805f9b34fb 0000ff03-0000-1000-8000-00805f9b34fb 0000ff04-0000-1000-8000-00805f9b34fb 0000ff05-0000-1000-8000-00805f9b34fb 0000ff06-0000-1000-8000-00805f9b34fb 0000ff07-0000-1000-8000-00805f9b34fb 0000ff08-0000-1000-8000-00805f9b34fb 0000ff09-0000-1000-8000-00805f9b34fb 0000ff0a-0000-1000-8000-00805f9b34fb
0000ff30-0000-1000-8000-00805f9b34fb  -- 0000ff31-0000-1000-8000-00805f9b34fb


# Get temperature from the environmental sensing service
device[:environmental_sensing, :temperature]

# Dump device information
srv = :device_information
device.characteristics(srv).each do |uuid|
    info  = BLE::Characteristic[uuid]
    name  = info.nil? ? uuid : info[:name]
    value = device[srv, uuid] rescue '/!\\ not-readable /!\\'
    puts "%-30s: %s" % [ name, value ]
end
