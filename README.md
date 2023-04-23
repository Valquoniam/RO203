# RO203

RO203 Project in collab w/ Axel Dumont - Solving Linear Programs : "Pegs" & "Towers

In this repository, you will find our work on solving Pegs and Tower games using cplex.

## Game n°1 : Peg Solitaire

 !["Pegs Board"](/images/Pegs.png)

Available commands :

- `generateDataSet(n)` create n instances of the game, with multiple sizes and density.

- `displayAllGrids()` displays all the instances in a more readable way than the .txt form.

- `solveDataSet()`solves all the instances and displays the steps.

- `performanceDiagram("../perfs_peg.png")` show a graph of the computation time for the optimal solves.

- `resultArray("../perfs_peg.tex)` creates a .tex displaying the computation time and which solves are optimal.


## Game n°2 : Towers

!["Towers Board"](/images/Towers.png)

Available commands :

- `performanceDiagram("../perfs_peg.png")` show a graph of the computation time for the optimal solves.

- `resultArray("../perfs_peg.tex)` creates a .tex displaying the computation time and which solves are optimal.
