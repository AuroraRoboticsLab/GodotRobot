# GodotRobot
Simple early proof of concept C++ robot simulation using Godot 4.2's GDExtension interface.

## Build Process

To build this, start by downloading the [Godot 4.2 engine](https://godotengine.org/download/) for your machine.

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

    Godot-v4.2.1-stable.exe demo/project.godot


## Godot Robot Nodes

GodotRobot2D is a Sprite2D that pulls its location from 


## Debug Clues

When you start the Godot engine, you'll get errors like this if your version of godot-cpp doesn't match your engine version:

    ERROR: Attempt to get non-existent interface function: object_has_script_method.

This is caused by godot-cpp being 4.3, but engine being 4.2.  Check out the right version and rebuild godot-cpp.





