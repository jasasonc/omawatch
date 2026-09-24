import Toybox.Lang;

// Garmin complications. One read costs less than a millisecond, so the values
// are read with the other data once a minute. Every read is guarded: a watch
// that does not have the module, or a value it cannot supply, gives null.
module Comp {

    enum {
        BATTERY = 1, STEPS, CALORIES, FLOORS, INTENSITY, DATE, WEEKDAY,
        WEATHER_NOW, FORECAST1, FORECAST2, FORECAST3, CALENDAR, SUNRISE,
        SUNSET, ALTITUDE, PRESSURE, NOTIFICATIONS, HEART_RATE,
        WEEK_RUN, WEEK_BIKE, RECOVERY, STRESS, BODY_BATTERY,
        VO2_RUN, VO2_BIKE, TRAINING, RACE_5K, RACE_10K, RACE_HALF,
        RACE_MARATHON, PACE_5K, PACE_10K, PACE_HALF, PACE_MARATHON,
        PULSE_OX, RESPIRATION, SOLAR, TEMPERATURE, HIGH_LOW, PUSHES,
        GOLF, SLEEP_SCORE
    }

    function have() as Boolean {
        return Toybox has :Complications;
    }

    // The raw value, or null when the watch cannot supply it.
    function value(type as Number) as Lang.Object or Null {
        if (!(Toybox has :Complications)) { return null; }
        try {
            var c = Toybox.Complications.getComplication(
                new Toybox.Complications.Id(type as Toybox.Complications.Type));
            return c.value;
        } catch (e) {
            return null;
        }
    }

    function number(type as Number) as Number or Null {
        var v = value(type);
        if (v == null) { return null; }
        if (v instanceof Lang.Number) { return v as Number; }
        if (v instanceof Lang.Float) { return (v as Float).toNumber(); }
        if (v instanceof Lang.Long) { return (v as Long).toNumber(); }
        if (v instanceof Lang.Double) { return (v as Double).toNumber(); }
        return null;
    }

    function text(type as Number) as String or Null {
        var v = value(type);
        if (v == null) { return null; }
        if (v instanceof Lang.String) { return v as String; }
        return null;
    }
}
