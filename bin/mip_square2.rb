#!/usr/bin/env ruby

require "../lib/mip.rb"

MiP.start '1C:37:8D:FB:20:87' do
  flash_chest(color: 'green',on_duration: 10,off_duration: 5)
  speed(new_speed: 20)
  4.times do
    forward(duration: 100)
    turnright(degrees: 90)
    laser_sound(duration: 5)
  end
  spinright(num_times: 5)
  flash_chest(color: 'red')
  sleep 5
end

