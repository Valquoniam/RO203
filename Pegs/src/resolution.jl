# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using JuMP

include("generation.jl")
TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(grid::Matrix{Int64})
     
    

    # Get the size of the grid and add 4 because we need to include everything and we use n-2
    grid_size = size(grid,1)
    n = grid_size + 4
    nb_pions = 0
    
    # Get the number of initial pawns
    for i in 1:grid_size
        for j in 1:grid_size
            if grid[i,j] == 1
                nb_pions += 1
            end
        end
    end
    # Maximal number of steps = number of initial pawns
    s = Int64(nb_pions)
    
    # Create the model
    m = Model(CPLEX.Optimizer)

    # Big thanks to https://www.cs.york.ac.uk/aig/projects/implied/docs/CPAIOR03.pdf for the constraints and the variables
   
    #################################################
    # Variables
    @variable(m, M[1:n, 1:n, 1:s, 1:4], Bin)  # M[i,j,t,d]     d = 1 : North | d = 2 : South | d = 3 : East | d = 4 : West 
    @variable(m, bState[1:n, 1:n, 1:s], Bin)  # bState[i,j,t]
    #################################################
    
    #################################################
    # Constraints
    
    # East
    @constraint(m, [i in 1:n, j in 1:n, t in 1:(s-1)], M[i,j,t,3] <= bState[i,j,t])
    @constraint(m, [i in 1:(n-1), j in 1:n, t in 1:(s-1)], M[i,j,t,3] <= bState[i+1,j,t])
    @constraint(m, [i in 1:(n-2), j in 1:n, t in 1:(s-1)], M[i,j,t,3] <= (1 - bState[i+2,j,t]))

    # West
    @constraint(m, [i in 1:n, j in 1:n, t in 1:(s-1)], M[i,j,t,4] <= bState[i,j,t])
    @constraint(m, [i in 2:n, j in 1:n, t in 1:(s-1)], M[i,j,t,4] <= bState[i-1,j,t])
    @constraint(m, [i in 3:n, j in 1:n, t in 1:(s-1)], M[i,j,t,4] <= (1 - bState[i-2,j,t]))
    
    # South
    @constraint(m, [i in 1:n, j in 1:n, t in 1:(s-1)], M[i,j,t,2] <= bState[i,j,t])
    @constraint(m, [i in 1:n, j in 1:(n-1), t in 1:(s-1)], M[i,j,t,2] <= bState[i,j+1,t])
    @constraint(m, [i in 1:n, j in 1:(n-2), t in 1:(s-1)], M[i,j,t,2] <= (1 - bState[i,j+2,t]))
    
    # North
    @constraint(m, [i in 1:n, j in 1:n, t in 1:(s-1)], M[i,j,t,1] <= bState[i,j,t])
    @constraint(m, [i in 1:n, j in 2:n, t in 1:(s-1)], M[i,j,t,1] <= bState[i,j-1,t])
    @constraint(m, [i in 1:n, j in 3:n, t in 1:(s-1)], M[i,j,t,1] <= (1 - bState[i,j-2,t]))
    
    # Transitions between time-steps t & t+1
    @constraint(m, [i in 3:(n-2), j in 3:(n-2) , t in 1:(s-1)], (bState[i,j,t] - bState[i,j,t+1]) == sum(M[i,j,t,d] for d in 1:4)
                                                                                                  + M[i-1,j,t,3] - M[i-2,j,t,3]
                                                                                                  + M[i+1,j,t,4] - M[i+2,j,t,4]
                                                                                                  + M[i,j-1,t,2] - M[i,j-2,t,2]
                                                                                                  + M[i,j+1,t,1] - M[i,j+2,t,1] )

    # One move at each step
    @constraint(m, [t in 1:(s-1)], sum(M[i,j,t,d] for i in 1:n, j in 1:n, d in 1:4) <= 1) # Max one move authorized

    # Initialasizing the board
    # We will consider the out-of-board values at the end of each step
    # For now, we work in binary, so we can't make them equal to 2 (as in the grid matrix)
    # Thus, we will say they are filled holes, which can't move at all
    
    @constraint(m, [t in 1:s, i in 3:(n-2), j in 3:(n-2), d in 1:4; grid[i-2, j-2] == 2], M[i,j,t,d] == 0) # Initializing twos as not mobile
    @constraint(m, [t in 1:s, i in 3:(n-2), j in 3:(n-2); grid[i-2, j-2] == 2], bState[i,j,t] == 1)        # Initializing twos as pawns


    @constraint(m, [i in 3:(n-2), j in 3:(n-2); grid[i-2, j-2] == 0], bState[i,j,1] == 0) # Initializing zeros
    @constraint(m, [i in 3:(n-2), j in 3:(n-2); grid[i-2, j-2] == 1], bState[i,j,1] == 1) # Initializing ones

    # Initializing the two border boxes we added in order to consider every hole on the actual board
    
    # Initializing them as filled holes
    @constraint(m, [i in 1:2, j in 1:n, t in 1:s], bState[i,j,t] == 1)
    @constraint(m, [i in (n-1):n, j in 1:n, t in 1:s], bState[i,j,t] == 1)
    @constraint(m, [i in 1:n, j in 1:2, t in 1:s], bState[i,j,t] == 1)
    @constraint(m, [i in 1:n, j in (n-1):n, t in 1:s], bState[i,j,t] == 1)
    
    # These holes cannot move
    @constraint(m, [t in 1:s, i in 1:2, j in 1:n, d in 1:4], M[i,j,t,d] == 0)
    @constraint(m, [t in 1:s, i in (n-1):n, j in 1:n, d in 1:4], M[i,j,t,d] == 0)
    @constraint(m, [t in 1:s, i in 1:n, j in 1:2, d in 1:4], M[i,j,t,d] == 0)
    @constraint(m, [t in 1:s, i in 1:n, j in (n-1):n, d in 1:4], M[i,j,t,d] == 0)
    #################################################

    #################################################
    #Objective

    @objective(m, Min, sum(bState[i,j,s] for i in 3:(n-2) for j in 3:(n-2) if grid[i-2,j-2] !=2))
    #################################################

    # Limitation du temps de résolution à 10 secondes
    set_time_limit_sec(m, 60)
    
    set_silent(m)
    start = time()
    # Lancement de la résolution
    optimize!(m)

    # Récupération du statut de la résolution
    isOptimal = termination_status(m) == MOI.OPTIMAL
    solutionFound = primal_status(m) == MOI.FEASIBLE_POINT

    if solutionFound
        all_grids = Array{Matrix{Int64}}(undef, s)
        # Displaying the steps of resolution
        for t in 1:s
            grid_at_step_t = Matrix{Int64}(undef, n-4,n-4)
            for i in 3:(n-2)
                for j in 3:(n-2)
                    if grid[i-2,j-2] == 2
                        grid_at_step_t[i-2,j-2] = 2
                    elseif value.(bState[i, j, t]) == 0
                        grid_at_step_t[i-2, j-2] = 0
                    elseif value.(bState[i, j, t]) == 1
                        grid_at_step_t[i-2, j-2] = 1
                    end
                end
            end
            all_grids[t] = grid_at_step_t
            displayGrid(grid_at_step_t)
        end
        
        # Récupération de la valeur de l’objectif
        obj = Int64(JuMP.objective_value(m))
        
        # Si la solution optimale n’est pas obtenue
        if !isOptimal
            
            print("Solution non optimale\n")
            # Le solveur fournit la meilleure borne connue sur la solution optimale...
            # (i.e., meilleure objectif de la relaxation linéaire parmi tous les noeuds de branch-and-bound non élagués)
            bound = JuMP.objective_bound(m)
            # ... qu’on utilise pour évaluer la qualité de la solution
            # trouvée par le solveur en calculant le gap
            # (i.e., l’écart relatif entre l’objectif de la solution
            # trouvée et la borne supérieure).
        
            # Gap : Différence entre nombre de pions obtenu et nombre de pions optimal
            gap = Int64(round(obj - bound))

            print("Objectif pour n = ",n, " : ", obj, "\n")
            print("Gap : ", gap , " pawn(s)\n")
        else
            print("Solution optimale \n")
            print("Objectif pour n = ",n, " : ", obj, "\n")
            print("Computation time : ", round(time() - start), "s.\n")
        end
        return isOptimal, time() - start, all_grids
    else
        println("Aucun solution trouvée dans le temps imparti.")
        return -1, -1, -1
    end
