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
        
    # The size of the grid has to be 7 +k*3
    @assert mod(n-7,3) == 0 "Incorrect size"

    # Grid creation
    grid = Matrix{Int64}(undef, n, n)

    # Considering corners to remove (here, it means writing a 2 in the correspondant cases)
    size_of_corners = 2 + (n-7) ÷ 3
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

        # Size of the grid between 7 and 16 for computation time obvious reasons
        n = Int64(7 + 3* ceil(3*rand()))
        
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


