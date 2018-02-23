#!/usr/bin/env ruby

require "../lib/mip.rb"

m = Mip.new('hci0','1C:37:8D:FB:20:87')
m.flash_chest
