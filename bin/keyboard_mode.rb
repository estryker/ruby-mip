#!/usr/bin/env ruby

require "../lib/mip.rb"

MiP.start '1C:37:8D:FB:20:87' do
    
  on_keyboard_command "square","draw a square of specified size"  do | size_str |
    size = size_str.to_i
    4.times do 
      drive(distance: size)
      turnright(degrees: 90)
      play_sound(sound: "boxing_punch_1")
    end
  end

  on_keyboard_command "spin", "spin to the right the specified number of times " do | times_str |
    times = timesstr.to_i
    spinright num_times: times
  end
  
  keyboard_mode
end