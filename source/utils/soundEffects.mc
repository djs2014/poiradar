import Toybox.Attention;
import Toybox.Lang;

public class SoundEffects {
    public static function playPing() as Void {
        var toneProfile =
            [
                new Attention.ToneProfile(1000, 40),
                new Attention.ToneProfile(1500, 150),
                new Attention.ToneProfile(3000, 10),
            ] as Lang.Array<Attention.ToneProfile>;
        Attention.playTone({
            :toneProfile => toneProfile,
        });
    }

    public static function playShortLowPing() as Void {
        if (Attention has :playTone && Attention has :ToneProfile) {
            var toneProfile =
                [
                    new Attention.ToneProfile(1400, 15), // Quick low attack
                    new Attention.ToneProfile(1100, 25), // Rapid downward decay
                ] as Lang.Array<Attention.ToneProfile>;

            Attention.playTone({
                :toneProfile => toneProfile,
            });
        }
    }

    public static function playDeepLowPing() as Void {
        if (Attention has :playTone && Attention has :ToneProfile) {
            var toneProfile =
                [
                    new Attention.ToneProfile(1100, 20), // Initial attack
                    new Attention.ToneProfile(850, 30), // Deep body
                ] as Lang.Array<Attention.ToneProfile>;

            Attention.playTone({
                :toneProfile => toneProfile,
            });
        }
    }

    // Submarine Radar / Sonar Echo Ping Profile
    // repeatCount: Number of times to repeat the sonar ping sequence, set to 0 for single play.
    public static function playSubmarinePing() as Void {
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
*/
