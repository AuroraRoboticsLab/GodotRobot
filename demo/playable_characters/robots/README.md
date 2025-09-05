# Robots

The robots that exist are:
* [Astra](astra/), and
* [Excahauler](excahauler/).

All robots inherit from the [BaseRobot](base_robot.tscn) scene which contains:
* A [PlayerComponent](../), 
* a movable CenterOfMass marker, and
* an [AutonomyComponent](../../components/autonomy_component/autonomy_component.tscn).

Currently, all robots are able to pick up and use all [tool attachments](tool_attachments/).
