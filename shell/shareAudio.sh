#!bin/sh
# Record program sound and microphone together
# Made by Matthias Quintern
# 2021
# This software comes with no warranty

# README!
# Set these variables for your system:
# run "pactl list sources short" and
# "pactl list sinks short" to get the correct device names
MICROPHONE="alsa_input.pci-0000_2d_00.4.analog-stereo" 
SPEAKERS="alsa_output.pci-0000_2d_00.4.analog-stereo"
# If the Monitors of Virtual Output and Virtual Input to not play sound, it be because of a broken config.
# Try removing all files in ~/.config/pulse (dont delete them, move them somewhere else!)
# Then run "pulseaudio -k" and try again.


# if called from commandline with argument
action=$1

# dmenu optionen
declare -A options
options+=(
    [share]="Share Audio"
    [stop]="Stop share audio"
)
# if no arg is given, run dmenu
if [ -s $action ];
then
    action=$(printf "%s\n" "${!options[@]}" | dmenu -p "Bitte wählen:")
fi


share_audio()
{
    # virtual output for program sound
    pactl load-module module-null-sink sink_name=VirtualOut
    pacmd update-sink-proplist VirtualOut device.description="Virtual_Output"
    pacmd update-source-proplist VirtualOut.monitor device.description="Virtual_Output_Monitor"

    # virtual input, combining virtual out and microphone
    pactl load-module module-null-sink sink_name=VirtualIn
    pacmd update-sink-proplist VirtualIn device.description="Virtual_Input"
    pacmd update-source-proplist VirtualIn.monitor device.description="Virtual_Input_Monitor"

    # virtual microphone, using virtual input (optional)
    # pactl load-module module-remap-source source_name=VirtualMic master="VirtualIn.monitor"
    # pacmd update-source-proplist VirtualMic device.description="Virtual-Microphone"

    # virtual out to in
    pactl load-module module-loopback source=VirtualOut.monitor sink=VirtualIn
    # virtual out to speakers
    pactl load-module module-loopback source=VirtualOut.monitor sink=$SPEAKERS
    # microphone to virtual in
    pactl load-module module-loopback source=$MICROPHONE sink=VirtualIn

    echo "Audio sharing set up. In pavucontrol, you need to:"
    echo "1) [Tab Playback]:  Send sound from your programs to 'Virtual Output'"
    echo "2) [Tab Recording]: Select 'Virtual Input Monitor' as source for the recording program (discord, audacity...)"
    echo "                    If you are using audacity, you need to start a recording to be able to change the source in pavucontrol"
    echo "3) [Both tabs]:     To change the volume of your programs in the recording, change the volume of 'Loopback to Virtual_Input from Virtual_Output_Monitor' and vice versa."
    echo ""
    echo \
"Program sound -> Virtual Out \ -----------------> Speakers/Headphones
 Microphone    ----------------\-> Virtual In \ -> Discord/Audacity
                                               \-> Virtual Microphone -> Discord/Audacity
"
    pavucontrol &
}


stop_share()
{
    echo "Unloading pulseaudio modules null-sink, loopback and remap-source."
    # pactl unload-module module-remap-source
    pactl unload-module module-loopback
    pactl unload-module module-null-sink
    echo "Done."
}


case $action in
    "share")
        share_audio;;
    "stop")
        stop_share;;
    *)
        echo "Invalid argument. Allowed are 'share' and 'stop'";;
esac

