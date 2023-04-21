# This file contains functions related to reading, writing and displaying a grid and experimental results
using JuMP
using Plots
import GR

########################## READ DATA FILE ##########################
"""
Read an instance from an input file

- Argument:
inputFile: path of the input file
"""
function readInputFile(inputFile::String)

    # Open the input file
    datafile = open(inputFile)

    data = readlines(datafile)
    close(datafile)

    # Get info
    n_lines = size(data, 1)

    # Initialize our board
    x = Matrix{Int64}(undef, n_lines, n_lines)
    # For each line of the input file, we read the value and copy it to x
    for i in 1:n_lines
        list_line = split(data[i]," ") # Split at spaces
        for j in 1:n_lines
            int_j = parse(Int64,list_line[j])
            x[i,j] = int_j       
        end
    end
    return x
end

#####################################################################

########################## SHOW THE BOARD ###########################

function displayBoard(x::Matrix{Int64})

    println("\n------------------")

    n_lines = size(x, 1)

    for i in 1:n_lines
        for j in 1:n_lines
            if x[i, j] == 0
                print("o")
            elseif x[i, j] == 1
                print("■")
            elseif x[i, j] == 2
                print(" ")
            end
        end 
        println()
    end
    println()
    println(" pegs: ", sum(x) - 32 ,)
    println("\n------------------")
end

###################################################################