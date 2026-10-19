# TDM Packer 2
A GUI tool for [Dark Mod](https://www.thedarkmod.com/) mappers, to help managing and packing fan missions. It can create the `pk4` file for you, automatically excluding any files and folders you specify in a `.pkignore` file, and allow you to easily fill out your mission's details, run DarkRadiant, edit files with syntax highlighting, and more.

###### Note: for users running this from source: this project uses Godot 4.4x. It may not work reliably in older or newer versions of Godot. (I'll keep using this version for the foreseable future.)

###### Note: As this is still a very early version with very limited testing, you should backup any missions you use this app with, and double-check the included/excluded files, as well as the resulting `pk4` contents.

###### Note: support for campaigns may be unreliable (it's completely untested). If your mission involves multiple maps, it may be better to not rely on this application for now.


# Current Features

- portable*
- allows specifying which files should be excluded from the `pk4` file, by editing the `pkignore` file
- packs your mission into the `pk4` at the press of a button
- allows easy editing of `darkmod.txt`, `readme.txt` and more
- automatically creates a `startingmap.txt` or `tdm_mapsequence.txt`, according to how many maps you specify in the map sequence
- can run DarkRadiant for the selected mission
- can launch TDM for the selected mission
- can launch a second TDM installation for testing your newly packed `pk4` files in isolation
- can edit files with syntax highlighting (`.xd`, `.gui`, .mtr, .script, etc).

###### * A note about portability: Godot inherently creates a folder in your OS's user data folder (%appdata% on Windows), but it's not used by TDM Packer.)


# Setting Up

First you need to set the paths to TDM and DarkRadiant. You can set all the paths in the settings panel, which you can find in the top-left menu icon -> `Settings` -> `Paths`.

<img width="560" height="379" alt="paths" src="https://github.com/user-attachments/assets/dd6f0935-b34f-474a-93bb-9a674057e919" />


- The TDM path is required for TDM Packer to find the `fms` folder, where all the missions are, and in case you wish to run TDM for the selected missions.

- DarkRadiant's path is only required if you wish to launch DarkRadiant for the selected missions (by pressing the `Edit` button in the `Missions` panel).

- The *"TDM Test Instance"* path is only required if you wish to launch a separate, fresh installation of TDM to test-run your newly packed missions in isolation (by pressing the `Test` button in the `Missions` panel).

Then you can add missions to your list by pressing `Open` in the `Missions` panel. All missions are read-only by default, so if you wish to manage/edit a mission, click the dot icon next to it. It turns into a green checkmark, meaning the mission can be edited. You can change this at any time.

<img width="519" height="418" alt="open_mission" src="https://github.com/user-attachments/assets/887eeae5-eb59-4424-ac8f-387d4c46e885" />


You can then edit/manage the mission as you please, and once you have your mission ready to publish, you can press the `Pack` button in the `Missions` panel to create the `pk4` file.

<img width="554" height="379" alt="packing" src="https://github.com/user-attachments/assets/20d0f84b-9ec1-4608-bff1-ae1c35b7d2fc" />



# Using TDM Packer

###### Note: All changes made to the mission are saved automatically.


## The `.pkignore` file

In the `Package -> Pack` tab you'll find an editable text box for the `.pkignore` file. This file is created automatically in your mission's folder.

This is where you can specify what should be excluded from the `pk4` file. (By default TDM Packer will pack everything in your mission's folder.)

This file works similarly to a `.gitignore` file, but more limited.

The filtering is case-sensitive, and does not yet support using `*`. These filters are merely substrings that every directory/file path is tested against: if the path has any of these substrings in it, then it's excluded. It's safer to include dots for file extensions.

<img width="922" height="590" alt="pkignore" src="https://github.com/user-attachments/assets/d17c3969-5952-4823-83bd-780e8b940582" />


Some files and folders are automatically excluded:
- file extensions `.log`, `.dat`, `.py`, `.pyc`, `.pk4`, `.zip`, `.7z`, `.rar`, `.gitignore`, `.gitattributes`
- the `.git` and `savegames` directories.
- the `.pkignore` itself

Some are automatically included:
- `darkmod.txt`
- `readme.txt`
- `startingmap.txt` and `tdm_mapsequence.txt`
- the `maps` folder

## darkmod.txt

Your can edit this file through the text fields in `Package -> Info`.

<img width="922" height="590" alt="modfile" src="https://github.com/user-attachments/assets/04bb751b-9e79-4f3c-bec1-d878d3fcdcb7" />

The file will be saved in conformity to the ordering required by DarkRadiant:
```
Title: ...

Mission 1 Title: ...
Mission 2 Title: ...
(...)
Mission N Title: ...

Description: ...
Author: ...
Version: ...
Required TDM Version: ...
```







## Token Replacement

There is support for a few preset tokens that you can include in your `readme.txt` file, as well as to automatically append the mission version to the `pk4` filename. When creating the `pk4`, TDM Packer will replace any of these tokens in your readme file with the respective information.

The changes are only made to the file in the `pk4`, not to the original file that you're editing.

The currently supported tokens are:
| Token | Result |
|---|---|
| $version     |  Gets replaced by the mission `Version` in darkmod.txt  |
| $author      |  Gets replaced by the `Author` name in darkmod.txt   |
| $title       |  Gets replaced by the mission `Title` in darkmod.txt   |
| $min_version |  Gets replaced by the `Required TDM Version` in darkmod.txt   |
| $date_time   |  Gets replaced with the current time and date at which the `pk4` is being created  |

The `$version` token can be used as a suffix for the `pk4` name. Extra text or symbols can be added to it in `Settings` (you can leave the field blank if you don't want to use this feature at all).

The date/time format can be set in the Settings, as well. By default is uses `d/m/y t`, where `t` is the current time (hh:mm), and `d`, `m`, `y` are day, month and year. That format results in:
```
25/06/2025 22:55
```
The `/` and spacing are optional and can be whatever you like. For example, a format like `t  |  m, d - y` would result in:
```
22:55  |  06, 25 - 2025
```
Words or abreviations for months (e.g., "Jan", "Feb"...) are currently not supported.



## File Editing

You can edit mission files in the `Files` tab, with syntax highlighting.

<img width="922" height="590" alt="files" src="https://github.com/user-attachments/assets/8365a90f-eeb6-4d0f-a381-fa245a1a7f5a" />









# Roadmap (hopefully, but no guarantees)
- add ui buttons for word-wrapping, undo/redo, find/replace, clear console, etc.

- explore the potential for checking for unused files, validating the used ones, etc.

- explore the potential for creating a new mission template from scratch at the press of a button.
