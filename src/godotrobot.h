/*
  Godot Robot interfacing example:
  
  Directly following GDExtension tutorial at:
    https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/gdextension_cpp_example.html
  
*/
#ifndef GODOTROBOT_H
#define GODOTROBOT_H

#include <godot_cpp/classes/sprite2d.hpp>

namespace godot {

// Draw a demo sprite
class GodotRobot2D : public Sprite2D {
	GDCLASS(GodotRobot2D, Sprite2D)

private:
	double time_passed;
	double amplitude;

protected:
	static void _bind_methods();

public:
	GodotRobot2D();
	~GodotRobot2D();
	
	void set_amplitude(const double p_amplitude) {
	    amplitude = p_amplitude;
    }

    double get_amplitude() const {
	    return amplitude;
    }

	void _process(double delta) override;
};

}

#endif


