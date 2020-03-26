#!/usr/bin/env ruby

require "../lib/mip.rb"

MiP.start '1C:37:8D:FB:20:87' do
  debug = true
  @logger.debug "flash chest"
  flash_chest(color: 'green',on_duration: 10,off_duration: 5)

  set_speed(new_speed: 20)
  4.times do
    drive(duration: 100)
    turnright(degrees: 90)
    play_sound(sound: "boxing_punch_1")
  end
  spinright(num_times: 5)
  flash_chest(color: 'red')
  sleep 5
end

