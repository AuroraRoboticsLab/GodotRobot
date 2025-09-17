# GodotRobot
Simple early proof of concept C++ robot simulation using Godot 4.5's GDExtension interface.

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

## Development

Visit the [Aurora Robotics Lab LUMINSim documentation wiki page](https://aurorarobotics.sssn.us/index.php/LUMINSim_Documentation) for in-depth information on the inner-workings of the simulator and many plans for future development.

### Build Process

If you are using MacOS, we have not yet set this up on your operating system! Feel free to reach out to us so we can work with you, or start a pull request with the progress you make so we can update our documentation.

To build this, start by downloading the [Godot 4.5 engine](https://godotengine.org/download/) for your machine.

If using windows, now is the time that you must install WSL, if you do not have it.

1. Press the Windows button and type cmd, and hit enter. This will launch the windows terminal.
2. Type `wsl` and hit enter. Then, hit enter again after asked to "press any key."
3. Once that process is done, run `wsl --install Ubuntu`, and allow that to finish.
4. Enter your username and password when prompted, and you will enter WSL.
5. Run `sudo apt update`, entering the password you chose earlier.
6. Once the last step finishes, run `sudo apt upgrade -y`. Then you can continue with the steps below.

You'll also need build tools:

    sudo apt-get install scons build-essential g++

Check out MiningRobot first:

    git clone https://github.com/AuroraRoboticsLab/MiningRobot
    cd MiningRobot

Inside the MiningRobot/ folder, check out this repo:

    git clone https://github.com/AuroraRoboticsLab/GodotRobot
    cd GodotRobot

Now prep the correct version of the godot-cpp GDExtension interface library inside GodotRobot:

    git clone -b 4.5 https://github.com/godotengine/godot-cpp
    cd godot-cpp
    git checkout 4.5
    cd ..

If building on Windows, you need to install mingw:

    sudo apt install gcc-mingw-w64 mingw-w64 -y

Build godot-cpp (the GDExtension interface) and this extension by issuing this from inside GodotRobot/:

    scons platform=<YOUR_PLATFORM>

(Specify "platform=linux" or "platform=windows"; the default is linux)  

Building will take a few minutes the first time, as it builds the whole godot-cpp interface, but it will be very fast after that.

Finally, if you are on Linux, you can try out the example project by running 

    Godot-v4.5-stable.exe demo/project.godot

On Windows, run your Godot executable you downloaded earlier, click 'Import', and navigate to `MiningRobot/GodotRobot/demo/project.godot`.

The standard edit loop is:
 - Save in Godot Engine.
 - Edit the .cpp file in your favorite editor.
 - Switch to GodotRobot/ terminal and `scons` build.
 - Switch to Godot Engine and Project -> Reload Current Project.

You also need [Blender 3](https://download.blender.org/release/Blender3.0/), at least version 3.0 (Blender 4+ does not seem to work).  Attach the Blender install path to Godot in Godot Engine -> Editor -> Settings -> FileSystem -> Import -> Blender 3 Path.  I set mine to "/usr/bin", the default on Ubuntu.

### Web Export

To do a web export, you need Emscripten. In some distributions, simply `sudo apt install emscripten` will work. If that doesn't work for you, you'll have to clone the repository. From inside the godot-cpp cloned repo directory:
```
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
```

Then you need to `source emsdk_env.sh`. Either run that command each time a web export is necessary, or add it to your .bashrc (not recommended).

Once Emscripten is working (run `emcc --version` to check), run `scons platform=web target=template_debug threads=no` to compile for web.

## Terrain Nodes

The terrain nodes let you represent static or dynamic terrains.  They can be nested in other Node3Ds or offset around, but should not be scaled.

`TerrainStatic256` stores a 256x256 heightmap, normally loaded from an EXR float height image scaled to -10000 meters (black) to +10000 meters (white). 
 - `fill_from_image(dem:Image, pixel_spacing:float)` takes an image and pixel spacing in meters to create the height map.
 - `add_mesh(shader:Shader,casts_shadows:bool)` creates a mesh for rendering, using the specified shader.
 - `add_static_collider()` creates a StaticBody3D with a CollisionShape3D of our heightmap, so physics interacts with the terrain.

`TerrainSim` stores a dynamic mineable 256x256 heightmap.  It inherits from `TerrainStatic256`.  
 - `excavate_point(world:Vector3, dirtball_offset:Vector3, spawn_vel:Vector3)` to excavate terrain into dirtballs.  Any locations needing dirtablls will emit the signal `spawn_dirtball` with a spawn position and velocity as Vector3.
 - `try_merge(dirtball:Node3D)` to merge dirtballs back down onto the terrain.




## Debug Clues

When you start the Godot engine, you'll get errors like this if your version of godot-cpp doesn't match your engine version:

    ERROR: Attempt to get non-existent interface function: object_has_script_method.

This is caused by checking out the wrong godot-cpp version (e.g. 4.2 instead of 4.3).  Check out the right version and rebuild godot-cpp.

    ERROR: Cannot load a GDExtension built for Godot 4.X.0 using an older version of Godot (4.Y.0).
This is caused by compiling for 4.X.0, but engine being 4.Y.0.  Upgrade your engine.





