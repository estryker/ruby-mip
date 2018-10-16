#!/usr/bin/env ruby

require "../lib/mip.rb"

m = MiP.new('1C:37:8D:FB:20:87')
m.flash_chest('red',3,6)
sleep(4)
m.disconnect!
