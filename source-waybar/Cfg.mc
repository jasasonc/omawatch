import Toybox.Lang;

// Build variant: this binary starts with the Waybar layout.
module Cfg {
    const LAYOUT = 1;

    // -1 keeps the user setting. Only screenshots override it.
    const THEME = -1;

    // Empty keeps the user setting. Only screenshots override it, because the
    // simulator holds its own copy of the settings.
    const SLOTS = [] as Array<Number>;
}