end 
            
        
"""
All the functions to heuristically solve an instance
"""

# We have to figure, for every peg on the board, the list of his valid moves
# For that, let's already simplify things with a distance function between two tuple of indexes
function distance(grid::Matrix{Int64}, a::Tuple{Int, Int}, b::Tuple{Int, Int})
    
    # Return 0 if the pawns are not in the same line or column
    if ((a[1] != b[1] && a[2] != b[2] ) || grid[a...] == 2 || grid[b...] == 2)
        return 0
    # Else returns the distance    
    else
        return abs(a[1] - b[1]) + abs(a[2] - b[2])
    end
end

# distance(readInputFile("../data/instance_1.txt"), (1,1), (5,5))

# For each pegs, we calculate all the possible next boards reachable 
# Here is the function for that

function getNextGrids(grid::Matrix{Int64}, valid_indices::Vector{Tuple{Int, Int}})
    
    displayGrid(grid)

    nextgrids = Vector{Matrix{Int64}}()
    for ind in valid_indices
        # 1 - Need a peg to jump
        if grid[ind...] !=1
            continue
        end
        
        # If we have a peg, we need to evaluate his neigbors
        neighbors = (ind2 for ind2 in valid_indices if distance(grid, ind, ind2) ==1)

        for n in neighbors

            # 2 - Need a peg to jump over
            if grid[n...] !=1
                continue
            end

            # We then need the 2nd neigbour
            n2 = (n[1] - (ind[1] - n[1]), n[2] - (ind[2] - n[2]))

            # 3 - Location must me empty and in the grid
            if n2 in valid_indices && grid[n2...] == 0
  
                # Then make a copy of the current grid.
                copy_of_actual_grid = copy(grid)
                displayGrid(grid)
                # Remove the jumping peg from its current location.
                copy_of_actual_grid[ind...] = 0

                # Remove the jumped peg.
                copy_of_actual_grid[n...] = 0

                # Place the jumping peg in its new location.
                copy_of_actual_grid[n2...] = 1

                # Save the new board state.
                push!(nextgrids, copy_of_actual_grid)
            else
                continue
            end
        end
    end
    return nextgrids
