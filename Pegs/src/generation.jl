# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")
using JuMP
"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""

################## GENERATING AN INSTANCE #####################################

function generateInstance(n::Int64, density::Float64)
    
    # Grid creation
    grid = Matrix{Int64}(undef, n, n)

    # Setting multiple type of boards
    type_of_boards = ["crux", "square", "random"]
    
    # Selecting one of them randomly
    board_type = type_of_boards[rand(1:length(type_of_boards))]
    println(board_type)
    size_of_corners = 0
    # 1st case : crux
    if board_type == "crux"
        
        # Considering corners to remove (here, it means writing a 2 in the correspondant cases)
        size_of_corners = 2 + (n-7) ÷ 3
    end

    # 2nd case : square : do nothing

    for i in 1:n
        for j in 1:n
            # Corners
            if (i <= size_of_corners || i > n -size_of_corners) && (j <= size_of_corners || j > n - size_of_corners)
                grid[i,j] = 2
            else
                if rand() < density
                    grid[i,j] = 1
                else
                    grid[i,j] = 0
                end
            end

            # 3rd case : random board
            # We start as a square board, but we randomly add "off-the-grid" points. Here : 1 chance out of 3 to be off-the-grid
            if board_type == "random"
                is_a_2 = rand(1:3)
                if is_a_2 == 1
                    grid[i,j] = 2
                end
            end
        end
    end
    return grid
end

##########################################################################

############################ GENERATING THE DATASET ######################

""" 
Generate all the instances
"""

function generateDataSet(set_size::Int64)
    for i in 2:set_size

        # Size of the grid between 5 and 10 for computation time obvious reasons
        n = rand(5:10)
        
        # Random density
        density = rand()

        # Generation of the grid
        grid = generateInstance(n,density)

        # Creation of the instance file
        fout = open("../data/instance_$i.txt", "w")

        # Writing in the instance file
        for i in 1:n
            for j in 1:n
                if j != n
                    write(fout,string(grid[i,j]))
                    write(fout," ")
                else
                    write(fout,string(grid[i,j]))
                    write(fout,"\n")
                end
            end
        end
    close(fout)
    end
end

#########################################################################


