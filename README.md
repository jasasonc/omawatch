# OmaWatch

A Garmin watch face in the style of a tiling Linux desktop. Two layouts, a
code-editor look, and the colour schemes of the Omarchy desktop.

## Layouts

- **Neovim.** Your values as code rows (`hr = 54`) around a cursor line that
  holds the time. A heart rate graph in a box at the bottom, like btop.
- **Waybar.** A bar across the top with the weekday as workspace numbers.
  The bottom edge of the bar fills from sunrise to sunset.

## Features

- 22 colour schemes: Tokyo Night, Catppuccin, Gruvbox, Everforest, Nord and
  more.
- Four rows you can set: heart rate, body battery, elevation, steps,
  temperature, watch battery, floors, stress.
- Sunrise and sunset line with the current position of the sun.
- Heart rate graph of the last hours.
- Always-on mode with dim digits that move every minute.
- Settings on the watch itself: hold MENU on the face and open its settings.
  No phone needed.

## Requirements

- A round AMOLED Garmin watch with Connect IQ API 5.0 or newer. 47 models,
  from the Venu 2 to the Fenix 8.
- Temperature and the sunrise and sunset times come from Garmin's weather
  data. The watch gets them from the phone, so they stay empty until the
  first sync.

## Install

Get it from the Connect IQ Store, or build it yourself.

## Build

1. Install the Connect IQ SDK Manager, then the SDK and the devices you want.
2. Make a developer key:

   ```
   openssl genrsa -out developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key -nocrypt
   ```

3. Build for one watch:

   ```
   monkeyc -f monkey.jungle -d instinct3amoled45mm -o bin/omawatch.prg -y developer_key -w -l 3
   ```

4. Run it in the simulator:

   ```
   connectiq &
   monkeydo bin/omawatch.prg instinct3amoled45mm
   ```

To put it on a watch, copy the `.prg` file to `GARMIN/Apps` on the watch, then
disconnect the cable.

## Fonts

The face uses JetBrains Mono, converted to bitmap fonts with
`tools/mkfont.py`. To make the fonts for one screen size:

```
tools/mkfont.py --ttf /usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf \
  --size 17 --out resources-round-390x390/fonts --name jbmrow \
  --extra-codepoints U+E34C,U+E34D,U+F240,U+E30D
```

JetBrains Mono is licensed under the SIL Open Font License 1.1. See
`docs/OFL.txt`.

## Layout grid

Every layout is drawn on a 390 x 390 grid and scaled to the screen with
`Draw.p()`. Each screen size has its own font set in
`resources-round-<size>x<size>/fonts`.

## Licence

MIT. See `LICENSE`.

This project is not connected to Garmin, and not connected to the Omarchy
project.
