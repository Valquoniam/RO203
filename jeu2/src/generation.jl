# This file contains methods to generate a data set of instances (i.e., sudoku grids)

include("io.jl")
"""
Generate an (n+2)*(n+2) grid with a given density

Argument
- n: size of the grid
"""
function generateInstance(n::Int64)
    grid = Array{Int64}(zeros(n,n))
    filled_slots = 0
    while filled_slots < n*n
        i = Int(floor(filled_slots/n)+1)
        j = rem(filled_slots,n)+1
        tested = Array{Int64}(zeros(0))
        test = ceil.(Int, n*rand())
        push!(tested,test)

        while !IsOkay(grid, i, j, test) && size(tested,1) < n
            test = ceil.(Int, n*rand())
            if !(test in tested)
                push!(tested,test)
            end
        end
        grid[i, j] = test
        filled_slots += 1

        if size(tested,1) >= n
			grid = Array{Int64}(zeros(n,n))
			filled_slots = 0
		end
    end

    
	haut = Array{Int64}(zeros(n))
    bas = Array{Int64}(zeros(n))
    gauche = Array{Int64}(zeros(n))
    droite = Array{Int64}(zeros(n))

	for j in 1:n
		for i in 1:n
			if isVisible(grid,i,j,"haut")
				haut[j]+=1
			end
            if isVisible(grid,i,j,"bas")
                bas[j]+=1
            end
            if isVisible(grid,i,j,"gauche")
                gauche[i]+=1
            end
            if isVisible(grid,i,j,"droite")
                droite[i]+=1
            end
        end
    end
		
    return haut, bas, gauche, droite
end


function IsOkay(grid, i, j, value)
    for i2 in 1:size(grid, 1)
        if grid[i2, j] == value
            return false
        end
    end
    for j2 in 1:size(grid, 1)
        if grid[i, j2] == value
            return false
        end
    end
    return true
end

function isVisible(t,i,j,cote)
	if cote == "haut"
		for i_ in 1:i
			if t[i_,j] > t[i,j]
				return false
			end
		end
	elseif cote == "bas"
		for i_ in i:size(t,1)
			if t[i_,j] > t[i,j]
				return false
			end
		end
	elseif cote == "gauche"
		for j_ in 1:j
			if t[i,j_] > t[i,j]
				return false
			end
		end
	elseif cote == "droite"
		for j_ in j:size(t,1)
			if t[i,j_] > t[i,j]
				return false
			end
		end
	end
	return true	
end

"""
Generate all the instances
Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # For each grid size considered
    for size in [5,6,7,8,9]

		# Generate 10 instances
		for instance in 1:2
			fileName = "../data/instance_t" * string(size) * "_" * string(instance) * ".txt"

			if !isfile(fileName)
				println("-- Generating file " * fileName)
                haut, bas, gauche, droite = generateInstance(size)
				saveInstance(haut, bas, gauche, droite, fileName)
			end 
		end
	end
end
