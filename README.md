# GodotRobot
Simple early proof of concept C++ robot simulation using Godot 4.2's GDExtension interface.

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


## Build Process

To build this, start by downloading the [Godot 4.2.2 engine](https://godotengine.org/download/) for your machine.

You also need [Blender 3](https://download.blender.org/release/Blender3.0/), at least version 3.0 (Blender 4+ does not seem to work).  Attach the Blender install path to Godot in Godot Engine -> Editor -> Settings -> FileSystem -> Import -> Blender 3 Path.  I set mine to "/usr/bin", the default on Ubuntu.


You'll also need build tools:

    sudo apt-get install scons build-essential g++

Check out MiningRobot first:

    git clone https://github.com/AuroraRoboticsLab/MiningRobot
    cd MiningRobot

Inside the MiningRobot/ folder, check out this repo:

    git clone https://github.com/AuroraRoboticsLab/GodotRobot
    cd GodotRobot

Now prep the correct version of the godot-cpp GDExtension interface library inside GodotRobot:

    git clone -b 4.2 https://github.com/godotengine/godot-cpp
    cd godot-cpp
    git checkout 4.2
    cd ..

Build godot-cpp (the GDExtension interface) and this extension by issuing this from inside GodotRobot/:

    scons

(Or you can specify a "platform=linux" or "platform=windows" string.)  

Building will take a few minutes the first time, as it builds the whole godot-cpp interface, but it will be very fast after that.

Finally, you can try out the example project by running 

    Godot-v4.2.2-stable.exe demo/project.godot

The standard edit loop is:
 - Save in Godot Engine.
 - Edit the .cpp file in your favorite editor.
 - Switch to GodotRobot/ terminal and `scons` build.
 - Switch to Godot Engine and Project -> Reload Current Project.


## Godot Robot Nodes

GodotRobot2D is a Sprite2D that pulls its location from C++ and automatically moves around under C++ control. 


## Debug Clues

When you start the Godot engine, you'll get errors like this if your version of godot-cpp doesn't match your engine version:

    ERROR: Attempt to get non-existent interface function: object_has_script_method.

This is caused by godot-cpp being 4.3, but engine being 4.2.  Check out the right version and rebuild godot-cpp.





