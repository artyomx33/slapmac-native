#!/bin/bash
# Generate voice pack sounds using macOS say command
# Output: WAV files in sounds/ directory
# NOTE: Uses voices available on GitHub Actions runners

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR/../sounds"

echo "🎙️  Generating SlapMac voice packs..."
mkdir -p "$SOUNDS_DIR"/{classic,sexy,angry,goat,robot,wilhelm}

# Check if say command exists
if ! command -v say &> /dev/null; then
    echo "❌ 'say' command not found. Are you on macOS?"
    exit 1
fi

# Function to generate sound with fallback
generate_sound() {
    local text="$1"
    local output="$2"
    local voice="$3"
    local fallback_voice="$4"
    
    if say -v "$voice" "$text" -o "$output" 2>/dev/null; then
        echo "  ✅ $voice: $text"
    elif [ -n "$fallback_voice" ]; then
        echo "  ⚠️  $voice not found, using $fallback_voice: $text"
        say -v "$fallback_voice" "$text" -o "$output"
    else
        echo "  ⚠️  Using default voice: $text"
        say "$text" -o "$output"
    fi
}

# Classic pack
echo "😱 Classic pack..."
generate_sound "Ouch!" "$SOUNDS_DIR/classic/ouch_1.aiff" "Samantha" "Alex"
generate_sound "Ow!" "$SOUNDS_DIR/classic/ouch_2.aiff" "Samantha" "Alex"
generate_sound "Hey!" "$SOUNDS_DIR/classic/hey.aiff" "Samantha" "Alex"
generate_sound "Stop it!" "$SOUNDS_DIR/classic/stop_it.aiff" "Samantha" "Alex"
generate_sound "That hurts!" "$SOUNDS_DIR/classic/that_hurts.aiff" "Samantha" "Alex"
generate_sound "Why?" "$SOUNDS_DIR/classic/why.aiff" "Samantha" "Alex"

# Sexy pack
echo "💋 Sexy pack..."
generate_sound "Oh yeah." "$SOUNDS_DIR/sexy/oh_yeah_1.aiff" "Samantha" "Victoria"
generate_sound "Oh yeah!" "$SOUNDS_DIR/sexy/oh_yeah_2.aiff" "Samantha" "Victoria"
generate_sound "Mmm." "$SOUNDS_DIR/sexy/mmm.aiff" "Samantha" "Victoria"
generate_sound "Do it again." "$SOUNDS_DIR/sexy/do_it_again.aiff" "Samantha" "Victoria"
generate_sound "Harder." "$SOUNDS_DIR/sexy/harder.aiff" "Samantha" "Victoria"
generate_sound "Oh baby." "$SOUNDS_DIR/sexy/oh_baby.aiff" "Samantha" "Victoria"

# Angry pack
echo "🤬 Angry pack..."
generate_sound "HEY!" "$SOUNDS_DIR/angry/hey_loud.aiff" "Fred" "Bruce"
generate_sound "OUCH!" "$SOUNDS_DIR/angry/ouch_loud.aiff" "Fred" "Bruce"
generate_sound "STOP!" "$SOUNDS_DIR/angry/stop_loud.aiff" "Fred" "Bruce"
generate_sound "What the!" "$SOUNDS_DIR/angry/what_the.aiff" "Fred" "Bruce"
generate_sound "Idiot!" "$SOUNDS_DIR/angry/idiot.aiff" "Fred" "Bruce"
generate_sound "Seriously!" "$SOUNDS_DIR/angry/seriously.aiff" "Fred" "Bruce"

# Goat pack
echo "🐐 Goat pack..."
generate_sound "Baaaa!" "$SOUNDS_DIR/goat/baaa_1.aiff" "Bad News" "Bruce"
generate_sound "Baaaaa!" "$SOUNDS_DIR/goat/baaa_2.aiff" "Bad News" "Bruce"
generate_sound "Maah!" "$SOUNDS_DIR/goat/maah.aiff" "Bad News" "Bruce"
generate_sound "Bleeeet!" "$SOUNDS_DIR/goat/bleeeet.aiff" "Bad News" "Bruce"
generate_sound "Meeeeh!" "$SOUNDS_DIR/goat/goat_scream.aiff" "Bad News" "Bruce"
generate_sound "Baaaaah!" "$SOUNDS_DIR/goat/meeeeh.aiff" "Bad News" "Bruce"

# Robot pack
echo "🤖 Robot pack..."
generate_sound "Error four oh four." "$SOUNDS_DIR/robot/error_404.aiff" "Zarvox" "Alex"
generate_sound "Damage detected." "$SOUNDS_DIR/robot/damage_detected.aiff" "Zarvox" "Alex"
generate_sound "System hurt." "$SOUNDS_DIR/robot/system_hurt.aiff" "Zarvox" "Alex"
generate_sound "Malfunction." "$SOUNDS_DIR/robot/malfunction.aiff" "Zarvox" "Alex"
generate_sound "Ouch." "$SOUNDS_DIR/robot/ouch_robot.aiff" "Zarvox" "Alex"
generate_sound "Beep boop." "$SOUNDS_DIR/robot/beep_boop.aiff" "Zarvox" "Alex"

# Wilhelm pack - using available voices (Hysterical not on CI)
echo "😵 Wilhelm pack..."
generate_sound "Aaaaaaaah!" "$SOUNDS_DIR/wilhelm/wilhelm_1.aiff" "Albert" "Fred"
generate_sound "Oh nooooo!" "$SOUNDS_DIR/wilhelm/wilhelm_2.aiff" "Albert" "Fred"
generate_sound "Aaaah!" "$SOUNDS_DIR/wilhelm/wilhelm_3.aiff" "Albert" "Fred"
generate_sound "Aaaaaaahhh!" "$SOUNDS_DIR/wilhelm/aaaaaaah.aiff" "Albert" "Fred"
generate_sound "Noooooo!" "$SOUNDS_DIR/wilhelm/noooooo.aiff" "Albert" "Fred"
generate_sound "Aaaaaaaaaaaaaah!" "$SOUNDS_DIR/wilhelm/scream_long.aiff" "Albert" "Fred"

echo "🔄 Converting AIFF to WAV..."
find "$SOUNDS_DIR" -name "*.aiff" | while read file; do
    wavfile="${file%.aiff}.wav"
    afconvert "$file" "$wavfile" -f WAVE -d LEI16@44100
    rm "$file"
done

echo "✅ Voice packs generated!"
echo "📁 Location: $SOUNDS_DIR"
ls -la "$SOUNDS_DIR"/*/ | head -50
