---
title: "Environments and a Player Controller"
date: 2023-02-24T20:48:16-06:00
draft: false
toc: false
images:
tags:
  - game-design
  - godot
---

The time has finally come for an exciting devlog! Fresh off the presses, these posts will provide insight on projects, here at Volcano Lair, and our whopping staff of...one. One unpaid developer between jobs. Many of the things you'll read, have actually been in development for some time. It's going to take time to catch up with the project's current state, but these articles, they take time.

So, lets jump right in on an in-development project. I've been sitting on this for a while as I watched the tooling for Godot improve. One of these spaces is level design tools. While I have used Blender before in the past, it's top-heavy. And I am an old-school gamer, who used to do stupid things in Quake and Half-Life. Blender isn't the tool i'm used to. It was my hopes that something more oriented around CSG-style modelling would be available. I hit the search engines and found a Quake map importer called [Qodot](https://github.com/QodotPlugin/qodot-plugin) covered on YouTube. Combined with [TrenchBroom](https://trenchbroom.github.io/), a Quake level editor, I had the necessary tooling for environments.

My first introduction to both came courtesy of [LucyLavend's](https://lucylavend.com/) tutorial on Qodot, embedded below.

{{< youtube dVagDDRb2jQ >}}

For the test scene: I dropped a plane in TrenchBroom, and a quick and dirty placeholder texture. With a few clicks, the .map file imported without a hitch, and I was able to apply the materials created with ease. Qodot imported the .map, and built the necessary collision meshes.

![Image of TrenchBroom editor](/img/blog/environments-and-movement/trenchbroom_screen.jpg)

The next step in the process was a player and a player controller. I’m no stranger to third person controllers. I’ve used [another contrib controller](https://github.com/khairul169/3rdperson-godot) pre 3.x, and had [updated it](https://github.com/ghostfreeman/3rdperson-godot) to work with 3.x.

{{< youtube Wwhhgz53_HI >}}

I felt this controller lagged behind its contemporaries in the sea of the Soulslike; so I evaluated a few controllers in the Asset Library. Ultimately, [pemguin005’s third person controller](https://github.com/pemguin005/Third-Person-Controller---Godot-Souls-like) won out. It leaned on the Animation StateMachine and was documented, especially on the topic of importing assets from Mixamo. These video tutorials saved me many days of fiddling with Blender. There's a lot of specialized tooling around exporting Mixamo-rigged models straight to Godot preferred formats.

There was some code cleanup involved. Out of a passion to make functionality more readable, methods were moved around. The goal would be to make it more maintainable as a daily driver.

{{< rawhtml >}}
<script src="https://gist.github.com/ghostfreeman/af386533db9bdb8fb8e08c68a2b9d92a.js"></script>
{{< /rawhtml >}}

During the cleanup, I introduced a bug where it forces camera rotation on the X axis clockwise after a second or so of no input. It's been a sore oversight, but hasn’t been a high priority compared to new feature adds. My long term plan is to address this, or revert changes back to the origin. There’s always a chance this all gets rewritten.

{{< youtube 3zQMv-RRaek >}}

Combined, these two changes make for an ideal player controller for further development.

Thanks again for reading, if you still are. Stay tuned, more posts are coming in the future.
