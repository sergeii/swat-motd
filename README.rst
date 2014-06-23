swat-motd
%%%%%%%%%

:Version:           1.2.0
:Home page:         https://github.com/sergeii/swat-motd
:Author:            Sergei Khoroshilov <kh.sergei@gmail.com>
:License:           The MIT License (http://opensource.org/licenses/MIT)

Description
===========
MOTD *("Message of the Day")* is a SWAT 4 message queue application that is able to fetch messages from multiple online sources and display them in arbitrary order.

Dependencies
============
* `Utils <https://github.com/sergeii/swat-utils>`_ *>=1.0.0*
* `HTTP <https://github.com/sergeii/swat-http>`_ *>=1.1.0*

Installation
============

1. Install the required packages listed above in the **Dependencies** section.

2. Download compiled binaries or compile the ``MOTD`` package yourself.

   Every release is accompanied by two tar files, each containing a compiled package for a specific game version::

    swat-motd.X.Y.Z.swat4.tar.gz
    swat-motd.X.Y.Z.swat4exp.tar.gz

   with `X.Y.Z` being a package version, followed by a game version identifier::

    swat4 - SWAT 4 1.0-1.1
    swat4exp - SWAT 4: The Stetchkov Syndicate

   Please check the `releases page <https://github.com/sergeii/swat-motd/releases>`_ to get the latest stable package version appropriate to your server game version.

3. Copy contents of a tar archive into the server's ``System`` directory.

4. Open ``Swat4DedicatedServer.ini``

5. Navigate to the ``[Engine.GameEngine]`` section.

6. Append the following lines to the bottom of the section::

    ServerActors=Utils.Package
    ServerActors=HTTP.Package
    ServerActors=MOTD.Core

7. Enable the mod by placing the following section at the bottom of ``Swat4DedicatedServer.ini``::

    [MOTD.Core]
    Enabled=True

8. Set up a MOTD source with a ``URL`` propery::

    URL=http://example.com/motd/
    URL=http://example.com/motd.html
    URL=http://example.com/motd.php

   Consider the following example of a MOTD valid source URL declaration::

    URL=http://swat4stats.com/api/motd/leaderboard/vip_escapes/?initial=120

   The presented configuration will lead to displaying the following MOTD:

   .. image:: https://raw.githubusercontent.com/sergeii/swat4stats.com/master/docs/screenshots/api_leaderboard.png

   Read more about `swat4stats.com <http://swat4stats.com>`_ API `here <https://github.com/sergeii/swat4stats.com#api>`_.

If you have done everything right, contents of your ``Swat4DedicatedServer.ini`` should look similar to::

  [Engine.GameEngine]
  EnableDevTools=False
  InitialMenuClass=SwatGui.SwatMainMenu
  ...
  ServerActors=Utils.Package
  ServerActors=HTTP.Package
  ServerActors=MOTD.Core
  ...

  [MOTD.Core]
  Enabled=True
  URL=http://swat4stats.com/api/motd/leaderboard/vip_escapes/?initial=120

The server's ``System`` directory must also contain the following files::

  Utils.u
  HTTP.u
  MOTD.u

Compatibility
=============
If you have already installed either of the ``Utils`` or ``HTTP`` packages before, the ``MOTD`` dependency package order must be still maintained: ``Utils`` > ``HTTP`` > ``MOTD``

Suppose you had the following packages installed::

  ServerActors=Utils.Package
  ServerActors=HTTP.Package
  ServerActors=GS1.Listener
  ServerActors=GS2.Listener
  ServerActors=Julia.Core
  ServerActors=JuliaAdmin.Extension
  ServerActors=JuliaTracker.Extension

To install the ``MOTD`` package you would want to maintain the dependency package order::

  ServerActors=Utils.Package
  ServerActors=HTTP.Package
  ServerActors=MOTD.Core
  ServerActors=GS1.Listener
  ServerActors=GS2.Listener
  ServerActors=Julia.Core
  ServerActors=JuliaAdmin.Extension
  ServerActors=JuliaTracker.Extension


Properties
==========
The ``[JuliaTracker.Extension]`` section of ``Swat4DedicatedServer.ini`` accepts the following properties:

.. list-table::
 :widths: 15 40 10 10
 :header-rows: 1

 * - Property
   - Descripion
   - Options
   - Default
 * - Enabled
   - Enables the mod
   - True/False
   - False
 * - URL
   - URL address of a MOTD source.

     The property supports multiple URL declarations::

      URL=http://example.org/motd
      URL=http://example.org/motd/
      URL=http://example.com/motd.html
      URL=http://example.net/motd.txt
      URL=http://example.net/motd.php
      URL=http://example.net/etc/

   - URL address
   -
 * - MaxMessages
   - Total number of messages the MOTD application will hold in queue.
   - Positive integer
   - 0 (infinite)

MOTD Source Format
==================
* Every URL address declared with the ``URL`` property of ``[MOTD.Core]`` is considered a MOTD source.

* A MOTD source may contain zero, one or multiple message blocks.

* A message block must comply with the following format::

  "number (initial time)" "\t" "number (repetition time)" "\t" "player name (optional message target)" "\n" Message

  i.e. a message block consists of a block header and arbitrary number of lines that will be displayed in chat.

* A message block header is supports the following parameters:

  * **initial time** - is a level time (in seconds) the first message will be be displayed at.
  * **repetition time** - is number of seconds between message repetitions.

    A value of 0 disables message repetitions.

  * **message target** is a player name or a name pattern that denotes a message target.
  
    This parameter is optional. By default, messages are displayed to all players.

  Block header parameters are delimited with a tab charater ``\t``

* Multiple message blocks are delimited with a double newline character ``\n\n``

Consider the following MOTD source examples:

::

  60	0
  Hello World!
  This is line #2
  This is line #3
  This is line #4

::

  60	300	|CLAN|*
  This a targeted message that is displayed to all players whose name begin with |CLAN|.
  The message is displayed every 5 minutes (300 seconds) with the initial delay of 60 seconds.

  30	0
  This a public message that is displayed to all players.
  The message is displayed once at 30 seconds from a level start.

  120	600
  This a another public message.
  The message is repeated every 10 minutes.
  The initial delay is 2 minutes.

::

  45	0
  [c=FFFFFF][b]-[\b] You [c=00FF00][b]MUST[\b] [c=FFFFFF]follow the server rules.

  50	0
  [c=FFFFFF][b]-[\b] You [c=00FF00][b]MUST[\b] [c=FFFFFF]respect other players.

  55	0
  [c=FFFFFF][b]-[\b] Do [c=FF0000][b]NOT[\b] [c=FFFFFF]argue with the rules and admin decisions.

  60	0
  [c=FFFFFF][b]-[\b] Do [c=FF0000][b]NOT[\b] [c=FFFFFF]use offensive, religious and other provocative names.

  65	0
  [c=FFFFFF][b]-[\b] Do [c=FF0000][b]NOT[\b] [c=FFFFFF]insult or argue with other players.

  70	0
  [c=FFFFFF][b]-[\b] Do [c=FF0000][b]NOT[\b] [c=FFFFFF]play as a RAMBO [c=FFFFFF]and rush through the map.

  75	0
  [c=FFFFFF][b]-[\b] Use lethal force [c=FFFF00][b]ONLY[\b] [c=FFFFFF]if a suspect is aiming at you or a civilian.

  80	0
  [c=FFFFFF][b]-[\b] Do [c=FF0000][b]NOT[\b] [c=FFFFFF]hurt suspects or civilians who have surrendered.

  85	0
  [c=FFFFFF][b]-[\b] Do [c=FF0000][b]NOT[\b] [c=FFFFFF]kill or injure civilians deliberatelly.

  90	0
  [c=FFFFFF][b]-[\b] Do [c=FF0000][b]NOT[\b] [c=FFFFFF]endanger your team.

  95	0
  [c=FFFFFF][b]-[\b] You [c=00FF00][b]MUST[\b] [c=FFFFFF]use english language [c=FFFF00][b]ONLY[\b][c=FFFFFF].

  100	0
  [c=FFFFFF]Please visit our website [c=FFFF00]www.mytteam.com [c=FFFFFF]for the full list of rules and advice.

  600	1200
  [c=FFFFFF]Welcome to [b]-==MYT Co-op Svr==-[\b]
  [c=FFFFFF]Please follow the rules and and enjoy your game.

  630	1200
  [c=FFFFFF]Feel free to visit our website at [c=FFFF00]www.mytteam.com

  660	1200
  [c=FFFFFF]Join our Teamspeak server at [c=FFFF00][b]81.19.209.212:9987[\b]
  [c=FFFFFF]Get the latest client software from [c=FFFF00]www.teamspeak.com

  690	1400
  [c=FFFFFF]Visit [c=FFFF00]swat4stats.com [c=FFFFFF]to see game reports, CO-OP leaderboards and more.[b] 


See Also
========
* `swat4stats.com API <https://github.com/sergeii/swat4stats.com#api>`_