#!/usr/bin/env ruby

require "../lib/mip.rb"

m = MiP.new(mac_address: '1C:37:8D:FB:20:87', interface: 'hci0')
m.flash_chest(color: 'red',on_duration: 3,off_duration: 6)
sleep(4)
m.disconnect!
