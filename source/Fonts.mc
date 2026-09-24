import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// JetBrains Mono, rendered to bitmap fonts by tools/genfonts.sh. Bitmap fonts
// live in the graphics pool, not in the 128 KB application memory.
//
// There are two sizes of the text fonts. Only the pair the user chose is
// loaded, so the large pair costs nothing when it is not used.
module Fonts {
    var big as Graphics.FontType = Graphics.FONT_NUMBER_MILD;
    var row as Graphics.FontType = Graphics.FONT_XTINY;
    var small as Graphics.FontType = Graphics.FONT_XTINY;

    function load() as Void {
        big = WatchUi.loadResource(Rez.Fonts.JbmBig) as Graphics.FontReference;
        if (Theme.textSize == 1) {
            row = WatchUi.loadResource(Rez.Fonts.JbmRowL) as Graphics.FontReference;
            small = WatchUi.loadResource(Rez.Fonts.JbmSmallL) as Graphics.FontReference;
        } else {
            row = WatchUi.loadResource(Rez.Fonts.JbmRow) as Graphics.FontReference;
            small = WatchUi.loadResource(Rez.Fonts.JbmSmall) as Graphics.FontReference;
        }
    }
}
