import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class OmaWatchApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        Theme.load();
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [ new OmaWatchView() ];
    }

    // Reachable on the watch: hold MENU on the face, then the settings entry.
    function getSettingsView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] or Null {
        return SettingsMenu.main();
    }

    function onSettingsChanged() as Void {
        Theme.load();
        WatchUi.requestUpdate();
    }
}
