---
title: "Environments and Mechanics"
date: 2023-02-24T20:48:16-06:00
draft: true
toc: false
images:
tags:
  - game-design
  - godot
---

I figured the time has finally come to provide some content regarding a few projects that are being worked on here at Volcano Lair, and our whopping staff of…one. One unpaid developer between jobs. Many of the things outlined have been in development for some time, and I will take the time to catch up where we’re at in terms of development, but these articles, they take time.

For an in development third-person shooter project, the first step of development I took was to evaluate environment building tools for Godot. While I have used Blender before in the past. it is way too over encumbered for level design, and having come from the Quake school of gaming (and mapping), I wanted something more akin to Radiant and Hammer. Something big on CSG-style modelling and brush-based design. If anything, I would use a conventional level editor to “block” the playspace and then use static meshes to make it pretty.

I hit the search engines like I hit the gym and found a good resource covering [Qodot](https://github.com/QodotPlugin/qodot-plugin) from LucyLavend, who similarly espoused using Qodot and the [TrenchBroom](https://trenchbroom.github.io/) editor as a tool for blocking. Also, this project will intentionally have a blocky, brutalist aesthetic. TrenchBroom increasingly started to look like the right tool for the job.

{{< youtube dVagDDRb2jQ >}}

For development of our test scene, which basically needs to be a space to test our player controller and eventually, other systems, I just slapped together a basic plane space in TrenchBroom and a simple placeholder texture using Affinity Photo. With a few clicks, the .map file imported without a hitch and I was able to apply the materials created with ease.

TODO: Photo from TrenchBroom

The next step in the process was to implement a player and a player controller. I evaluated a few controllers in the Asset Library and decided to go for [pemguin005’s third person controller](https://github.com/pemguin005/Third-Person-Controller---Godot-Souls-like), which also had a lot of detes on importing and configuring a player model from Mixamo.

There was a bit of code cleanup involved, a lot of the logic here wasn’t modular enough for my tastes, so I found myself moving a few things around. 

TODO Code block comparisons

In the process, I introduced a bug where it locks the camera rotation on the X axis counterclockwise after a second or so of no input that has been driving me batshit, but hasn’t been a high priority for me to fix, while I focus on more exciting things.
