import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

module Clock {

    function timeText() as String {
        var t = System.getClockTime();
        var hour = t.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }
        return Data.two(hour) + ":" + Data.two(t.min);
    }

    // "thu 10 sep"
    function dateText(lower as Boolean) as String {
        var i = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var s = (i.day_of_week as String) + " " + i.day.toString() + " " + (i.month as String);
        return lower ? s.toLower() : s;
    }

    // "11 Sep". The Waybar layout shows the weekday as workspace numbers, so
    // the date there does not repeat it.
    function dayMonth() as String {
        var i = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return i.day.toString() + " " + (i.month as String);
    }

    function weekday() as Number {
        var i = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        // Gregorian counts Sunday as 1, the bar counts Monday as 1.
        return ((i.day_of_week as Number) + 5) % 7 + 1;
    }
}
