# GodotRobot (AKA [LUMINSim](https://aurorarobotics.sssn.us/index.php/LUMINSim))
Simple early proof of concept robot simulation using Godot 4.4.

## How to Host a Server

To host the demo from a Linux server, run (at minimum) the following command:

    ./Demo_GodotRobot.x86_64 --headless --host --address=YourLocalIPAddress

Here are the flags available for use:
* `--headless` disables the use of any windows, enabling console-only servers.
* `--host` specifies that you are trying to host a server from the console.
* `--address=YourLocalIPAddress` sets the server's IP (127.0.0.1 by default) (can use wildcard `*` to use all available interfaces).
* `--game-version` prints out the sim's version number and exits the program.
* `--port=YourPort` sets a custom port value (31415 by default).
* `--max-players=PlayerNumberHere` sets the maximum number of players.
* `--disable-chat` disables the chat for all connected users.


## Development Process

If you are using MacOS, we have not yet set this up on your operating system! Feel free to reach out to us so we can work with you, or start a pull request with the progress you make so we can update our documentation.

To open this project, start by downloading the [Godot 4.4 engine](https://godotengine.org/download/) for your machine.

If you are on Linux, you can try out the example project by running 

    Godot-v4.4-stable.exe demo/project.godot

On Windows, run your Godot executable you downloaded earlier, click 'Import', and navigate to `MiningRobot/GodotRobot/demo/project.godot`. This *should* be the same on MacOS (and Linux if you do not specify the project directory).

You also need [Blender 3](https://download.blender.org/release/Blender3.0/), at least version 3.0 (Blender 4+ does not seem to work).  Attach the Blender install path to Godot in Godot Engine -> Editor -> Settings -> FileSystem -> Import -> Blender 3 Path.  Tip for Linux users: I set mine to "/usr/bin", the default on Ubuntu.

