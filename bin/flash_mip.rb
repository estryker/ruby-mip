#!/usr/bin/env ruby

require "../lib/mip.rb"

m = MiP.new('1C:37:8D:FB:20:87','hci0')
m.flash_chest('red',3,6)
