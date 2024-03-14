#include "godotrobot.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void GodotRobot2D::_bind_methods() {	
    ClassDB::bind_method(D_METHOD("get_amplitude"), &GodotRobot2D::get_amplitude);
	ClassDB::bind_method(D_METHOD("set_amplitude", "p_amplitude"), &GodotRobot2D::set_amplitude);
	ClassDB::add_property("GodotRobot2D", PropertyInfo(Variant::FLOAT, "amplitude"), "set_amplitude", "get_amplitude");

}

GodotRobot2D::GodotRobot2D() {
	// Initialize any variables here.
	time_passed = 0.0;
	amplitude = 10.0;
}

GodotRobot2D::~GodotRobot2D() {
	// Add your cleanup here.
}

void GodotRobot2D::_process(double delta) {
	time_passed += delta;

	Vector2 new_position = Vector2(
	    amplitude + (amplitude * sin(time_passed * 2.0)), 
	    amplitude + (amplitude * cos(time_passed * 1.5))
	);

	set_position(new_position);
}



