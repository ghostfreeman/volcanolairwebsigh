---
title: "Quest System"
date: 2023-03-08T09:00:16-06:00
draft: false
toc: false
images:
tags:
  - game-design
  - godot
  - programming
  - quest-system
---

For today’s post I am going to go into building a basic quest system which I intend to use for various projects. This is far from finished, it is but the foundation that will change as my needs do. For that reason, much of what I’m describing will be theoretical. Don’t expect many code examples.

## Why we’re here

It’s not that Godot is short of a quest system: there’s a comprehensive one in [Quest Editor](https://github.com/VP-GAMES/QuestEditor). It covers all the expected features in a somewhat trivial UI with the ability to specify pre, during, and post actions through deferred method calls. Yet, why deny yourself the pleasure of building it yourself? Additionally, I haven’t fleshed out other game mechanics, and since having quests is pivotal, these will be developed in tandem. And this spares us features we don’t need. Down the road, we may need Quest Editor. But for now, let’s stick to simple and extendible.

## Examining quest systems

I started my quest by examining existing Quest systems in Godot and Unity. It’s through this I found the aforementioned Quest System, which is quite extensive but overloaded for projects at my level. Miziziziz has been a frequent source of knowledge and inspiration for me as I’ve used Godot, and he has also [built a quest system](https://github.com/Miziziziz/GodotDialogAndQuestSystem) for his projects. It’s definitely designed to be extendible, as its barebones.

There are different philosophies on quest systems. An article on GameDeveloper [from Jacob Kjeldsen](https://www.gamedeveloper.com/design/the-quest-for-the-custom-quest-system) promotes their (now mothballed) Unity plugin [CustomQuest](https://assetstore.unity.com/packages/tools/custom-quest-quest-system-92594), but its a great summary of many core principles that almost all ‘tasks’ in video games entail, reducing it to eight types:

* Kill
* Gather
* Escort
* Courier (they call *FedX*)
* Defend
* Collect (they call *Profit*)
* Activate
* Search

And from there, they identified 12 patterns that implement the types, and all behaviors in the game world that they entail. It’s not quite [the 36 dramatic situations](https://en.wikipedia.org/wiki/The_Thirty-Six_Dramatic_Situations) for game design, but this covers the tangible 80-100% of features you’ll ever use. If I had to support more than just Activate and Collect in a multi-million dollar production, I’d use the plugin.

Reflecting on Miz’s examples and CustomQuest’s design, I knew that any system I wanted to build should be:

* Quickly implementable using core Godot principles,
* Extendible in a trivial manner
* Not fight against Godot principles.

While I have extensively researched data-oriented principles, Godot [is not built for that](https://godotengine.org/article/why-isnt-godot-ecs-based-game-engine/). I’d rather not fight the engine as much as possible.

## Initial architecture

For the initial development, I took the implementation [from Miz’s system](https://github.com/Miziziziz/GodotDialogAndQuestSystem) which keeps quest data persistent between scenes via its own nested scene, with the scripting components attached. Much of the ongoing architecture owes itself to scene changes, so for the purposes of Tasks, managed by an [autoload delegate](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) that tracks quest scenes across parent scenes, assures progress is kept in memory, and on disk between loads and play sessions. As we finish a transition between scenes, this manager will also attach them to the active state tree.

For the tasks in the scene tree, we will turn to an empty `Spatial` type to attach the Task classes. I wanted to think small, and not about the seven types that CustomQuest addresses. So for now, there are three classes covering the quests to support at this phase of development:

* Complete a predetermined number of tasks until done, in any order (`StandardTask`).
* Complete a predetermined number of tasks sequentially until they're all done (`SequentialTask`).
* Collect a predetermined number of items until they are all collected (`CollectionTask`).

Each of these share common elements with the parent `Task` class depicted below:

![UML diagram outlining the classes of the greater Quest System](/img/blog/quest-system/mermaid-diagram-2023-03-05-210428-cropped.png)

And the code for the parent task, in its current implementation

{{< rawhtml >}}
<script src="https://gist.github.com/ghostfreeman/107d6c30a0053ce5b7e99438eda95da0.js"></script>
{{< /rawhtml >}}

You’ll notice for the states, I co-opted the work from Maxim Zaks, as it covers potential future states we may need. At worst, when the final project takes form, they can be dropped from the Enum safely. We do get some leeway, as we can toggle between the active task (IN_PROGRESS) and inactive in the quest manager (UNLOCKED).

Let’s shift over to what our expectations are from the player as we complete a task, in this case, one that is a `StandardTask`:

* Player is assigned a task in the quest.
* Player completes the task by means of delegating actions elsewhere in the game.
* The task is marked as completed.
* A reward is granted.
* Other actions are fired off as a result of completion.
* And its marked as done in the manager so we never reinitialize it.

All this will be managed in the child `Task` classes, which should be obvious based on their method names. As a quest completes, we will trigger them via signals or direct calls elsewhere in the script.

The `StandardTask` in its current form is open for your perusal below:

{{< rawhtml >}}
<script src="https://gist.github.com/ghostfreeman/cbf06266d0af3a5eacbef9a81844c5f1.js"></script>
{{< /rawhtml >}}

This is not the final version, and I’m many smaller tasks away from confirming my implementation. But this is where we’re at.

## Closing Links
I want to shout out the resources I found online to help guide development. Unlike a lot of my experiences solving technical problems, where I jump straight into VS Code, I did my research. I hope you find these resources helpful:

* [Asaf Benjaminov’s tutorial for Unity](https://medium.com/@asaf.j.benjaminov/implementing-a-scalable-quest-system-7f36ea4cfe22)
* [Maxim Zaks' Hackernoon article on building it around the ECS pattern](https://hackernoon.com/building-a-quest-system-cf7f1d3da132)
* [Young Ho Roh’s guest article on quest systems](https://ludogogy.co.uk/quest-systems-in-role-playing-games/)

I’ll see you next time, when we actually talk about tangible mechanics! If you have any feedback, [hit me up](https://gamedev.social/@volcanolair) on Mastodon.