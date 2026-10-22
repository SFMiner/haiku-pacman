# Credits

## Maze layout: Classic mode
`data/maze_classic.txt` is a tile-by-tile copy of the layout in
[bobeff/pacman](https://github.com/bobeff/pacman) (`assets/maze.txt`), converted to this project's
format: energizers `o`, ghost door `-`, and start markers `P` (Pac-Man), `B` (Blinky), `I` (Inky),
`K` (Pinky), `C` (Clyde), `F` (fruit). The source is licensed GPL-3.0, and this project is GPL-3.0
as well (see `LICENSE`).

The layout matches the arcade board's counts: 28 × 31 tiles, 240 dots, 4 energizers.

## Maze layout: Default mode
`data/maze_default.txt` is original. It was generated once with a recursive-backtracker maze (seed 1),
then loops were added, the tunnel row and ghost house were placed by hand, and the start markers were
added. It is not copied from any other source.

## Game design
Original. Working title "Haiku Pac". Pac-Man is a trademark of Bandai Namco, and this project does
not use its name, art or sound.
