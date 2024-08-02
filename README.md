# TDM Packer 2
A GUI tool for managing and packing The Dark Mod missions. It can create the `pk4` for you, automatically excluding any files and folders you specify in a `.pkignore` file, and allow you to easily edit some mission files, run DarkRadiant, and more.


###### Note: This project was made in Godot 4.2.2-stable. It may not work in older versions of Godot. It also uses GDSCript exclusively, which doesn't require the Mono version of Godot, but should be compatible with it.

![2024-08-02 18_18_58-TDM Packer 2](https://github.com/user-attachments/assets/1e03cefc-35ba-41c7-8ab1-805893c2a86c)

![2024-08-02 18_29_08-TDM Packer 2](https://github.com/user-attachments/assets/df567658-90fd-4a26-a83e-8b84d00bcdae)


# Current Features

- fully portable
- automatically creates a .pkignore ignore file in your FM folder
- allow you to edit the .pkignore file
- provides editors for `darkmod.txt` and `readme.txt`
- automatically creates a `startingmap.txt` or `tdm_mapsequence.txt`, according to how many maps you specify in the map sequence
- packs your mission into the pk4 at the press of a button, excluding all files and folders you specify in the .pkignore
- can run DarkRadiant sepcifically for the selected mission
- can launch a copy of TDM for testing your newly packed pk4 files in isolation
- supports multiple missions


# Usage

The first thing you need to do when launching TDM Packer for the first time, is to set the paths to TDM and DarkRadiant. You can set all the paths in the settings panel, which you can find in the top-left menu -> `Settings` -> `Paths`.

The only path that is mandatory is the TDM path, as it will allow TDM Packer to find your missions folder. The DarkRadiant path is only required if you wish to launch DarkRadiant for the selected mission (by pressing the `Edit` button in the `Missions` panel), and the `TDM Test Version` path is only required if you wish to launch a separate copy of your TDM instalation to test-run your newly packed pk4 files (by pressing the `Test` button in the `Missions` panel).

Once you have that set up, you can press the `Add` button in the `Missions` panel to add missions to your list. You can then edit the .pkignore file (in the `Files` tab), and a few others, as you please, as well as add/remove maps from the map sequence list.


### The `.pkignore` file

By default TDM Packer will pack everything in your FM folder, but you can edit the `.pkignore` file to specify what should be excluded. This file works similarly to a `.gitignore` file, but very limited.

```py
# suports comments

/sources     # folders must start or end with a '/'
/savegames
prefabs/

# anything else is interpreted as a file filter

.blend
todo
some_file.txt
```

Don't use `*`, as it's not supported. These filters are merely substrings that every directory/file name is tested against: if it has any of these substrings in it, then it's excluded. It's better to include dots for file extensions, though.

Some files and folders are automatically excluded:
- any file with `bak` in it (backup files)
- file extensions `.log`, `.dat`, `.py`, `.pyc`, `.pk4`, `.zip`, `.7z`, `.rar`, `.gitignore`, `.gitattributes`
- the `.git` and `savegames` directories.


The filtering system is case-sensitive.









# Roadmap (hopefully, but no guarantees)
- add tool buttons for word-wrapping, undo/redo, find/replace, and also clear console, etc

- explore the potential for checking for unused files, validating the used ones, etc

- attempt to implement file editing with appropriate syntax highlighting (for xdata, scripts, materials, skins, etc)

- explore the potential for creating a new mission template from scratch at the press of a button
