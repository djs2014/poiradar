import Toybox.Attention;
import Toybox.Lang;

public class SoundEffects {
    public static function playShortPing(repeatCount as Integer) as Void {
        var toneProfile =
            [
                new Attention.ToneProfile(1000, 40),
                new Attention.ToneProfile(1500, 150),
                new Attention.ToneProfile(3000, 0),
            ] as Lang.Array<Attention.ToneProfile>;
        Attention.playTone({
            :toneProfile => toneProfile,
            :repeatCount => repeatCount,
        });
    }

    // Submarine Radar / Sonar Echo Ping Profile
    // repeatCount: Number of times to repeat the sonar ping sequence, set to 0 for single play.
    public static function playSubmarinePing(repeatCount as Integer) as Void {
        if (Attention has :playTone && Attention has :ToneProfile) {
            var sonarPing =
                [
                    // 1. Initial High Transmit Pulse (The Sharp Ping)
                    new Attention.ToneProfile(2400, 30), // High-frequency attack
                    new Attention.ToneProfile(2100, 40), // Mid-high transition
                    new Attention.ToneProfile(1800, 60), // Transmit body tail

                    // 2. Silence / Propagation Delay (Waiting for return echo)
                    new Attention.ToneProfile(0, 180), // Pause / Silence (0 Hz)

                    // 3. The Distant Echo Return
                    new Attention.ToneProfile(1200, 25), // Soft return ping arrival
                    new Attention.ToneProfile(950, 45), // Fading resonance echo
                ] as Array<Attention.ToneProfile>;

            // Play via Connect IQ Attention API
            Attention.playTone({
                :toneProfile => sonarPing,
                :repeatCount => repeatCount,
            });
        }
    }
}
/*
Segment,Freq (Hz),Duration (ms),Acoustic Function
Transmit Attack,2400,30,Mimics the piezo shock of the ping firing.
Chirp Decay,2100 → 1800,100 total,Simulates acoustic dispersion into water.
Propagation Gap,0,180,Creates the illusion of distance (echo delay).
Echo Return,1200 → 950,70 total,A pitch-dropped secondary ping simulating a distant reflection.

Hardware Notes for Edge 1040 vs. Edge 1050
Edge 1050: Features an upgraded multi-tone speaker. It renders the 2400 Hz to 950 Hz sweep smoothly with high clarity.

Edge 1040: Uses a basic piezoelectric buzzer. Piezo speakers have high resonant peaks around 2000 Hz – 2700 Hz. 
If the echo (1200 Hz) sounds too faint on the 1040, shift the entire array up by +400 Hz:

Transmit: 2800 Hz 
→ 2400 Hz

Echo: 1600 Hz 
→ 1350 Hz
*/
