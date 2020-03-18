#!/usr/bin/env ruby

require "/home/ethan/ruby-mip/lib/mip.rb"

MiP.start '1C:37:8D:FB:20:87' do
  play_sound(sound: 'guns',duration: 2)
  (0..106).each do | i |
    play_sound(sound: i,duration: 2)
    sleep 1
  end
end
