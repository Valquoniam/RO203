# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using JuMP

include("generation.jl")
TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(grid::Matrix{Int64})
     
    start = time()

    # Get the size of the grid and add 4 because we need to include everything and we use n-2
    grid_size = size(grid,1)
    n = grid_size + 4

    # Get our parameters
    nb_cases = grid_size^2 - 4*(floor(grid_size/3))^2
    nb_cases_out = grid_size^2 - nb_cases
    s = Int64(sum(grid) - 2*nb_cases_out)
    
    # Create the model
    m = Model(CPLEX.Optimizer)

    # Big thanks to https://www.cs.york.ac.uk/aig/projects/implied/docs/CPAIOR03.pdf for the constraints and the variable
   
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
    @constraint(m, [t in 1:(s-1)], sum(M[i,j,t,d] for i in 1:n, j in 1:n, d in 1:4) <= 1) # Un seul mouvement par étape est autorisé, tous pions confondus # <= 1 si le jeu n'est pas forcément résolvable


    # Adding a constraint for security : at each step, the number of holes has to increase by 1
    # @constraint(m, [t in 2:(s-1)], sum(bState[i,j,t] for i in 1:n for j in 1:n) == sum(bState[i,j,t-1] for i in 1:n for j in 1:n) -1)

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
    set_time_limit_sec(m, 20)
    
    set_silent(m)
    
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
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
end 

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

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
                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end
                
                if isOptimal == -1
                    println(fout, "Pas de solution trouvé dans le temps imparti")
                else
                    println(fout, "solveTime = ", resolutionTime, " s.\n") 
                    println(fout, "isOptimal = ", isOptimal, "\n")
                    for i in 1:n
                        println(fout, "Etape n°$i : \n")
                        grid_string = displayGrid(all_grids[i])
                        println(fout,grid_string)
                    end
                end
                close(fout)
            end
        end 
    end 
end
