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

    // Pass keys like :blue, :yellow, :green, :grey, :text, :background
    static function getColor(key as Symbol, isDarkTheme as Boolean) as Number {
        if (isDarkTheme) {
            switch (key) {
                case :blue:
                    return 0x00AAFF; // Garmin blue
                case :cyanBlue:
                    return 0x00D5FF; // Vibrant cyan-blue
                case :yellow:
                    return 0xE5FF00; // Adjusted lemon yellow for LCD/Edge 1050
                case :green:
                    return 0x00FF66; // Bright mint green
                case :red:
                    return 0xFF4444; // Bright red
                case :grey:
                    return 0xAAAAAA; // Light grey
                case :text:
                    return Graphics.COLOR_WHITE;
                case :background:
                    return Graphics.COLOR_BLACK;
            }
        } else {
            // Light Theme
            switch (key) {
                case :blue:
                    return 0x00AAFF; // Garmin blue
                case :royalBlue:
                    return 0x0044CC; // Deep royal blue
                case :yellow:
                    return 0x997700; // Dark gold/amber
                case :green:
                    return 0x008822; // Forest green
                case :red:
                    return 0xCC3333; // Deep red
                case :grey:
                    return 0x555555; // Dark slate grey
                case :text:
                    return Graphics.COLOR_BLACK;
                case :background:
                    return Graphics.COLOR_WHITE;
            }
        }
        return Graphics.COLOR_WHITE;
    }
}