end

#We need a function to sum all the pawns on the grid
function sum_grid(grid::Matrix{Int64})
    n = size(grid, 1)
    sum = 0
    for i in 1:n
        for j in 1:n
            if grid[i,j] == 1
                sum += 1
            end
        end
    end
    return sum
end

# Now let's search through all these next grids, to find the best choice
function findSolution(grid::Matrix{Int64}, valid_indices::Vector{Tuple{Int, Int}})
    
    # Need a vector containing all the grids we have to explore
    # Initially, it's just the initial grid
    grids_to_explore = [copy(grid)]
    # We will remember the road which led to the actual grid
    # Initially, this road is empty

    path_to_current_grid = [copy(grid)]  # To ensure grids_to_explore and path_to_current_grid have the same type
    pop!(path_to_current_grid )
    min = sum_grid(grid)
    counter = 0
    roof = 1000000
    # We will pop a grid from the vector of grids to explore, and add it to the path.
    while (!isempty(grids_to_explore) && counter < roof)

        current_grid = pop!(grids_to_explore)
        if sum_grid(current_grid) < min
            min = sum_grid(current_grid)
        end

        # If the current grid is not deeper, we come back one step, to find a better choice
        while (length(path_to_current_grid) > 0 && sum_grid(path_to_current_grid[end]) <= sum_grid(current_grid))
            # Use the sum as a measure of depth.
            pop!(path_to_current_grid)
        end
        
        # Adding the grid to the path
        push!(path_to_current_grid, current_grid)

        nextgrids = getNextGrids(current_grid, valid_indices)
        
        if sum_grid(current_grid) <=1
            # This is the winning state
            return path_to_current_grid
        else
            # If there are moves available from current_state,
            # push them to states (recursing down)
            append!(grids_to_explore, nextgrids)
        end
        counter += 1
    end

    println("Minimum number of pegs found : $min \n")

    grids_to_explore = [copy(grid)]
    path_to_current_grid = [copy(grid)]  # To ensure grids_to_explore and path_to_current_grid have the same type
    pop!(path_to_current_grid )
    counter = 0
    # We will pop a grid from the vector of grids to explore, and add it to the path.
    while (!isempty(grids_to_explore) && counter < roof)

        current_grid = pop!(grids_to_explore)

        # If the current grid is not deeper, we come back one step, to find a better choice
        while (length(path_to_current_grid) > 0 && sum_grid(path_to_current_grid[end]) <= sum_grid(current_grid))
            # Use the sum as a measure of depth.
            pop!(path_to_current_grid)
        end
        
        # Adding the grid to the path
        push!(path_to_current_grid, current_grid)

        nextgrids = getNextGrids(current_grid, valid_indices)
        
        if sum_grid(current_grid) == min
            # This is the winning state
            return path_to_current_grid
        else
            # If there are moves available from current_state,
            # push them to states (recursing down)
            append!(grids_to_explore, nextgrids)
        end
        counter += 1
    end
    return false
