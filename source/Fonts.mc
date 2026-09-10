import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// JetBrains Mono, rendered to bitmap fonts by tools/mkfont.py. Bitmap fonts
// live in the graphics pool, not in the 128 KB application memory.
module Fonts {
    var big as Graphics.FontType = Graphics.FONT_NUMBER_MILD;
    var row as Graphics.FontType = Graphics.FONT_XTINY;
    var small as Graphics.FontType = Graphics.FONT_XTINY;

    function load() as Void {
        big = WatchUi.loadResource(Rez.Fonts.JbmBig) as Graphics.FontReference;
        row = WatchUi.loadResource(Rez.Fonts.JbmRow) as Graphics.FontReference;
        small = WatchUi.loadResource(Rez.Fonts.JbmSmall) as Graphics.FontReference;
    }
}
