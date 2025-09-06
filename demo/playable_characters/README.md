# Playable Characters

The current user-playable characters are:
* [Astra](robots/astra/),
* [Excahauler](robots/excahauler/), and
* [Astronaut](astronaut/).

The [PlayerComponent scene](player_component.tscn) is in common between all playable characters. It centralizes playable character logic by handling:
* [MovableCamera](../components/movable_camera_3d/movable_camera_3d.tscn) instantiation logic,
* [ChargeComponent](../components/charge_component/charge_component.tscn) encapsulation, and
* Nametag encapsulation.

