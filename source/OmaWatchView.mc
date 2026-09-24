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
    // The cursor flips when at least 0.8 s passed since the last flip. A late
    // redraw still flips, and the quick redraws right after waking do not.
    private var mCursorOn as Boolean = true;
    private var mLastFlip as Number = 0;
    const BLINK_MS = 800;

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
            var now = System.getTimer();
            if (now - mLastFlip >= BLINK_MS) {
                mCursorOn = !mCursorOn;
                mLastFlip = now;
            }
            LayoutNeovim.draw(dc, mCursorOn);
        }
    }

    function drawSleep(dc as Dc) as Void {
        var t = System.getClockTime();
        var dx = (t.min % 3 - 1) * AOD_SHIFT;
        var dy = ((t.min / 3) % 3 - 1) * AOD_SHIFT;
        var cx = dc.getWidth() / 2 + dx;
        var cy = dc.getHeight() / 2 + dy;

        Draw.text(dc, cx, cy, Fonts.big, AOD_COLOUR, Clock.timeText(), Graphics.TEXT_JUSTIFY_CENTER);

        if (Theme.topBar == 7) { return; }

        // A bare line does not say much, so the value goes under it. Both are
        // thin and grey, to keep the lit pixels low.
        var f = Data.barFraction(Theme.topBar);
        var w = Draw.p(160);
        var y = cy - Draw.p(96);
        dc.setColor(AOD_COLOUR, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        if (f >= 0.0) {
            var px = cx - w / 2 + (w * f).toNumber();
            dc.drawLine(cx - w / 2, y, px, y);
            dc.drawLine(px, y - Draw.p(3), px, y + Draw.p(3));
        }

        var summary = Data.barSummary(Theme.topBar);
        if (!summary.equals("")) {
            Draw.text(dc, cx, y + Draw.p(18), Fonts.small, AOD_COLOUR, summary, Graphics.TEXT_JUSTIFY_CENTER);
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
