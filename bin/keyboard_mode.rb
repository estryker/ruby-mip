#!/usr/bin/env ruby

require "../lib/mip.rb"

MiP.start '1C:37:8D:FB:20:87' do
  debug = true  
  on_keyboard_command "square","draw a square of specified size"  do | size_str |
    size = size_str.to_i
    4.times do 
      @logger.debug "driving"
      drive(distance: size)
      @logger.debug "turning"
      turnright(degrees: 90)
      @logger.debug "playing sound"
      play_sound(sound: "boxing_punch_1")
    end
  end

  on_keyboard_command "flash", "flash chest for specified time in seconds " do
    flash_chest(color: 'red',on_duration: 5,off_duration: 5)
  end
  
  on_keyboard_command "flashoff", "stop flashing chest" do 
    set_chest_led(color: 'green')
  end

  on_keyboard_command "spin", "spin to the right the specified number of times " do | times_str |
    times = times_str.to_i
    spinright(num_times: times)
  end
  puts "Ready!"
  keyboard_mode
end