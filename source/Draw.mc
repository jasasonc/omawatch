import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Math;

// Shared drawing pieces: code rows, the heart rate graph and the daylight line.
module Draw {

    // Everything is designed for a 390 px screen and scaled from there.
    var scale as Float = 1.0;

    function setScreen(w as Number) as Void {
        scale = w / 390.0;
    }

    function p(v as Number) as Number {
        return (v * scale + 0.5).toNumber();
    }

    // The space between two code rows. Large text needs more of it.
    function rowGap() as Number {
        return p(Theme.textSize == 1 ? 26 : 22);
    }

    // Nerd Font icons, built from their code points because Monkey C has no
    // unicode escapes.
    function iconSun() as String { return (0xe30d as Number).toChar().toString(); }
    function iconBattery() as String { return (0xf240 as Number).toChar().toString(); }
    function iconSunrise() as String { return (0xe34c as Number).toChar().toString(); }
    function iconSunset() as String { return (0xe34d as Number).toChar().toString(); }

    // hr = 54m, with the "=" at a fixed column so the rows line up.
    function row(dc as Dc, x as Number, y as Number, font as Graphics.FontType,
                 label as String, value as String, unit as String, eqOffset as Number) as Void {
        dc.setColor(Theme.c(Theme.FG), Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, label, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var eq = x + eqOffset;
        dc.setColor(Theme.c(Theme.CYAN), Graphics.COLOR_TRANSPARENT);
        dc.drawText(eq, y, font, "=", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var vx = eq + dc.getTextWidthInPixels("= ", font);
        dc.setColor(Theme.c(Theme.ORANGE), Graphics.COLOR_TRANSPARENT);
        dc.drawText(vx, y, font, value, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        if (!unit.equals("")) {
            var ux = vx + dc.getTextWidthInPixels(value, font);
            dc.setColor(Theme.c(Theme.DFG), Graphics.COLOR_TRANSPARENT);
            dc.drawText(ux, y, font, unit, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function text(dc as Dc, x as Number, y as Number, font as Graphics.FontType,
                  colour as Number, value as String, justify as Number) as Void {
        dc.setColor(colour, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, value, justify | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // btop-style bar graph of the heart rate history.
    function graph(dc as Dc, x as Number, y as Number, w as Number, h as Number) as Void {
        var n = Data.hist.size();
        if (n < 2) { return; }

        var barW = p(3);
        var gap = p(1) > 1 ? p(1) : 1;
        if (barW < 2) { barW = 2; }
        var bars = w / (barW + gap);
        if (bars < 1) { return; }

        var span = Data.histMax - Data.histMin;
        if (span < 1) { span = 1; }

        for (var i = 0; i < bars; i++) {
            // Newest bar on the right.
            var idx = n - 1 - (bars - 1 - i) * n / bars;
            if (idx < 0) { continue; }
            var v = Data.hist[idx];
            var f = (v - Data.histMin).toFloat() / span.toFloat();
            if (f < 0.06) { f = 0.06; }
            var bh = (f * h).toNumber();
            var colour = f > 0.72 ? Theme.RED : (f > 0.5 ? Theme.YELLOW : Theme.GREEN);
            dc.setColor(Theme.c(colour), Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x + i * (barW + gap), y + h - bh, barW, bh);
        }
    }

    // btop-style box with a title.
    function box(dc as Dc, x as Number, y as Number, w as Number, h as Number,
                 title as String, font as Graphics.FontType) as Void {
        dc.setColor(Theme.c(Theme.ACCENT), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(x, y, w, h, p(6));

        var tw = dc.getTextWidthInPixels(" " + title + " ", font);
        dc.setColor(Theme.c(Theme.BG), Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + p(10), y - p(6), tw, p(12));
        text(dc, x + p(12), y, font, Theme.c(Theme.FG), title, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // The top progress line: sunrise to sunset, a goal, a battery or the day,
    // chosen in the settings. The dot marks the current position.
    function topBar(dc as Dc, cx as Number, y as Number, w as Number,
                    font as Graphics.FontType, dim as Boolean) as Void {
        var kind = Theme.topBar;
        if (kind == 7) { return; }
        var lit = dim ? Theme.c(Theme.DFG) : Theme.c(Theme.YELLOW);
        var leftText = Data.barLeft(kind);
        var rightText = Data.barRight(kind);

        var left = cx - w / 2;
        var right = cx + w / 2;
        text(dc, left, y, font, dim ? Theme.c(Theme.MUTED) : Theme.c(Theme.YELLOW), leftText, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, right, y, font, dim ? Theme.c(Theme.MUTED) : Theme.c(Theme.DFG), rightText, Graphics.TEXT_JUSTIFY_RIGHT);

        var x0 = left + dc.getTextWidthInPixels(leftText, font) + p(8);
        var x1 = right - dc.getTextWidthInPixels(rightText, font) - p(8);
        if (x1 <= x0) { return; }

        dc.setPenWidth(p(2));
        dc.setColor(Theme.c(Theme.SEL), Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x0, y, x1, y);

        var f = Data.barFraction(kind);
        if (f < 0.0) { return; }
        var px = x0 + ((x1 - x0) * f).toNumber();
        dc.setColor(lit, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x0, y, px, y);
        dc.fillCircle(px, y, dim ? p(2) : p(3));
    }
}