end

function heuristicSolve(grid::Matrix{Int64})
    
    start = time()
    # Basic informations
    valid_indices = Vector{Tuple{Int, Int}}()
    grid_size = size(grid,1)

    for i in 1:grid_size
        for j in 1:grid_size
            if grid[i,j] != 2
                push!(valid_indices, (i, j))
            end
        end
    end 
    
    all_grids = findSolution(grid, valid_indices)
    if all_grids == false
        println("No solutions found in 1000 iterations")
        return false, -1, -1
    else
        println("Found the following solution:")
        for grid in all_grids
            println(displayGrid(grid))
        end
    end    
    return true, time() - start, all_grids
end   

# heuristicSolve(readInputFile("../data/instance_3.txt"))

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        instance = readInputFile(dataFolder * file)
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime, all_grids = cplexSolve(instance)
                    n = size(all_grids,1)

                    if isOptimal == -1
                        println(fout, "Pas de solution trouvé dans le temps imparti")
                    else
                        println(fout, "solveTime = ", resolutionTime, "\n") 
                        println(fout, "isOptimal = ", isOptimal, "\n")
                        for i in 1:n
                            println(fout, "Etape n°$i : \n")
                            grid_string = displayGrid(all_grids[i])
                            println(fout,grid_string)
                        end
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime, all_grids = heuristicSolve(instance)
                    n = size(all_grids,1)

                    if isOptimal == -1
                        println(fout, "Pas de solution trouvé dans le temps imparti")
                    else
                        println(fout, "solveTime = ", resolutionTime, "\n") 
                        println(fout, "isOptimal = ", isOptimal, "\n")
                        for i in 1:n
                            println(fout, "Etape n°$i : \n")
                            grid_string = displayGrid(all_grids[i])
                            println(fout,grid_string)
                        end
                    end
                end
                close(fout)
            end
        end 
    end 
end
