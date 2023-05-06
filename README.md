# Miner clone

All GDScript codes are made by me and licensed as CC0.  
Only the art assets are kind of stingy depending on the software, so I can't license as pure CC0 and without any sublicenses.  
Other than GDScript codes, I can only grant you permissions to create mods or build the game only.  

Credit:  
- [Cascadeur](https://cascadeur.com/)

Feature:
- [60 Fps performance mode available](https://twitter.com/JezCorden/status/1651521634262564869/photo/1)
- Optimized for 6th Gen Intel i3

This codebase guideline:
- Split the project to another independent repository when getting too big.
- You need to see the codes as your enemy. [Always implement things when you actually need them, never when you just foresee that you will\] need them.](https://en.wikipedia.org/wiki/You_aren't_gonna_need_it)
- Always assume every functions will be used for multithreading. And write it for multithreading too! If possible. One way to know if you done it right is, look at the function has at least one input and one output. If one of them does not, then it must be OOP(Object-oriented programming) and not functional programming. That mean it's possible not able to run in multithread.
- Avoid reading global variables, and avoid writing to it as if a plague.
