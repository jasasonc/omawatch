import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

// The menu you reach on the watch: hold MENU on the face, then the settings
// entry of this face. Buttons only, no touch needed.
//
// There are 31 row values, which is too many for one list on a watch you
// operate with buttons. The row pickers therefore go through a group first:
// Row 1 -> Vitals -> Heart rate.
module SettingsMenu {

    const VALUES = ["Heart rate", "Body battery", "Elevation", "Steps", "Temperature", "Watch battery", "Floors", "Stress",
                    "Step goal %", "Steps / goal", "Floors / goal", "Active min / goal",
                    "VO2 max run", "VO2 max bike", "Weekly run distance", "Weekly bike distance",
                    "Pressure", "Calories", "Respiration rate", "Pulse ox", "Sleep score", "Recovery time",
                    "Notifications", "Race time 5K", "Race time 10K", "Race time half", "Race time marathon",
                    "Feels like", "Humidity", "Wind speed", "Rain chance"];

    const GROUPS = ["Vitals", "Activity", "Fitness", "Weather", "Watch"];

    // The row values of each group, as indexes into VALUES.
    const GROUP_VALUES = [
        [0, 1, 7, 19, 18, 20, 21],
        [3, 6, 8, 9, 10, 11, 17, 14, 15],
        [12, 13, 23, 24, 25, 26],
        [4, 27, 28, 29, 30, 16, 2],
        [5, 22]
    ];

    const LAYOUTS = ["Neovim", "Waybar"];
    const TOP_BARS = ["Daylight", "Step goal", "Floors goal", "Active minutes", "Body battery", "Watch battery", "Day", "Off",
                      "Stress", "Sleep score", "Pulse ox"];
    const GRAPHS = ["Heart rate", "Body battery", "Elevation", "Pressure", "Stress", "Pulse ox", "Temperature"];
    const TEMP_UNITS = ["Watch setting", "Celsius", "Fahrenheit"];
    const DIST_UNITS = ["Watch setting", "Kilometres", "Miles"];

    function main() as [WatchUi.Views, WatchUi.InputDelegates] {
        var menu = new WatchUi.Menu2({ :title => "OmaWatch" });
        menu.addItem(new WatchUi.MenuItem("Theme", Palettes.NAMES[Theme.themeIndex], :theme, null));
        menu.addItem(new WatchUi.MenuItem("Layout", LAYOUTS[Theme.layout], :layout, null));
        menu.addItem(new WatchUi.MenuItem("Top bar", TOP_BARS[Theme.topBar], :topbar, null));
        menu.addItem(new WatchUi.MenuItem("Graph", GRAPHS[Theme.graph], :graph, null));
        menu.addItem(new WatchUi.MenuItem("Temperature", TEMP_UNITS[Theme.tempUnit], :tempunit, null));
        menu.addItem(new WatchUi.MenuItem("Distance", DIST_UNITS[Theme.distUnit], :distunit, null));
        menu.addItem(new WatchUi.MenuItem("Row 1", VALUES[Theme.slots[0]], :slot1, null));
        menu.addItem(new WatchUi.MenuItem("Row 2", VALUES[Theme.slots[1]], :slot2, null));
        menu.addItem(new WatchUi.MenuItem("Row 3", VALUES[Theme.slots[2]], :slot3, null));
        menu.addItem(new WatchUi.MenuItem("Row 4", VALUES[Theme.slots[3]], :slot4, null));
        return [menu, new MainDelegate()];
    }

    // A flat list, for the settings that have few enough choices.
    function picker(title as String, names as Array<String>, key as String, item as WatchUi.MenuItem) as Void {
        var menu = new WatchUi.Menu2({ :title => title });
        for (var i = 0; i < names.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(names[i], null, i, null));
        }
        WatchUi.pushView(menu, new PickDelegate(key, names, item, 1), WatchUi.SLIDE_LEFT);
    }

    // The group list for a row, which then opens the values of that group.
    function rowPicker(title as String, key as String, item as WatchUi.MenuItem) as Void {
        var menu = new WatchUi.Menu2({ :title => title });
        for (var i = 0; i < GROUPS.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(GROUPS[i], null, i, null));
        }
        WatchUi.pushView(menu, new GroupDelegate(key, item), WatchUi.SLIDE_LEFT);
    }
}

class MainDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :theme) {
            SettingsMenu.picker("Theme", Palettes.NAMES, "Theme", item);
        } else if (id == :topbar) {
            SettingsMenu.picker("Top bar", SettingsMenu.TOP_BARS, "TopBar", item);
        } else if (id == :graph) {
            SettingsMenu.picker("Graph", SettingsMenu.GRAPHS, "Graph", item);
        } else if (id == :tempunit) {
            SettingsMenu.picker("Temperature", SettingsMenu.TEMP_UNITS, "TempUnit", item);
        } else if (id == :distunit) {
            SettingsMenu.picker("Distance", SettingsMenu.DIST_UNITS, "DistUnit", item);
        } else if (id == :layout) {
            SettingsMenu.picker("Layout", SettingsMenu.LAYOUTS, "Layout", item);
        } else if (id == :slot1) {
            SettingsMenu.rowPicker("Row 1", "Slot1", item);
        } else if (id == :slot2) {
            SettingsMenu.rowPicker("Row 2", "Slot2", item);
        } else if (id == :slot3) {
            SettingsMenu.rowPicker("Row 3", "Slot3", item);
        } else if (id == :slot4) {
            SettingsMenu.rowPicker("Row 4", "Slot4", item);
        }
    }
}

// Shows the values of one group. The ids are the real value numbers, so the
// stored setting stays the same whatever group it was picked from.
class GroupDelegate extends WatchUi.Menu2InputDelegate {

    private var mKey as String;
    private var mItem as WatchUi.MenuItem;

    function initialize(key as String, item as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        mKey = key;
        mItem = item;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var group = SettingsMenu.GROUP_VALUES[item.getId() as Number];
        var menu = new WatchUi.Menu2({ :title => SettingsMenu.GROUPS[item.getId() as Number] });
        for (var i = 0; i < group.size(); i++) {
            var value = group[i] as Number;
            menu.addItem(new WatchUi.MenuItem(SettingsMenu.VALUES[value], null, value, null));
        }
        WatchUi.pushView(menu, new PickDelegate(mKey, SettingsMenu.VALUES, mItem, 2), WatchUi.SLIDE_LEFT);
    }
}

class PickDelegate extends WatchUi.Menu2InputDelegate {

    private var mKey as String;
    private var mNames as Array<String>;
    private var mItem as WatchUi.MenuItem;
    // How many views to close: one for a flat list, two when the value was
    // picked inside a group, so both close and the main menu comes back.
    private var mDepth as Number;

    function initialize(key as String, names as Array<String>, item as WatchUi.MenuItem, depth as Number) {
        Menu2InputDelegate.initialize();
        mKey = key;
        mNames = names;
        mItem = item;
        mDepth = depth;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var value = item.getId() as Number;
        Properties.setValue(mKey, value);
        Theme.load();
        mItem.setSubLabel(mNames[value]);
        WatchUi.requestUpdate();
        for (var i = 0; i < mDepth; i++) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
