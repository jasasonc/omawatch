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
    var stepGoal as Number or Null = null;
    var floors as Number or Null = null;
    var floorsGoal as Number or Null = null;
    var activeWeek as Number or Null = null;
    var activeWeekGoal as Number or Null = null;
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
            if (am.stepGoal != null) { stepGoal = am.stepGoal as Number; }
            if (am has :floorsClimbed && am.floorsClimbed != null) { floors = am.floorsClimbed as Number; }
            if (am has :floorsClimbedGoal && am.floorsClimbedGoal != null) { floorsGoal = am.floorsClimbedGoal as Number; }
            if (am has :activeMinutesWeek && am.activeMinutesWeek != null) {
                activeWeek = (am.activeMinutesWeek as ActivityMonitor.ActiveMinutes).total;
            }
            if (am has :activeMinutesWeekGoal && am.activeMinutesWeekGoal != null) { activeWeekGoal = am.activeMinutesWeekGoal as Number; }
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

        // Sunrise and sunset need a position. The watch's own last fix comes
        // first, then an activity fix, then the weather station, which can be
        // far away. Some watches give 0,0 instead of "no position", so every
        // position is checked before it is used.
        var loc = null;
        if (Toybox has :Position) {
            // The last known fix. This does not switch the GPS on.
            var pi = Position.getInfo();
            if (pi != null && pi.position != null) {
                loc = valid(pi.position as Position.Location);
            }
        }
        if (loc == null && act != null && act.currentLocation != null) {
            loc = valid(act.currentLocation as Position.Location);
        }
        if (loc == null && cc != null && cc.observationLocationPosition != null) {
            loc = valid(cc.observationLocationPosition as Position.Location);
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

    // Garmin reports the temperature in Celsius. Setting 0 follows the watch
    // unit setting, 1 is Celsius, 2 is Fahrenheit.
    function tempValue() as Number or Null {
        if (temp == null) { return null; }
        var unit = Theme.tempUnit;
        var fahrenheit = unit == 2 ||
            (unit == 0 && System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE);
        return fahrenheit ? ((temp as Number) * 9.0 / 5.0 + 32.0).toNumber() : temp;
    }

    // 8432 of 10000 -> "8432/10k"
    function ofGoal(value as Number or Null, goal as Number or Null) as String {
        if (value == null) { return "--"; }
        if (goal == null || goal <= 0) { return value.toString(); }
        return value.toString() + "/" + compact(goal as Number);
    }

    function compact(n as Number) as String {
        if (n < 1000) { return n.toString(); }
        if (n % 1000 == 0) { return (n / 1000).toString() + "k"; }
        return (n / 1000).toString() + "." + ((n % 1000) / 100).toString() + "k";
    }

    function percent(value as Number or Null, goal as Number or Null) as Number or Null {
        if (value == null || goal == null || goal <= 0) { return null; }
        return ((value as Number) * 100) / (goal as Number);
    }

    // Top bar: fraction 0..1 (or -1 when unknown) and the two end labels.
    // 0 daylight, 1 step goal, 2 floors goal, 3 active minutes, 4 body battery,
    // 5 watch battery, 6 day, 7 off.
    function barFraction(kind as Number) as Float {
        switch (kind) {
            case 0: return sunFraction;
            case 1: return fraction(steps, stepGoal);
            case 2: return fraction(floors, floorsGoal);
            case 3: return fraction(activeWeek, activeWeekGoal);
            case 4: return fraction(bb, 100);
            case 5: return fraction(bat, 100);
            case 6:
                var t = System.getClockTime();
                return (t.hour * 60 + t.min).toFloat() / 1440.0;
        }
        return -1.0;
    }

    function fraction(value as Number or Null, goal as Number or Null) as Float {
        if (value == null || goal == null || goal <= 0) { return -1.0; }
        var f = (value as Number).toFloat() / (goal as Number).toFloat();
        return f > 1.0 ? 1.0 : (f < 0.0 ? 0.0 : f);
    }

    function barLeft(kind as Number) as String {
        switch (kind) {
            case 0: return Draw.iconSunrise() + " " + sunriseText;
            case 1: return "steps " + numText(steps);
            case 2: return "floors " + numText(floors);
            case 3: return "active " + numText(activeWeek);
            case 4: return "bb";
            case 5: return "bat";
            case 6: return "00";
        }
        return "";
    }

    function barRight(kind as Number) as String {
        switch (kind) {
            case 0: return sunsetText + " " + Draw.iconSunset();
            case 1: return goalText(stepGoal);
            case 2: return goalText(floorsGoal);
            case 3: return goalText(activeWeekGoal);
            case 4: return numText(bb);
            case 5: return bat.toString() + "%";
            case 6: return "24";
        }
        return "";
    }

    function goalText(goal as Number or Null) as String {
        return goal == null ? "--" : compact(goal as Number);
    }

    // Slot values, in the order of the settings list.
    function slotLabel(slot as Number) as String {
        var names = ["hr", "bb", "elev", "steps", "temp", "bat", "floors", "stress", "goal", "steps", "floors", "active"];
        return slot >= 0 && slot < names.size() ? names[slot] : "";
    }

    function slotValue(slot as Number) as String {
        switch (slot) {
            case 0: return numText(hr);
            case 1: return numText(bb);
            case 2: return numText(elev);
            case 3: return steps.toString();
            case 4: return numText(tempValue());
            case 5: return bat.toString();
            case 6: return numText(floors);
            case 7: return numText(stress);
            case 8: return numText(percent(steps, stepGoal));
            case 9: return ofGoal(steps, stepGoal);
            case 10: return ofGoal(floors, floorsGoal);
            case 11: return ofGoal(activeWeek, activeWeekGoal);
        }
        return "";
    }

    function slotUnit(slot as Number) as String {
        switch (slot) {
            case 2: return " m";
            case 4: return "°";
            case 5: return "%";
            case 8: return "%";
        }
        return "";
    }

    function numText(v as Number or Null) as String {
        return v == null ? "--" : v.toString();
    }
}
