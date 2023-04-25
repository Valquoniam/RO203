# RO203

RO203 Project in collab w/ Axel Dumont - Solving Linear Programs : "Pegs" & "Towers

In this repository, you will find our work on solving Pegs and Tower games using cplex.

## Game n°1 : Peg Solitaire

 !["Pegs Board"](/images/Pegs.png)

To include the program in Julia, you have to enter the command `include("resolution.jl")` in the directory _Pegs/src_
or `include("/Pegs/src/resolution.jl")` if you're in the main directory.

Then, you will have the available commands :

- `generateDataSet(n)` create n instances of the game, with multiple sizes, densities and forms.

- `displayAllGrids()` displays all the instances in a more readable way than the .txt form.

- `dislayGrid("../data/instance_i.txt")` displays only the selected grid.

- `solveDataSet()`solves all the instances and displays the steps.

- `performanceDiagram("../perfs_peg.png")` show a graph of the computation time for the optimal solves.

- `resultArray("../perfs_peg.tex)` creates a .tex displaying the computation time and which solves are optimal.

## Game n°2 : Towers

!["Towers Board"](/images/Towers.png)

Available commands :

- `performanceDiagram("../perfs_peg.png")` show a graph of the computation time for the optimal solves.

- `resultArray("../perfs_peg.tex)` creates a .tex displaying the computation time and which solves are optimal.
