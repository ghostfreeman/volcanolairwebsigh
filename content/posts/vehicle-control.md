---
title: "Vehicle Control"
date: 2023-03-29T21:00:00-05:00
draft: false
toc: false
images:
tags:
  - game-design
  - godot
  - programming
  - quest-system
---

I decided instead of just writing more about the theory of game design, today I’d go in depth regarding a demo i’m releasing today.

For a while, I’ve been mostly tackling my game development journeys in two different manners:

* The composition of a larger project, which entails a multitude of systems
* The creation of gameplay demos, which are self-contained enough to show progress and have something to fall back on as needed.

The first project involves a lot of additional components, including writing, worldbuilding, and design. And that will be the topic of future posts. But I wanted to share my progress on a small demo I completed for vehicle possession, as part of a medium-sized project.

The idea of commandeering vehicles is a pretty pivotal system for many games. Instead of going through the whole song and dance of building a vehicle, or even a player controller, I decided to use the [TruckTown demo](https://github.com/godotengine/godot-demo-projects/tree/4.0/3d/truck_town) to provide the vehicle code, and a contrib first person controller to provide the player controller.

I did make one small modification to the controller, to add an “Interact” action which would throw the interact on any other Scene its colliding against:

{{< rawhtml >}}
<script src="https://gist.github.com/ghostfreeman/31be130a3e9dcfbd5eda7307853b32ee.js"></script>
{{< /rawhtml >}}

This could be added elsewhere, but it seems pivotal enough to be in the controller. With this in place, all that remains is to extend the vehicle. But first, a sidebar…

## Handbrake

In the process of adding a working handbrake, I ended up making the underlying vehicle controller act erratically. I had thought upon reviewing the initial code, it would seem a trivial addition:

{{< rawhtml >}}
<script src="https://gist.github.com/ghostfreeman/f00ff47b04f9b917ebf25b85266737aa.js"></script>
{{< /rawhtml >}}

This began a long struggle with the physics process. Looking at [the underlying behavior](https://github.com/godotengine/godot-demo-projects/blob/4.0/3d/truck_town/vehicles/vehicle.gd), the engine calculates velocity per physics tick, so simply adding logic to zero it out would make it impossible to increase the acceleration for the next tick. This made my handbrake more of an outright stall.

I spent a good bit of time trying to find an ideal compromise, and ultimately settled on the below logic: 

{{< rawhtml >}}
<script src="https://gist.github.com/ghostfreeman/30eaa9749e16eb6adbca8e19916316a6.js"></script>
{{< /rawhtml >}}

In essence, its akin to engine braking, where the `clampf` will negate the engine force, the stopping force must be low but never zero, and it will avoid any of the more difficult clamping action if the speed is less than 5 meters/second. And over the remaining ticks, it will zero out. It’s not perfect, but it fits the bill.

I would love to tear this all apart and build it from the ground up someday, to better understand how the tick rate factors in. But alas, we’re on borrowed time.

## Possession

The possession logic itself works as follows:

* When interact is thrown on the vehicle, we need to toggle the lock for the vehicle controller, and the disable for the player controller
* The active camera is changed from the player to the vehicle’s camera
* The player is hidden from the scene tree and its `CollisonShape` disabled
* The player controller is locked from accepting inputs

Now I know what you’re thinking: Why hide the player? Couldn’t you just remove the node, and re-add it? Well, I tried. A few variations even, but walking up the scene tree is difficult in a non-trivial way. Any time I reinitialized the Player inside the Vehicle scene, it was never spawned in the parent game scene. Thus, it never got captured again using the rigid Node call logic below:

{{< rawhtml >}}
<script src="https://gist.github.com/ghostfreeman/97bb500bab33cda1726263057d61a6e2.js"></script>
{{< /rawhtml >}}

I also attempted to pull the node up the tree to no avail. And there’s no easy way to do this besides a singleton, and we’re pressed for time. Instead, we hide the player and disable its collision object, leaving it in-scene, and when we exit the vehicle, we re-position it based on a Marker3D next to the car door:

{{< rawhtml >}}
<script src="https://gist.github.com/ghostfreeman/8765a389bfa02488fd15b04ae8fcf338.js"></script>
{{< /rawhtml >}}

And thus, we have a car you can hop in and out of at a whimsy.

## Play for yourself

You can download the demo [here](/files/cardrive). I haven’t done a lot of bug hunting besides the obvious physics object fix, so if you find issues, you’re on your own. But if you wanna pass them along, don’t be a stranger. You can now see there’s a forum and comments here. There will also be a Discord, someday. When we have something to ship.

The source code can be viewed [here](https://github.com/ghostfreeman/carposessdemo).

Check back in a week when I go off on a rant about storytelling in games.