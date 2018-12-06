#!/usr/bin/env ruby

require "../lib/mip.rb"

MiP.start '1C:37:8D:FB:20:87' do
  flash_chest(color: 'green',on_duration: 10,off_duration: 5)
  set_speed(new_speed: 25)
  4.times do
    forward(duration: 200)
    turnright(degrees: 90)
    play_sound(sound: "guns", duration: 5)
  end
  spinright(num_times: 5)
  flash_chest(color: 'red')
  fall_forward
  sleep 2
  getup
end

