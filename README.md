# Description

Adds a new button to the vendor UI.  One click to sell all grey items. Right
click on this button for settings.  Can change threshold (eg sell all greens)
and can set to sell crafting materials.


# Credits 

Special Thanks to

Aiiane @ irc.freenode.net #WARUIDev
Helped me tons with my initial questions and getting my head around LUA addons. Also used
an initial bit of her Yabber code to start me off. Also helped me debug the addon before 
Preview Weekend with typos, helping fix the code up, and helping finally figure out the
problems we have had with the button. She is awesome. Thanks so much!
Go check out her addons on war.curse.com

smcn @ irc.freenode.net #WARUIDev
Showing me how to properly setup the button and inject it.

Kanedacopr @ curseforge.com
For helping me out with how to get seperate professions working.

Sniperumm @ irc.freenode.net #WARUIDEV
For helping me with the listbox and making an entire example project just to show me how.

# Changelog
## 15-Nov-2018 by Quillog

Added Magus Discs to exceptions
Added Manticore and Griffon mounts to exceptions
Added "Guild Recall Scroll" (destro) to exceptions  --- might not work for order, need item IDs to add other scrolls

## 2009-08-29  Daegalus  <Daegalus>

[f567ebbfc39b] [1.2.1]
* JunkDump.lua:

Fixed: If IgnoreProfessionRarity is off, JD was not honoring MaxProfessionSkill thresholds.


