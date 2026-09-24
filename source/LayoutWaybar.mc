import Toybox.Lang;
import Toybox.Graphics;

// Layout "Waybar": a bar across the top, its bottom edge filling from sunrise
// to sunset, then the time and the code rows.
// All numbers are for a 390 px screen and are scaled by Draw.p().
module LayoutWaybar {

    function draw(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;
        var barH = Draw.p(98);

        dc.setColor(Theme.c(Theme.DBG), Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, w, barH);

        workspaces(dc, cx, Draw.p(40));

        var tv = Data.tempValue();
        var t = tv == null ? "--" : tv.toString();
        var barY = Draw.p(68);
        Draw.text(dc, Draw.p(74), barY, Fonts.row, Theme.c(Theme.YELLOW), Draw.iconSun(), Graphics.TEXT_JUSTIFY_LEFT);
        Draw.text(dc, Draw.p(96), barY, Fonts.row, Theme.c(Theme.FG), t + "°", Graphics.TEXT_JUSTIFY_LEFT);
        Draw.text(dc, cx, barY, Fonts.row, Theme.c(Theme.FG), Clock.dayMonth(), Graphics.TEXT_JUSTIFY_CENTER);
        Draw.text(dc, w - Draw.p(96), barY, Fonts.row, Theme.c(Theme.FG), Data.bat.toString() + "%", Graphics.TEXT_JUSTIFY_RIGHT);
        Draw.text(dc, w - Draw.p(92), barY, Fonts.row, Theme.c(Theme.FG), Draw.iconBattery(), Graphics.TEXT_JUSTIFY_LEFT);

        barEdge(dc, w, barH);

        if (Theme.topBar != 7) {
            Draw.text(dc, Draw.p(34), Draw.p(112), Fonts.small, Theme.c(Theme.YELLOW), Data.barLeft(Theme.topBar), Graphics.TEXT_JUSTIFY_LEFT);
            Draw.text(dc, w - Draw.p(34), Draw.p(112), Fonts.small, Theme.c(Theme.DFG), Data.barRight(Theme.topBar), Graphics.TEXT_JUSTIFY_RIGHT);
        }

        Draw.text(dc, cx, Draw.p(172), Fonts.big, Theme.c(Theme.BFG), Clock.timeText(), Graphics.TEXT_JUSTIFY_CENTER);

        var left = cx - Draw.p(142);
        var right = cx + Draw.p(22);
        var eq = Draw.eqOffset(dc, Fonts.small, 56, 72);
        var top = Draw.p(236);
        var gap = Draw.rowGap();
        rowAt(dc, left, top, eq, 0);
        rowAt(dc, right, top, eq, 1);
        rowAt(dc, left, top + gap, eq, 2);
        rowAt(dc, right, top + gap, eq, 3);

        var boxY = Draw.p(288);
        var boxH = Draw.p(50);
        Draw.box(dc, Draw.p(75), boxY, Draw.p(240), boxH, Data.graphLabel, Fonts.small);
        Draw.graph(dc, Draw.p(83), boxY + Draw.p(9), Draw.p(224), boxH - Draw.p(18));
    }

    // The rows sit in two columns, so they use the small font. The row font
    // does not fit a long label and a long value in half a screen.
    function rowAt(dc as Dc, x as Number, y as Number, eq as Number, slot as Number) as Void {
        var id = Theme.slots[slot];
        Draw.row(dc, x, y, Fonts.small, Data.slotLabel(id), Data.slotValue(id), Data.slotUnit(id), eq);
    }

    // Weekday numbers 1 to 7, today filled like the active workspace.
    function workspaces(dc as Dc, cx as Number, y as Number) as Void {
        var today = Clock.weekday();
        var step = Draw.p(20);
        var x = cx - 3 * step;
        var dot = Draw.p(9);
        for (var d = 1; d <= 7; d++) {
            if (d == today) {
                dc.setColor(Theme.c(Theme.BFG), Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x - dot / 2, y - dot / 2, dot, dot);
            } else {
                Draw.text(dc, x, y, Fonts.small, Theme.c(Theme.DFG), d.toString(), Graphics.TEXT_JUSTIFY_CENTER);
            }
            x += step;
        }
    }

    // The bottom edge of the bar fills with the value chosen for the top bar.
    function barEdge(dc as Dc, w as Number, barH as Number) as Void {
        dc.setPenWidth(Draw.p(2));
        dc.setColor(Theme.c(Theme.SEL), Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, barH, w, barH);

        var f = Data.barFraction(Theme.topBar);
        if (Theme.topBar == 7 || f < 0.0) { return; }
        var x0 = Draw.p(24);
        var x1 = w - Draw.p(24);
        var px = x0 + ((x1 - x0) * f).toNumber();
        dc.setPenWidth(Draw.p(4));
        dc.setColor(Theme.c(Theme.YELLOW), Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, barH, px, barH);
        dc.fillCircle(px, barH, Draw.p(5));
    }
}
