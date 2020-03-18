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

#device.services.each {|s| puts s + "  -- " + device.characteristics(s).join(' ') }

#device.disconnect
module BLE
  module Service
    add '0000ffe0-0000-1000-8000-00805f9b34fb',
        name: 'MiP Receive Data Service',
        nick: :mip_receive_data
    add '0000ffe5-0000-1000-8000-00805f9b34fb',
        name: 'MiP Send Data Service',
        nick: :mip_send_data
  end
  class Characteristic
    add '0000ffe4-0000-1000-8000-00805f9b34fb',
        name: 'MiP Receive Data Notify Characteristic',
        nick: :mip_receive_notify
    add '0000ffe9-0000-1000-8000-00805f9b34fb',
        name: 'MiP Send Data Write Characteristic',
        nick: :mip_send_write
  end
end

#device[:mip_send_data, :mip_send_write]

#send_command(0x89, color_to_bytes(color), on_duration & 0xFF, off_duration & 0xFF)
#
 device.write(:mip_send_data, :mip_send_write,"\x89\xFF\x00\x00\x05\x05", raw: true)
# device.write('0000ffe5-0000-1000-8000-00805f9b34fb','0000ffe9-0000-1000-8000-00805f9b34fb', "\x89\xFF\x00\x00\x05\x05", raw: true)

sleep(2)
device.disconnect
__END__

According to https://github.com/WowWeeLabs/MiP-BLE-Protocol

    Receive Data Service: 0xFFE0
        Receive Data NOTIFY Characteristic: 0xFFE4
    Send Data Service: 0xFFE5
        Send Data WRITE Characteristic: 0xFFE9


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
