import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

// The menu you reach on the watch: hold MENU on the face, then the settings
// entry of this face. Buttons only, no touch needed.
module SettingsMenu {

    const VALUES = ["Heart rate", "Body battery", "Elevation", "Steps", "Temperature", "Watch battery", "Floors", "Stress"];
    const LAYOUTS = ["Neovim", "Waybar"];

    function main() as [WatchUi.Views, WatchUi.InputDelegates] {
        var menu = new WatchUi.Menu2({ :title => "OmaWatch" });
        menu.addItem(new WatchUi.MenuItem("Theme", Palettes.NAMES[Theme.themeIndex], :theme, null));
        menu.addItem(new WatchUi.MenuItem("Layout", LAYOUTS[Theme.layout], :layout, null));
        menu.addItem(new WatchUi.MenuItem("Row 1", VALUES[Theme.slots[0]], :slot1, null));
        menu.addItem(new WatchUi.MenuItem("Row 2", VALUES[Theme.slots[1]], :slot2, null));
        menu.addItem(new WatchUi.MenuItem("Row 3", VALUES[Theme.slots[2]], :slot3, null));
        menu.addItem(new WatchUi.MenuItem("Row 4", VALUES[Theme.slots[3]], :slot4, null));
        return [menu, new MainDelegate()];
    }

    function picker(title as String, names as Array<String>, key as String, item as WatchUi.MenuItem) as Void {
        var menu = new WatchUi.Menu2({ :title => title });
        for (var i = 0; i < names.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(names[i], null, i, null));
        }
        WatchUi.pushView(menu, new PickDelegate(key, names, item), WatchUi.SLIDE_LEFT);
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
        } else if (id == :layout) {
            SettingsMenu.picker("Layout", SettingsMenu.LAYOUTS, "Layout", item);
        } else if (id == :slot1) {
            SettingsMenu.picker("Row 1", SettingsMenu.VALUES, "Slot1", item);
        } else if (id == :slot2) {
            SettingsMenu.picker("Row 2", SettingsMenu.VALUES, "Slot2", item);
        } else if (id == :slot3) {
            SettingsMenu.picker("Row 3", SettingsMenu.VALUES, "Slot3", item);
        } else if (id == :slot4) {
            SettingsMenu.picker("Row 4", SettingsMenu.VALUES, "Slot4", item);
        }
    }
}

class PickDelegate extends WatchUi.Menu2InputDelegate {

    private var mKey as String;
    private var mNames as Array<String>;
    private var mItem as WatchUi.MenuItem;

    function initialize(key as String, names as Array<String>, item as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        mKey = key;
        mNames = names;
        mItem = item;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var value = item.getId() as Number;
        Properties.setValue(mKey, value);
        Theme.load();
        mItem.setSubLabel(mNames[value]);
        WatchUi.requestUpdate();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
