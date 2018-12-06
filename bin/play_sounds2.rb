#!/usr/bin/env ruby

require "/home/ethan/ruby-mip/lib/mip.rb"

MiP.start '1C:37:8D:FB:20:87' do
  (1..106).each do | i |
    play_sound(sound_number: i,duration: 2)
    sleep 1
  end
end
