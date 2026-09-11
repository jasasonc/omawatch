import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Position;

// All watch values, read at most once a minute. In high power mode the face
// redraws every second, so onUpdate must never read a sensor.
module Data {

    var hr as Number or Null = null;
    var bb as Number or Null = null;
    var stress as Number or Null = null;
    var elev as Number or Null = null;
    var steps as Number = 0;
    var floors as Number or Null = null;
    var temp as Number or Null = null;
    var bat as Number = 0;

    var hist as Array<Number> = [] as Array<Number>;   // heart rate, oldest first
    var histMin as Number = 40;
    var histMax as Number = 120;

    var sunriseText as String = "--:--";
    var sunsetText as String = "--:--";
    var sunFraction as Float = -1.0;                   // 0 at sunrise, 1 at sunset, -1 unknown

    var lastMinute as Number = -1;

    // Reads everything if the minute changed.
    function refresh(force as Boolean) as Void {
        var now = System.getClockTime();
        var minute = now.hour * 60 + now.min;
        if (!force && minute == lastMinute) { return; }
        lastMinute = minute;

        bat = System.getSystemStats().battery.toNumber();

        var am = ActivityMonitor.getInfo();
        if (am != null) {
            if (am.steps != null) { steps = am.steps as Number; }
            if (am has :floorsClimbed && am.floorsClimbed != null) { floors = am.floorsClimbed as Number; }
            if (am has :stressScore && am.stressScore != null) { stress = am.stressScore as Number; }
        }

        var act = Activity.getActivityInfo();
        if (act != null) {
            if (act.currentHeartRate != null) { hr = act.currentHeartRate as Number; }
            if (act.altitude != null) { elev = (act.altitude as Float).toNumber(); }
        }

        readSensorHistory();
        readWeather(act);
    }

    function readSensorHistory() as Void {
        if (!(Toybox has :SensorHistory)) { return; }

        if (Toybox.SensorHistory has :getBodyBatteryHistory) {
            var it = Toybox.SensorHistory.getBodyBatteryHistory({ :period => 1, :order => Toybox.SensorHistory.ORDER_NEWEST_FIRST });
            var s = it.next();
            if (s != null && s.data != null) { bb = (s.data as Float).toNumber(); }
        }

        if (Toybox.SensorHistory has :getHeartRateHistory) {
            var it = Toybox.SensorHistory.getHeartRateHistory({ :period => new Time.Duration(4 * 3600), :order => Toybox.SensorHistory.ORDER_OLDEST_FIRST });
            var values = [] as Array<Number>;
            var lo = 250;
            var hi = 0;
            var s = it.next();
            while (s != null) {
                if (s.data != null) {
                    var v = (s.data as Float).toNumber();
                    if (v > 0) {
                        values.add(v);
                        if (v < lo) { lo = v; }
                        if (v > hi) { hi = v; }
                    }
                }
                s = it.next();
            }
            hist = values;
            if (hi > lo) {
                histMin = lo;
                histMax = hi;
            }
            if (hr == null && values.size() > 0) { hr = values[values.size() - 1]; }
        }
    }

    function readWeather(act as Activity.Info or Null) as Void {
        if (!(Toybox has :Weather)) { return; }

        var cc = Toybox.Weather.getCurrentConditions();
        if (cc != null && cc.temperature != null) { temp = (cc.temperature as Numeric).toNumber(); }

        // Sunrise and sunset need a position. The weather station is the best
        // one, because the phone syncs it. Some watches give 0,0 instead of
        // "no position", so every position is checked before it is used.
        var loc = null;
        if (cc != null && cc.observationLocationPosition != null) {
            loc = valid(cc.observationLocationPosition as Position.Location);
        }
        if (loc == null && act != null && act.currentLocation != null) {
            loc = valid(act.currentLocation as Position.Location);
        }
        if (loc == null && (Toybox has :Position)) {
            // The last known fix. This does not switch the GPS on.
            var pi = Position.getInfo();
            if (pi != null && pi.position != null) {
                loc = valid(pi.position as Position.Location);
            }
        }
        if (loc != null) {
            Storage.setValue("loc", (loc as Position.Location).toDegrees());
        } else {
            var saved = Storage.getValue("loc");
            if (saved instanceof Array && saved.size() == 2) {
                loc = valid(new Position.Location({
                    :latitude => saved[0] as Double,
                    :longitude => saved[1] as Double,
                    :format => :degrees
                }));
            }
        }
        if (loc == null) { return; }

        var now = Time.now();
        var rise = Toybox.Weather.getSunrise(loc as Position.Location, now);
        var set = Toybox.Weather.getSunset(loc as Position.Location, now);
        if (rise == null || set == null) { return; }

        // A day must be longer than 4 hours and shorter than 22 hours. Outside
        // that, the position is wrong and the times are not shown.
        var total = (set as Time.Moment).value() - (rise as Time.Moment).value();
        if (total < 4 * 3600 || total > 22 * 3600) { return; }

        sunriseText = clock(rise as Time.Moment);
        sunsetText = clock(set as Time.Moment);

        var done = now.value() - (rise as Time.Moment).value();
        var f = done.toFloat() / total.toFloat();
        if (f < 0.0) { f = 0.0; }
        if (f > 1.0) { f = 1.0; }
        sunFraction = f;
    }

    // Null for a position that cannot be real: the middle of the ocean at 0,0,
    // the 180,180 some watches return, or values out of range.
    function valid(loc as Position.Location or Null) as Position.Location or Null {
        if (loc == null) { return null; }
        var d = loc.toDegrees();
        var lat = (d[0] as Double).toFloat();
        var lon = (d[1] as Double).toFloat();
        if (lat > 90.0 || lat < -90.0 || lon > 180.0 || lon < -180.0) { return null; }
        if (lat > -0.5 && lat < 0.5 && lon > -0.5 && lon < 0.5) { return null; }
        return loc;
    }

    function clock(m as Time.Moment) as String {
        var t = Gregorian.info(m, Time.FORMAT_SHORT);
        return two(t.hour) + ":" + two(t.min);
    }

    function two(v as Number) as String {
        return v < 10 ? "0" + v.toString() : v.toString();
    }

    // Slot values, in the order of the settings list.
    function slotLabel(slot as Number) as String {
        var names = ["hr", "bb", "elev", "steps", "temp", "bat", "floors", "stress"];
        return slot >= 0 && slot < names.size() ? names[slot] : "";
    }

    function slotValue(slot as Number) as String {
        switch (slot) {
            case 0: return numText(hr);
            case 1: return numText(bb);
            case 2: return numText(elev);
            case 3: return steps.toString();
            case 4: return numText(temp);
            case 5: return bat.toString();
            case 6: return numText(floors);
            case 7: return numText(stress);
        }
        return "";
    }

    function slotUnit(slot as Number) as String {
        switch (slot) {
            case 2: return " m";
            case 4: return "°";
            case 5: return "%";
        }
        return "";
    }

    function numText(v as Number or Null) as String {
        return v == null ? "--" : v.toString();
    }
}
