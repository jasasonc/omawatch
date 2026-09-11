# Connect IQ store listing

**App name:** OmaWatch

**Type:** Watch face

**Category:** Watch Faces (secondary: Tools, if a second one is allowed)

**Keywords:** terminal, code, linux, monospace, minimal, developer, tiling, sunrise, heart rate, battery, elevation, dark

**Price:** free

**Languages:** English

**Source code:** https://github.com/jasasonc/omawatch (MIT)

---

## Description

A watch face in the style of a tiling Linux desktop. Your data reads like code, and the screen stays dark and flat.

Two layouts, switchable at any time:

- Neovim: your values as code rows, for example "hr = 54", around a highlighted cursor line that holds the time. A heart rate graph in a box at the bottom.
- Waybar: a bar across the top with the weekday as workspace numbers, the date, the temperature and the watch battery. The bottom edge of the bar fills from sunrise to sunset, and a dot marks the time of day.

What you get:

- 22 colour schemes, among them Tokyo Night, Catppuccin, Gruvbox, Everforest and Nord.
- Four rows you set yourself: heart rate, body battery, elevation, steps, temperature, watch battery, floors or stress.
- A sunrise to sunset line that shows how much daylight is left.
- A heart rate graph of the last hours.
- An always-on mode with dim digits that move every minute, to protect the screen.
- Settings on the watch. Hold MENU on the face and open the settings of the face. You do not need the phone.

Before you rate it, please read this:

- The temperature and the sunrise and sunset times come from Garmin's weather data. The watch gets that from your phone, so these fields stay empty until the first sync after you install the face.
- Elevation comes from the barometer of the watch. On watches without one, the row shows two dashes.
- Body battery, stress and floors show data only if your watch records them.

Privacy: the face reads heart rate history, body battery, steps, altitude and the last known position of the watch, and uses them only to draw the screen. Nothing is stored or sent anywhere.

OmaWatch is not connected to Garmin. It is also not connected to the Omarchy desktop project, it only follows its look.

## What's new (version 1.0.0)

First release.

## Screenshots to upload

1. docs/neovim-tokyo-night.png
2. docs/waybar-nord.png
3. docs/neovim-gruvbox.png
4. docs/waybar-catppuccin.png
5. docs/neovim-everforest.png

## Supported watches

47 round AMOLED models with Connect IQ 5.0 or newer, among them:

Instinct 3 AMOLED 45mm and 50mm, Venu 2, Venu 2S, Venu 2 Plus, Venu 3, Venu 3S, Venu 4, Vivoactive 5, Vivoactive 6, Forerunner 165, 170, 265, 265S, 570, 965, 970, epix (Gen 2), epix Pro (Gen 2) 42/47/51mm, Fenix 8 43/47mm, Fenix 8 Pro, Fenix E, Fenix 9 and 9 Pro, MARQ (Gen 2), Descent Mk3, Approach S50 and S70, D2 Air X10, D2 Mach 1 and Mach 2.
