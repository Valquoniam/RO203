# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(haut, bas, gauche, droite)

    n = size(haut, 1)

    # Create the model
    m = Model(CPLEX.Optimizer)
    set_time_limit_sec(m, 120.0)
    # Start a chronometer
    start = time()

    @variable(m,x[1:n,1:n,1:n],Bin) # ==1 ssi (i,j) contient k
	@variable(m,y_h[1:n,1:n],Bin)	# ==1 ssi (i,j) visible depuis le haut
	@variable(m,y_b[1:n,1:n],Bin)	# ==1 ssi (i,j) visible depuis le bas
	@variable(m,y_g[1:n,1:n],Bin)	# ==1 ssi (i,j) visible depuis la gauche
	@variable(m,y_d[1:n,1:n],Bin)	# ==1 ssi (i,j) visible depuis la droite

    # Une seule valeur par case
	@constraint(m, [i in 1:n, j in 1:n], sum(x[i,j,k] for k in 1:n) == 1)

	# Chiffres différents sur une ligne
	@constraint(m, [i in 1:n, k in 1:n], sum(x[i,j,k] for j in 1:n) == 1)

	# Chiffres différents sur une colonne
	@constraint(m, [j in 1:n, k in 1:n], sum(x[i,j,k] for i in 1:n) == 1)

    # Haut
	@constraint(m, [j in 1:n], sum(y_h[i,j] for i in 1:n) == haut[j])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], y_h[i,j]<=1-sum(x[i_,j,k_] for i_ in 1:i-1 for k_ in k:n)/n+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], y_h[i,j]>=1-sum(x[i_,j,k_] for i_ in 1:i-1 for k_ in k:n)-n*(1-x[i,j,k]))

    # Bas
	@constraint(m, [j in 1:n], sum(y_b[i,j] for i in 1:n) == bas[j])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], y_b[i,j]<=1-sum(x[i_,j,k_] for i_ in i+1:n for k_ in k:n)/n+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], y_b[i,j]>=1-sum(x[i_,j,k_] for i_ in i+1:n for k_ in k:n)-n*(1-x[i,j,k]))

    # gauche
	@constraint(m, [i in 1:n], sum(y_g[i,j] for j in 1:n) == gauche[i])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], y_g[i,j]<=1-sum(x[i,j_,k_] for j_ in 1:j-1 for k_ in k:n)/n+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], y_g[i,j]>=1-sum(x[i,j_,k_] for j_ in 1:j-1 for k_ in k:n)-n*(1-x[i,j,k]))

    # droite
	@constraint(m, [i in 1:n], sum(y_d[i,j] for j in 1:n) == droite[i])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], y_d[i,j]<=1-sum(x[i,j_,k_] for j_ in j+1:n for k_ in k:n)/n+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], y_d[i,j]>=1-sum(x[i,j_,k_] for j_ in j+1:n for k_ in k:n)-n*(1-x[i,j,k]))

    @objective(m, Max, sum(x[1, 1, k] for k in 1:n))

    # Solve the model
    optimize!(m)


    # Return:
    # 1 - x(i,j,k) for all i, j, k
    # 2 - true if an optimum is found
    # 3 - the resolution time
    return x, JuMP.primal_status(m) == JuMP.MOI.FEASIBLE_POINT, time() - start
    
end

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""

function solveDataSet()

    dataFolder = "data/"
    resFolder = "res/"

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
        haut, bas, gauche, droite = readInputFile(dataFolder * file)

        outputFile = resolutionFolder[1] * "/" * file
        print(outputFile)

        # If the instance has not already been solved by this method
        if !isfile(outputFile)

            fout = open(outputFile, "w") 


            resolutionTime = -1
            isOptimal = false
                    
            # Solve it and get the results
            x, isOptimal, resolutionTime = cplexSolve(haut, bas, gauche, droite)

            # If a solution is found, write it
            if isOptimal

                writeSolution(fout, x) 
               
            end
        
            println(fout, "solveTime = ", resolutionTime) 
            println(fout, "isOptimal = ", isOptimal)
       
            close(fout)
      
        end

            
        # Display the results obtained with the method on the current instance
        include(outputFile)
        println(resolutionMethod[1], " optimal: ", isOptimal)
        println(resolutionMethod[1], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")         
    end 
end
