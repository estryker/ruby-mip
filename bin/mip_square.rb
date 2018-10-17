#!/usr/bin/env ruby

require "../lib/mip.rb"

MiP.start '1C:37:8D:FB:20:87' do
  flash_chest 'green',10,5
  4.times do
    forward 100
    turnright 90
    laser_sound 5
  end
  flash_chest 'red'
  sleep 5
  spin 10
  fall_back
end
