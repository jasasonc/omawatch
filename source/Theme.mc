import Toybox.Lang;
import Toybox.Application;

// Colours and user settings. The palettes are the same ones the desktop themes
// use, in the order below.
module Theme {

    enum {
        BG = 0, DBG, LBG, SEL, MUTED, FG, DFG, BFG, ACCENT, RED, YELLOW, GREEN, CYAN, ORANGE
    }


    // Cached settings
    var themeIndex as Number = 0;
    var layout as Number = 0;
    var slots as Array<Number> = [0, 1, 2, 3];
    var topBar as Number = 0;
    var tempUnit as Number = 0;
    var distUnit as Number = 0;
    var graph as Number = 0;
    var textSize as Number = 0;

    function load() as Void {
        themeIndex = Cfg.THEME >= 0 ? Cfg.THEME : num("Theme", 0);
        if (themeIndex < 0 || themeIndex >= Palettes.COLOURS.size()) { themeIndex = 0; }
        layout = num("Layout", Cfg.LAYOUT);
        if (layout < 0) { layout = Cfg.LAYOUT; }
        slots = Cfg.SLOTS.size() == 4 ? Cfg.SLOTS
                                      : [num("Slot1", 0), num("Slot2", 1), num("Slot3", 2), num("Slot4", 3)];
        for (var i = 0; i < slots.size(); i++) {
            if (slots[i] < 0 || slots[i] > 30) { slots[i] = 0; }
        }
        topBar = num("TopBar", 0);
        if (topBar < 0 || topBar > 10) { topBar = 0; }
        tempUnit = num("TempUnit", 0);
        if (tempUnit < 0 || tempUnit > 2) { tempUnit = 0; }
        distUnit = num("DistUnit", 0);
        if (distUnit < 0 || distUnit > 2) { distUnit = 0; }
        graph = num("Graph", 0);
        if (graph < 0 || graph > 6) { graph = 0; }
        textSize = num("TextSize", 0);
        if (textSize < 0 || textSize > 1) { textSize = 0; }
    }

    function num(key as String, fallback as Number) as Number {
        try {
            var v = Properties.getValue(key);
            if (v instanceof Number) { return v; }
        } catch (e) {
            // A missing property falls back to the default below.
        }
        return fallback;
    }

    // One colour of the active palette.
    function c(slot as Number) as Number {
        return Palettes.COLOURS[themeIndex][slot];
    }
}
