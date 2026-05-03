instead of iterating by each triangle to generate a structure (can be inconsistent across different triangle sizes)
Iterate by each grid space, and you can customise how many grid spaces there are
Each grid space can contain multiple empty maximal space packed until it's full, and you can create merging intersection for each pair of maximal space boxes until you got something you can do random with so you're not limited to what bounding space boxes there are, and you can put stuff anywhere
For now, you can do an unoptimised approach and just random then find if this is in the bounds of another box. It's quite pointless anyway since you'd generate this terrain once per map set.

Gui on top left in menu saying if map has loaded or not. Or just something directly in the player's lobby camera. (Retrieve map info)