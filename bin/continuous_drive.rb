#!/usr/bin/env ruby
# Note: continuous_drive doesn't seem to work at the moment. 
require "../lib/mip.rb"

MiP.start '1C:37:8D:FB:20:87' do
 flash_chest(color: 'blue',on_duration: 5,off_duration: 5)
  set_speed(new_speed: 28)
  # (duration_seconds: 0, spin: 0, left_spin: false,backwards: false, crazy: false)
  continuous_drive(duration_seconds: 5,spin: 10)
  continuous_drive(duration_seconds: 5,spin: 10,left_spin: true)
  continuous_drive(duration_seconds: 5,spin: 0, backwards: true)
  continuous_drive(duration_seconds: 5,spin: 10, crazy: true)
  continuous_drive(duration_seconds: 5,spin: 10, left_spin: true, crazy: true)

  stop
  flash_chest(color: 'red',on_duration: 2,off_duration: 2)
  sleep(5)
end