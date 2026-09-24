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

- Neovim: your values as code rows, "hr = 54", around a highlighted cursor line that holds the time. A graph in a box at the bottom.
- Waybar: a bar across the top with the weekday as workspace numbers, the date, the temperature and the battery.

What you get:

- 22 colour schemes: Tokyo Night, Catppuccin, Gruvbox, Everforest, Nord and more.
- Four rows from 31 values: heart rate, body battery, elevation, steps, temperature, watch battery, floors, stress, calories, pulse ox, respiration, sleep score, recovery, VO2 max, weekly run and bike distance, pressure, race time predictions, humidity, wind and rain chance.
- A top bar you set: daylight from sunrise to sunset, a goal, body battery, stress, sleep score or the day.
- A graph of the last hours, from heart rate, body battery, elevation, pressure, stress, pulse ox or temperature.
- Two text sizes. Celsius or Fahrenheit, kilometres or miles.
- Always-on mode with dim digits that move every minute.
- Settings on the watch. Hold MENU on the face and open its settings. No phone needed.

Good to know: the temperature, the weather values and the sunrise and sunset times come from Garmin's weather data, so they stay empty until your phone syncs. VO2 max, the weekly distances, the race times and the sleep score stay empty until the watch has enough data for them. Elevation and pressure need a watch with a barometer.

Privacy: the face reads your watch data only to draw the screen. Nothing is stored or sent anywhere.

Free and open source: github.com/jasasonc/omawatch

OmaWatch is not connected to Garmin, and not connected to the Omarchy project. It only follows its look.

## What's new (version 1.3.0)

See `marketing/` for the text of the last release. Version 1.3.0 went live on
2026-09-24.

## Screenshots to upload

1. docs/neovim-tokyo-night.png
2. docs/waybar-nord.png
3. docs/neovim-gruvbox.png
4. docs/waybar-catppuccin.png
5. docs/neovim-everforest.png

## Supported watches

47 round AMOLED models with Connect IQ 5.0 or newer, among them:

Instinct 3 AMOLED 45mm and 50mm, Venu 2, Venu 2S, Venu 2 Plus, Venu 3, Venu 3S, Venu 4, Vivoactive 5, Vivoactive 6, Forerunner 165, 170, 265, 265S, 570, 965, 970, epix (Gen 2), epix Pro (Gen 2) 42/47/51mm, Fenix 8 43/47mm, Fenix 8 Pro, Fenix E, Fenix 9 and 9 Pro, MARQ (Gen 2), Descent Mk3, Approach S50 and S70, D2 Air X10, D2 Mach 1 and Mach 2.
