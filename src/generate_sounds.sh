#!/bin/bash
# Generate voice pack sounds using macOS say command
# Output: WAV files in sounds/ directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR/../sounds"

echo "🎙️  Generating SlapMac voice packs..."
mkdir -p "$SOUNDS_DIR"/{classic,sexy,angry,goat,robot,wilhelm}

# Classic pack
echo "😱 Classic pack..."
say -v "Samantha" "Ouch!" -o "$SOUNDS_DIR/classic/ouch_1.aiff"
say -v "Samantha" "Ow!" -o "$SOUNDS_DIR/classic/ouch_2.aiff"
say -v "Samantha" "Hey!" -o "$SOUNDS_DIR/classic/hey.aiff"
say -v "Samantha" "Stop it!" -o "$SOUNDS_DIR/classic/stop_it.aiff"
say -v "Samantha" "That hurts!" -o "$SOUNDS_DIR/classic/that_hurts.aiff"
say -v "Samantha" "Why?" -o "$SOUNDS_DIR/classic/why.aiff"

# Sexy pack
echo "💋 Sexy pack..."
say -v "Samantha" "Oh yeah." -o "$SOUNDS_DIR/sexy/oh_yeah_1.aiff"
say -v "Samantha" "Oh yeah!" -o "$SOUNDS_DIR/sexy/oh_yeah_2.aiff"
say -v "Samantha" "Mmm." -o "$SOUNDS_DIR/sexy/mmm.aiff"
say -v "Samantha" "Do it again." -o "$SOUNDS_DIR/sexy/do_it_again.aiff"
say -v "Samantha" "Harder." -o "$SOUNDS_DIR/sexy/harder.aiff"
say -v "Samantha" "Oh baby." -o "$SOUNDS_DIR/sexy/oh_baby.aiff"

# Angry pack
echo "🤬 Angry pack..."
say -v "Fred" "HEY!" -o "$SOUNDS_DIR/angry/hey_loud.aiff"
say -v "Fred" "OUCH!" -o "$SOUNDS_DIR/angry/ouch_loud.aiff"
say -v "Fred" "STOP!" -o "$SOUNDS_DIR/angry/stop_loud.aiff"
say -v "Fred" "What the!" -o "$SOUNDS_DIR/angry/what_the.aiff"
say -v "Fred" "Idiot!" -o "$SOUNDS_DIR/angry/idiot.aiff"
say -v "Fred" "Seriously!" -o "$SOUNDS_DIR/angry/seriously.aiff"

# Goat pack
echo "🐐 Goat pack..."
say -v "Bad News" "Baaaa!" -o "$SOUNDS_DIR/goat/baaa_1.aiff"
say -v "Bad News" "Baaaaa!" -o "$SOUNDS_DIR/goat/baaa_2.aiff"
say -v "Bad News" "Maah!" -o "$SOUNDS_DIR/goat/maah.aiff"
say -v "Bad News" "Bleeeet!" -o "$SOUNDS_DIR/goat/bleeeet.aiff"
say -v "Bad News" "Meeeeh!" -o "$SOUNDS_DIR/goat/goat_scream.aiff"
say -v "Bad News" "Baaaaah!" -o "$SOUNDS_DIR/goat/meeeeh.aiff"

# Robot pack
echo "🤖 Robot pack..."
say -v "Zarvox" "Error four oh four." -o "$SOUNDS_DIR/robot/error_404.aiff"
say -v "Zarvox" "Damage detected." -o "$SOUNDS_DIR/robot/damage_detected.aiff"
say -v "Zarvox" "System hurt." -o "$SOUNDS_DIR/robot/system_hurt.aiff"
say -v "Zarvox" "Malfunction." -o "$SOUNDS_DIR/robot/malfunction.aiff"
say -v "Zarvox" "Ouch." -o "$SOUNDS_DIR/robot/ouch_robot.aiff"
say -v "Zarvox" "Beep boop." -o "$SOUNDS_DIR/robot/beep_boop.aiff"

# Wilhelm pack
echo "😵 Wilhelm pack..."
say -v "Hysterical" "Aaaaaaaah!" -o "$SOUNDS_DIR/wilhelm/wilhelm_1.aiff"
say -v "Hysterical" "Oh nooooo!" -o "$SOUNDS_DIR/wilhelm/wilhelm_2.aiff"
say -v "Hysterical" "Aaaah!" -o "$SOUNDS_DIR/wilhelm/wilhelm_3.aiff"
say -v "Hysterical" "Aaaaaaahhh!" -o "$SOUNDS_DIR/wilhelm/aaaaaaah.aiff"
say -v "Hysterical" "Noooooo!" -o "$SOUNDS_DIR/wilhelm/noooooo.aiff"
say -v "Hysterical" "Aaaaaaaaaaaaaah!" -o "$SOUNDS_DIR/wilhelm/scream_long.aiff"

echo "🔄 Converting AIFF to WAV..."
find "$SOUNDS_DIR" -name "*.aiff" | while read file; do
    wavfile="${file%.aiff}.wav"
    afconvert "$file" "$wavfile" -f WAVE -d LEI16@44100
    rm "$file"
done

echo "✅ Voice packs generated!"
echo "📁 Location: $SOUNDS_DIR"
ls -la "$SOUNDS_DIR"/*/
