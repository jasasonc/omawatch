import Toybox.Lang;
import Toybox.Graphics;

// Layout "Neovim": code rows around a cursor line that holds the time.
// All numbers are for a 390 px screen and are scaled by Draw.p().
module LayoutNeovim {

    function draw(dc as Dc, blink as Boolean) as Void {
        var w = dc.getWidth();
        var cx = w / 2;
        var rowX = Draw.p(92);
        var bandY = Draw.p(132);
        var bandH = Draw.p(80);
        var timeX = Draw.p(74);

        Draw.topBar(dc, cx, Draw.p(40), Draw.p(232), Fonts.small, false);
        Draw.text(dc, cx, Draw.p(64), Fonts.row, Theme.c(Theme.MUTED), "-- " + Clock.dateText(true), Graphics.TEXT_JUSTIFY_CENTER);

        var gap = Draw.rowGap();
        var eq = Draw.eqOffset(dc, Fonts.row, 70, 96);
        var above = bandY - Draw.p(20);
        row(dc, 2, above - gap, rowX, eq, 0);
        row(dc, 1, above, rowX, eq, 1);

        // Cursor line
        dc.setColor(Theme.c(Theme.LBG), Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, bandY, w, bandH);
        lineNumber(dc, 3, bandY + bandH / 2, true);

        var time = Clock.timeText();
        Draw.text(dc, timeX, bandY + bandH / 2, Fonts.big, Theme.c(Theme.BFG), time, Graphics.TEXT_JUSTIFY_LEFT);
        if (blink) {
            var cur = timeX + dc.getTextWidthInPixels(time, Fonts.big) + Draw.p(6);
            dc.setColor(Theme.c(Theme.ACCENT), Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(cur, bandY + Draw.p(14), Draw.p(22), bandH - Draw.p(28));
        }

        var below = bandY + bandH + Draw.p(16);
        row(dc, 1, below, rowX, eq, 2);
        row(dc, 2, below + gap, rowX, eq, 3);

        var boxY = Draw.p(278);
        var boxH = Draw.p(52);
        Draw.box(dc, Draw.p(74), boxY, Draw.p(242), boxH, Data.graphLabel, Fonts.small);
        Draw.graph(dc, Draw.p(82), boxY + Draw.p(10), Draw.p(226), boxH - Draw.p(18));

        statusLine(dc, cx, Draw.p(348));
    }

    function row(dc as Dc, n as Number, y as Number, x as Number, eq as Number, slot as Number) as Void {
        lineNumber(dc, n, y, false);
        var id = Theme.slots[slot];
        Draw.row(dc, x, y, Fonts.row, Data.slotLabel(id), Data.slotValue(id), Data.slotUnit(id), eq);
    }

    function lineNumber(dc as Dc, n as Number, y as Number, current as Boolean) as Void {
        var colour = current ? Theme.c(Theme.YELLOW) : Theme.c(Theme.MUTED);
        Draw.text(dc, Draw.p(70), y, Fonts.small, colour, n.toString(), Graphics.TEXT_JUSTIFY_RIGHT);
    }

    // Temperature and battery with their icons, no bar around them.
    function statusLine(dc as Dc, cx as Number, y as Number) as Void {
        var tv = Data.tempValue();
        var t = tv == null ? "--" : tv.toString();

        Draw.text(dc, cx - Draw.p(86), y, Fonts.row, Theme.c(Theme.YELLOW), Draw.iconSun(), Graphics.TEXT_JUSTIFY_LEFT);
        Draw.text(dc, cx - Draw.p(64), y, Fonts.row, Theme.c(Theme.FG), t + "°", Graphics.TEXT_JUSTIFY_LEFT);

        Draw.text(dc, cx + Draw.p(20), y, Fonts.row, Theme.c(Theme.FG), Draw.iconBattery(), Graphics.TEXT_JUSTIFY_LEFT);
        Draw.text(dc, cx + Draw.p(46), y, Fonts.row, Theme.c(Theme.FG), Data.bat.toString() + "%", Graphics.TEXT_JUSTIFY_LEFT);
    }
}
