import Toybox.Graphics;
import Toybox.Lang;

/*
    ThemeManager.mc
    A utility class to manage color themes for the application.
    It provides a method to retrieve colors based on the current theme (dark or light).

    var isDark = (getBackgroundColor() == Graphics.COLOR_BLACK);
    var color = ThemeManager.getColor(:background, isDark));
*/
class ThemeManager {
    static function getColor(key as Symbol) as Number {
        switch (key) {
            case :blue:
                return 0x00aaff; // Garmin blue
            case :cyanBlue:
                return 0x00d5ff; // Vibrant cyan-blue
            case :darkBlue:
                return 0x0000aa;
            case :yellow:
                return 0xffff00;
            case :warmYellow:
                return 0xffea00;
            case :lemonYellow:
                return 0xe5ff00; // Adjusted lemon yellow for LCD/Edge 1050
            case :darkYellow:
                return 0x997700; // Dark gold/amber
            case :green:
                return 0x00ff66; // Bright mint green
            case :forestGreen:
                return 0x008822; // Forest green
            case :darkGreen:
                return 0x006600; // Dark green
            case :red:
                return 0xff4444; // Bright red
            case :deepRed:
                return 0xcc3333; // Deep red
            case :darkRed:
                return 0xaa0000; // Dark red
            case :lightGrey:
                return 0xaaaaaa; // Light grey
            case :grey:
                return 0x888888; // Medium grey
            case :darkGrey:
                return 0x555555; // Dark grey
        }
        return Graphics.COLOR_WHITE;
    }
}
