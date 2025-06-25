# TDM Packer 2
A GUI tool for The Dark Mod mappers, to help managing and packing fan missions. It can create the `pk4` for you, automatically excluding any files and folders you specify in a `.pkignore` file, and allow you to easily edit some mission files, run DarkRadiant, and more.


###### Note: for users running this from source: this project is using Godot 4.4.stable. It may not work in older versions of Godot.

###### Note: As this is still a very early version with very little testing, you should backup any missions you use this app with, and double-check the included/excluded files, as well as the resulting `pk4` contents.

![tdmp_a04_1](https://github.com/user-attachments/assets/605f244d-877c-4e1b-a797-3ee8ca917699)

![tdmp_a04_2](https://github.com/user-attachments/assets/a38eda99-a042-437b-b86e-e420138646ff)


# Current Features

- portable
- allows specifying which files should be excluded from the `pk4` file, by editing the `pkignore` file
- packs your mission into the `pk4` at the press of a button
- allows easy editing of `darkmod.txt` and `readme.txt`
- automatically creates a `startingmap.txt` or `tdm_mapsequence.txt`, according to how many maps you specify in the map sequence
- can run DarkRadiant for the selected mission
- can launch TDM for the selected mission
- can launch a second TDM installation for testing your newly packed `pk4` files in isolation


# Usage

The first thing you need to do when launching TDM Packer for the first time, is to set the paths to TDM and DarkRadiant. You can set all the paths in the settings panel, which you can find in the top-left menu -> `Settings` -> `Paths`.

The only path that is mandatory is the TDM path, as it will allow TDM Packer to find the `fms` folder, where all the missions are. The DarkRadiant path is only required if you wish to launch DarkRadiant for the selected mission (by pressing the `Edit` button in the `Missions` panel), and the *"TDM Copy Executable"* path is only required if you wish to launch a separate, fresh installation of TDM to test-run your newly packed missions (by pressing the `Test` button in the `Missions` panel).

Once you have that set up, you can add missions to your list by pressing `Open` in the `Missions` panel. You can then edit the files as you please, as well as add/remove maps from the map sequence list.

Once you have your mission ready to publish, you can press the `Pack` button in the `Missions` panel to create the `pk4` file.

### The `.pkignore` file

In the `Package -> Pack` tab you'll find an editable text box for the `.pkignore` file. This file is created automatically by TDM Packer in your mission's folder. 

This is where you can specify what should be excluded from the `pk4` file. (By default TDM Packer will pack everything in your FM folder.)

This file works similarly to a `.gitignore` file, but very limited.

```py
# suports comments

/sources     # folders must start or end with a '/'
prefabs/

# anything else is interpreted as a file filter

.blend
todo
some_file.txt
```

The filtering is case-sensitive. Don't use `*`, as it's not yet supported. These filters are merely substrings that every directory/file path is tested against: if the path has any of these substrings in it, then it's excluded. It's safer to include dots for file extensions.

Some files and folders are automatically excluded:
- any file with `bak` in it (backup files)
- file extensions `.log`, `.dat`, `.py`, `.pyc`, `.pk4`, `.zip`, `.7z`, `.rar`, `.gitignore`, `.gitattributes`
- the `.git` and `savegames` directories.


### Token Replacement

TDM Packer provides support for a few preset tokens that you can include in your `readme.txt` file, as well as to automatically append the mission version to the `pk4` filename. When creating the `pk4`, TDM Packer will replace any of these tokens in your readme file with the respective information.

The changes are only made to the file in the `pk4`, not to the original file in your hard drive.

The currently supported tokens are:
| Token | Result |
|---|---|
| $version     |  Gets replaced by the mission `Version` in darkmod.txt  |
| $author      |  Gets replaced by the `Author` name in darkmod.txt   |
| $title       |  Gets replaced by the mission `Title` in darkmod.txt   |
| $min_version |  Gets replaced by the `Required TDM Version` in darkmod.txt   |
| $date_time   |  Gets replaced with the current time and date at which the `pk4` is being created  |

The `$version` token can be used as a suffix for the `pk4` name. Extra text or symbols can be added to it in `Settings` (you can leave this field blank, if you don't want to use this feature at all).

The date/time format can be set in the Settings, as well. By default is uses `d/m/y t`, where `t` is the current time (hh:mm), and `d`, `m`, `y` are day, month and year. That format results in:
```
25/06/2025 22:55
```
The `/` and spacing are optional and can be whatever you like. For example, a format like `t  |  m, d - y` would result in:
```
22:55  |  06, 25 - 2025
```
Words or abreviations for months (e.g., "Jan", "Feb"...) are currently not supported.


# Roadmap (hopefully, but no guarantees)
- add ui buttons for word-wrapping, undo/redo, find/replace, clear console, etc.

- explore the potential for checking for unused files, validating the used ones, etc.

- attempt to implement file editing with appropriate syntax highlighting (for xdata, scripts, materials, skins, etc).

- explore the potential for creating a new mission template from scratch at the press of a button.
