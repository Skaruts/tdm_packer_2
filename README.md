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



# Roadmap (hopefully, but no guarantees)
- add tool buttons for word-wrapping, undo/redo, find/replace, and also clear console, etc

- explore the potential for checking for unused files, validating the used ones, etc

- attempt to implement file editing with appropriate syntax highlighting (for xdata, scripts, materials, skins, etc)

- explore the potential for creating a new mission template from scratch at the press of a button
