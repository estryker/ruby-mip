#!/usr/bin/env ruby

require "../lib/mip.rb"

MiP.start '1C:37:8D:FB:20:87' do
    on_gesture(direction: 'left') do 
        play_sound(sound: 'uh_oh')
    end
    on_gesture(direction: 'right') do 
        play_sound(sound: 'oh_yeah')
    end
    on_gesture(direction: 'forward') do 
        play_sound(sound: 'burping')
        set_speed(new_speed: 20)
        forward(duration: 100)
    end
    on_gesture(direction: 'back') do 
        play_sound(sound: 'farting')
        set_speed(new_speed: 20)
        backward(duration: 100)
    end
    on_status_check do | message |
        puts "status check: " + message.inspect
    end
    gesture_mode_on!
    flash_chest(color: 'green',on_duration: 10,off_duration: 5)
    sleep(10)
    get_status
    sleep(20)
    flash_chest(color: 'red',on_duration: 5,off_duration: 5)
    sleep(2)
end