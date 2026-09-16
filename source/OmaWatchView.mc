import Toybox.Lang;
import Toybox.Graphics;
import Toybox.System;
import Toybox.WatchUi;

class OmaWatchView extends WatchUi.WatchFace {

    // Always-on mode must stay dim and must move a little every minute, or the
    // watch turns the screen off. Grey, thin, and 4 px of movement.
    const AOD_COLOUR = 0x555555;
    const AOD_SHIFT = 4;

    private var mLowPower as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        Draw.setScreen(dc.getWidth());
        Theme.load();
        Fonts.load();
    }

    function onShow() as Void {
        Data.refresh(true);
    }

    function onUpdate(dc as Dc) as Void {
        Data.refresh(false);

        var sleep = mLowPower && System.getDeviceSettings().requiresBurnInProtection;
        dc.setColor(Graphics.COLOR_WHITE, sleep ? Graphics.COLOR_BLACK : Theme.c(Theme.BG));
        dc.clear();

        if (sleep) {
            drawSleep(dc);
        } else if (Theme.layout == 1) {
            LayoutWaybar.draw(dc);
        } else {
            // The cursor blinks once a second, like a terminal.
            LayoutNeovim.draw(dc, System.getClockTime().sec % 2 == 0);
        }
    }

    function drawSleep(dc as Dc) as Void {
        var t = System.getClockTime();
        var dx = (t.min % 3 - 1) * AOD_SHIFT;
        var dy = ((t.min / 3) % 3 - 1) * AOD_SHIFT;
        var cx = dc.getWidth() / 2 + dx;
        var cy = dc.getHeight() / 2 + dy;

        Draw.text(dc, cx, cy, Fonts.big, AOD_COLOUR, Clock.timeText(), Graphics.TEXT_JUSTIFY_CENTER);

        var f = Data.barFraction(Theme.topBar);
        if (Theme.topBar != 7 && f >= 0.0) {
            var w = Draw.p(160);
            var y = cy - Draw.p(90);
            dc.setColor(AOD_COLOUR, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            var px = cx - w / 2 + (w * f).toNumber();
            dc.drawLine(cx - w / 2, y, px, y);
        }
    }

    function onEnterSleep() as Void {
        mLowPower = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        mLowPower = false;
        WatchUi.requestUpdate();
    }
}
