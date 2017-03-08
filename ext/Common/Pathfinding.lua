--[[####	Pathfinding Lib		####

		Version: 	0.01
		Author:		Maxxxel
		
		Ask if you want to use functions from here without using the Lib.
--]]

--[[####	Requirements 	####
	
		MapPositionGOS: To check for Collision
		BinaryHeap:		To Sort and Get the pathnodes as fast as possible
--]]

require 'MapPositionGOS'
local BH = require 'BinaryHeap'

--[[####	Local Variables 	####
--]]

local insert, abs, min, max, sqrt, floor = table.insert, math.abs, math.min, math.max, math.sqrt, math.floor
local sqrt2 = sqrt(2)

--[[#### 	Menu 	####

		Settings
			Offset		-> Change the Offset, the smaller the more precise but needs performance
			weighting 	-> Change the dynamig weighting, the higher the less nodes are expanded so FPS friendlier but not always shortest path
--]]
	
	_G.Pathfinding = MenuElement({			id = "Pathfinding", name = "Pathfinding", 	type = MENU})
	_G.Pathfinding:MenuElement({			id = "Settings", 	name = "Settings", 		type = MENU})
	_G.Pathfinding.Settings:MenuElement({	id = "Offset", 		name = "1. Offset (default 75) ", 				value = 75, 	min = 25, 	max = 100, 	step = 1})
	_G.Pathfinding.Settings:MenuElement({	id = "weighting", 	name = "2. Dynamic Weighting (default 1.5) ", 	value = 1.5, 	min = 1, 	max = 2, 	step = .1})
	_G.Pathfinding.Settings:MenuElement({	id = "Penalty", 	name = "3. Strict Theta Penalty (default 50) ", value = 50, 	min = 0, 	max = 100, 	step = 1})

--[[####	Core Class 	####

		:__init() 						-> Starts the Core class and sets important variables for later use
		:Round(num, fac)				-> Rounds a given number with given fac
		:MakeNode(x, y, parent, g) 		-> Creates a node with given x, y, parent and g value
		:Convert(Point) 				-> Converts a Poto a Node with x and y rounded to use our grid
		:GetNeighborsVis(node, visited) -> Returns all vissible Neighbors of a given node, that arent in visited already
		:lineOfSight(node, neighbor) 	-> Returns true if node and neighbor got a line of sight without obstacles inbetween
		:isWalkable(...) 				-> Returns true if given point/node/etc. is walkable
		:GetDistance(PosA, PosB) 		-> Returns the straight distance between two given Positions
--]]

class 'Core'

	function Core:__init()
		local v = _G.Pathfinding.Settings.Offset:Value()
		self.Offset = {
			[1] = {x = 0, 	y = v}, 	--Top
			[2] = {x = v, 	y = 0}, 	--Right
			[3] = {x = 0, 	y = -v}, 	--Down
			[4] = {x = -v, 	y = 0},		--Left
			[5] = {x = v, 	y = v}, 	--TopRight
			[6] = {x = -v, 	y = v},		--TopLeft
			[7] = {x = v, 	y = -v}, 	--DownRight
			[8] = {x = -v,	y = -v} 	--DownLeft
		}
		self.v = v
	end

	function Core:Round(num, idp)
		local mult = 10^(idp or 0)
		return floor(num * mult + 0.5) / mult
	end

	function Core:myRound(x, base)
		return base * self:Round(x / base)
	end

	function Core:MakeNode(x, y, parent, g)
		local id = tostring(x) .. tostring(y)

		return {x = x, y = y, id = id, parent = parent, g = g}
	end

	function Core:Convert(Point)
		local x = self:myRound(Point.x, self.v)
		local y = self:myRound(Point.z, self.v)
		local Node = self:MakeNode(x, y)

		return Node 
	end

	function Core:GetNeighborsVis(node, visited)
		local Neighbors = {}

		for i = 1, #self.Offset do
			local order = self.Offset[i]
			local x, y = node.x + order.x, node.y + order.y
			local Neighbor = self:MakeNode(x, y)
			local Check = visited[Neighbor.id]

			if self:isWalkable(Neighbor) and not Check then
				insert(Neighbors, Neighbor)
			elseif Check then
				insert(Neighbors, Check)
			end
		end

		return Neighbors
	end

	function Core:lineOfSight(node, neighbor)
		local x0, x1, y0, y1 = node.x, neighbor.x, node.y, neighbor.y
		local sx,sy,dx,dy

		if x0 < x1 then
			sx = self.v
			dx = x1 - x0
		else
			sx = -self.v
			dx = x0 - x1
		end

		if y0 < y1 then
			sy = self.v
			dy = y1 - y0
		else
			sy = -self.v
			dy = y0 - y1
		end

		local err, e2 = dx-dy, nil

		if not Core:isWalkable({x = x0, y = 0, z = y0}) then return false end

		while not(x0 == x1 and y0 == y1) do
			e2 = err + err
			if e2 > -dy then
				err = err - dy
				x0  = x0 + sx
			end
			if e2 < dx then
				err = err + dx
				y0  = y0 + sy
			end

			if not Core:isWalkable({x = x0, y = 0, z = y0}) then return false end
		end

		return true
	end

	function Core:isWalkable(...)
		local wall = MapPosition:inWall(Point(...)) 
		return not wall
	end

	function Core:GetDistance(PosA, PosB)
		local value = sqrt((PosA.x - PosB.x) * (PosA.x - PosB.x) + (PosA.y - PosB.y) * (PosA.y - PosB.y))

		return value
	end

	function Core:Smooth(_)
		if #_ == 2 then return _ end

		local Path = {}
		local from = 1
		local to = #_
		local toAdd = 0

		insert(Path, _[from])

		while from ~= to do
			for i = from, to do
				local Active = _[i]

				for j = from + 1, to do
					local Next = _[j]

					if Next.id == Active.id then
						goto Return
					end

					if self:lineOfSight(Active, Next) then
						toAdd = j
					end
				end

				if toAdd ~= 0 then
					from = toAdd
					insert(Path, _[toAdd])
					toAdd = 0
					break
				end
			end
		end

		insert(Path, _[to])

		::Return::

		return Path
	end

	function Core:BuildPath(node)
		local Path = {}

		while node.id ~= node.parent.id do
			insert(Path, node)
			node = node.parent
		end

		insert(Path, node.parent)
		--Path = self:Smooth(Path)

		return Path		
	end

	function Core:tryTaut(x1, y1, x2, y2, x3, y3)
        if x1 < x2 then
            if y1 < y2 then
           		local ret = self:isTautFromBottomLeft(x1, y1, x2, y2, x3, y3)
                return ret
            elseif y2 < y1 then
            	local ret = self:isTautFromTopLeft(x1, y1, x2, y2, x3, y3)
                return ret
            else
            	local ret = self:isTautFromLeft(x1, y1, x2, y2, x3, y3)
                return ret
            end
        elseif x2 < x1 then
            if y1 < y2 then
                return self:isTautFromBottomRight(x1, y1, x2, y2, x3, y3)
            elseif y2 < y1 then
                return self:isTautFromTopRight(x1, y1, x2, y2, x3, y3)
            else
                return self:isTautFromRight(x1, y1, x2, y2, x3, y3)
            end
        else
            if y1 < y2 then
                return self:isTautFromBottom(x1, y1, x2, y2, x3, y3)
            elseif y2 < y1 then
                return self:isTautFromTop(x1, y1, x2, y2, x3, y3)
            else
                print("ERROR IN TRYTAUT")
            end
        end
    end

    function Core:isTautFromBottomLeft(x1, y1, x2, y2, x3, y3)
        if x3 < x2 or y3 < y2 then return false end
        
        local compareGradients = (y2 - y1) * (x3 - x2) - (y3 - y2) * (x2 - x1)
        if compareGradients < 0 then
            return not self:isWalkable(x2 + Core.v, y2)
        elseif compareGradients > 0 then
            return not self:isWalkable(x2, y2 + Core.v)
        else
            return true
        end
    end
    
    function Core:isTautFromTopLeft(x1, y1, x2, y2, x3, y3)
        if x3 < x2 or y3 > y2 then return false end
        
        local compareGradients = (y2 - y1) * (x3 - x2) - (y3 - y2) * (x2 - x1)
        if compareGradients < 0 then
            return not self:isWalkable(x2, y2 - Core.v)
        elseif compareGradients > 0 then
            return not self:isWalkable(x2 + Core.v, y2)
        else
            return true
        end
    end
    
    function Core:isTautFromBottomRight(x1, y1, x2, y2, x3, y3)
        if x3 > x2 or y3 < y2 then return false end

        local compareGradients = (y2 - y1) * (x3 - x2) - (y3 - y2) * (x2 - x1)
        if compareGradients < 0 then
            return not self:isWalkable(x2, y2 + Core.v)
        elseif compareGradients > 0 then
            return not self:isWalkable(x2 - Core.v, y2)
        else
            return true
        end
    end

    function Core:isTautFromTopRight(x1, y1, x2, y2, x3, y3)
        if x3 > x2 or y3 > y2 then return false end
        
        local compareGradients = (y2 - y1) * (x3 - x2) - (y3 - y2) * (x2 - x1)
        if compareGradients < 0 then
            return not self:isWalkable(x2 - Core.v, y2)
        elseif compareGradients > 0 then
            return not self:isWalkable(x2, y2 - Core.v)
        else
            return true
        end
    end
    
    function Core:isTautFromLeft(x1, y1, x2, y2, x3, y3)
        if x3 < x2 then return false end
        
        local dy = y3 - y2
        if dy < 0 then
            return not self:isWalkable(x2 - Core.v, y2 - Core.v)
        elseif dy > 0 then
            return not self:isWalkable(x2 - Core.v, y2)
        else
            return true
        end
    end

    function Core:isTautFromRight(x1, y1, x2, y2, x3, y3)
        if x3 > x2 then return false end
        
        local dy = y3 - y2
        if dy < 0 then
            return not self:isWalkable(x2, y2 - Core.v)
        elseif dy > 0 then
            return not self:isWalkable(x2, y2)
        else
            return true
        end
    end

    function Core:isTautFromBottom(x1, y1, x2, y2, x3, y3)
        if y3 < y2 then return false end
        
        local dx = x3 - x2
        if dx < 0 then
            return not self:isWalkable(x2 - Core.v, y2 - Core.v)
        elseif dx > 0 then
            return not self:isWalkable(x2, y2 - Core.v)
        else
            return true
        end
    end

    function Core:isTautFromTop(x1, y1, x2, y2, x3, y3)
        if y3 > y2 then return false end
        
        local dx = x3 - x2
        if dx < 0 then
            return not self:isWalkable(x2 - Core.v, y2)
        elseif dx > 0 then
            return not self:isWalkable(x2, y2)
        else
            return true
        end
    end

--[[#### 	Heuristic Class 	####
--]]

class 'Heuristic'
	
	function Heuristic:Manhattan(a, b)
		local dx = abs(a.x - b.x)
		local dy = abs(a.y - b.y)

		return Core:Round(dx + dy)
	end

	function Heuristic:Octile(a, b, c, d)
		local dx = not c and abs(a.x - b.x) or abs(a - b)
		local dy = not c and abs(a.y - b.y) or abs(c - d)

		return Round((dx + dy) + (sqrt2 - 2) * min(dx, dy))
	end

	function Heuristic:Straight(a, b)
		return Core:GetDistance(a, b)
	end

--[[####	Theta Algorithm 	####
--]]

class 'Theta'
	
	function Theta:FindPath(Start, Finish)
		Core:__init()

		local Path = {}
		local startNode, endNode = Core:Convert(Start), Core:Convert(Finish)
		self.dyn = _G.Pathfinding.Settings.weighting:Value()

		self:Initalize(startNode, endNode)
		Path = Core:isWalkable(endNode) and self:ComputePath() or {}

		return Path
	end

	function Theta:InitNode(node)
		local Node = {}
		Node = node
		Node.g = 999999
		Node.parent = nil

		return Node
	end

	function Theta:Initalize(startNode, endNode)
		self.openList = BH()
		self.closed = {}
		self.start = self:InitNode(startNode)
		self.finish = self:InitNode(endNode)
		self.createdNeighbors = {}
		--Declare start
		self.start.parent = self.start
		self.start.g = 0
		self.start.h = Heuristic:Straight(self.start, self.finish)
		self.start.f = self.start.g + self.start.h
		--Insert start
		self.openList:push(self.start)
	end

	function Theta:ComputeCost(C, N)
		if Core:lineOfSight(C.parent, N) then
			--Path 2
			local gValue = C.parent.g + Heuristic:Straight(C.parent, N)
			if gValue < N.g then
				N.parent = C.parent
				N.g = gValue
			end
		else
			--Path 1
			local gValue = C.g + Heuristic:Straight(C, N)
			if gValue < N.g then
				N.parent = C
				N.g = gValue
			end
		end
	end

	function Theta:UpdateNode(C, N)
		local oldG = N.g
		self:ComputeCost(C, N)

		if N.g < oldG then
			if N.isOpen then
				self.openList:heapify(N)
			else
				local hValue = Heuristic:Straight(N, self.finish)
				N.f = N.g + hValue
				N.isOpen = true
				self.openList:push(N)
			end
		end
	end

	function Theta:ComputePath()
		local overheat = 0

		while not self.openList:empty() and overheat < 25000 do
			local currentNode = self.openList:pop()

			--Early Exit
			if currentNode.id == self.finish.id then
				return Core:BuildPath(currentNode)
			end

			self.closed[currentNode.id] = true

			local Neighbors = Core:GetNeighborsVis(currentNode, self.createdNeighbors)
			for i = 1, #Neighbors do
				local Neighbor = Neighbors[i]

				self.createdNeighbors[Neighbor.id] = Neighbor

				if not self.closed[Neighbor.id] then
					if not Neighbor.g then
						self:InitNode(Neighbor)
						Neighbor.parent = currentNode
					end

					self:UpdateNode(currentNode, Neighbor, dyn)
				end
			end

			overheat = overheat + 1
		end

		print("OVERHEAT OF PATHFINDING")
		--Fail return
		return {}
	end

--[[####	LazyTheta Algorithm 	####
--]]

class 'LazyTheta'
	
	function LazyTheta:FindPath(Start, Finish)
		Core:__init()

		local Path = {}
		local startNode, endNode = Core:Convert(Start), Core:Convert(Finish)
		local dyn = _G.Pathfinding.Settings.weighting:Value()

		self:Initalize(startNode, endNode)
		Path = Core:isWalkable(endNode) and self:ComputePath(dyn) or {}

		return Path
	end

	function LazyTheta:InitNode(node, parent)
		local Node = {}
		Node = node
		Node.g = 999999
		--Node.parent = parent

		return Node
	end

	function LazyTheta:Initalize(startNode, endNode)
		self.openList = BH()
		self.closed = {}
		self.start = self:InitNode(startNode)
		self.finish = self:InitNode(endNode)
		self.createdNeighbors = {}
		--Declare start
		self.start.isOpen = true
		self.start.parent = self.start
		self.start.g = 0
		self.start.h = Heuristic:Straight(self.start, self.finish)
		self.start.f = self.start.g + self.start.h
		--Insert start
		self.openList:push(self.start)
	end

	function LazyTheta:ComputeCost(C, N)
		local _ = C.parent.g + Heuristic:Straight(C.parent, N)
		if _ < N.g then
			N.parent = C.parent
			N.g = _
		end
	end

	function LazyTheta:UpdateNode(C, N, dyn)
		local oldG = N.g
		self:ComputeCost(C, N)

		if N.g < oldG then
			if N.isOpen then
				self.openList:heapify(N)
			else
				local hValue = Heuristic:Straight(N, self.finish)
				N.f = N.g + hValue * dyn
				N.isOpen = true
				self.openList:push(N)
			end
		end
	end

	function LazyTheta:BuildPath(node)
		local Path = {}

		while true do
			insert(Path, node)
			node = node.parent

			if node.id == self.start.id then 
				insert(Path, node)
				break 
			end
		end

		return Path
	end

	function LazyTheta:SetVertex(node)
		if not Core:lineOfSight(node, node.parent) then
			--Path 1
			local minValue = 999999
			local retValue = node.parent

			local Neighbors = Core:GetNeighborsVis(node, {})
			for i = 1, #Neighbors do
				local Neighbor = Neighbors[i]
				if self.closed[Neighbor.id] then
					Neighbor = self.createdNeighbors[Neighbor.id]
					local ng = Neighbor.g + Heuristic:Straight(Neighbor, node)
					if ng < minValue then
						minValue = ng
						retValue = Neighbor
					end
				end
			end

			node.parent = retValue
			node.g = minValue
		end
	end

	function LazyTheta:ComputePath(dyn)
		local overheat = 0

		while not self.openList:empty() and overheat < 25000 do
			local currentNode = self.openList:pop()
			self:SetVertex(currentNode)

			--Early Exit
			if currentNode.id == self.finish.id then
				return Core:BuildPath(currentNode)
			end

			self.closed[currentNode.id] = true

			local Neighbors = Core:GetNeighborsVis(currentNode, self.createdNeighbors)
			for i = 1, #Neighbors do
				local Neighbor = Neighbors[i]
				self.createdNeighbors[Neighbor.id] = Neighbor

				if not self.closed[Neighbor.id] then
					if not Neighbor.isOpen then
						self:InitNode(Neighbor, currentNode.parent)
					end

					self:UpdateNode(currentNode, Neighbor, dyn)
				end
			end

			overheat = overheat + 1
		end

		print("OVERHEAT OF PATHFINDING")
		--Fail return
		return {}
	end

--[[####	StrictTheta Algorithm 	####
--]]

class 'StrictTheta'
	
	function StrictTheta:FindPath(Start, Finish)
		Core:__init()

		local Path = {}
		local startNode, endNode = Core:Convert(Start), Core:Convert(Finish)
		local dyn = _G.Pathfinding.Settings.weighting:Value()

		self:Initalize(startNode, endNode)
		Path = Core:isWalkable(endNode) and self:ComputePath(dyn) or {}

		return Path
	end

	function StrictTheta:InitNode(node)
		local Node = {}
		Node = node
		Node.g = 999999
		Node.parent = nil

		return Node
	end

	function StrictTheta:Initalize(startNode, endNode)
		self.openList = BH()
		self.closed = {}
		self.start = self:InitNode(startNode)
		self.finish = self:InitNode(endNode)
		self.createdNeighbors = {}
		self.Penalty = _G.Pathfinding.Settings.Penalty:Value()
		--Declare start
		self.start.parent = self.start
		self.start.g = 0
		self.start.h = Heuristic:Straight(self.start, self.finish)
		self.start.f = self.start.g + self.start.h
		--Insert start
		self.openList:push(self.start)
	end

	function StrictTheta:isTaut(N, C)
		local P = C.parent
       	if not P then return true end

		return Core:tryTaut(N.x, N.y, C.x, C.y, P.x, P.y)
	end

	function StrictTheta:relaxTarget(N, P, cost)
		if cost < N.g then
			local newG = cost

			if not self:isTaut(N, P) then
				newG = newG + self.Penalty 
			end

			N.g = newG
			N.parent = P
		end
	end

	function StrictTheta:Relax(C, N)
		local parent = C.parent

		if Core:lineOfSight(C.parent, N) then
			local cost = parent.g + Heuristic:Straight(parent, N)
			self:relaxTarget(N, parent, cost)
		else
			local cost = C.g + Heuristic:Straight(C, N)
			self:relaxTarget(N, C, cost)
		end
	end

	function StrictTheta:UpdateNode(C, N, dyn)
		local oldG = N.g
		self:Relax(C, N)

		if N.g < oldG then
			if N.isOpen then
				self.openList:heapify(N)
			else
				local hValue = Heuristic:Straight(N, self.finish)
				N.f = N.g + hValue * dyn
				N.isOpen = true
				self.openList:push(N)
			end
		end
	end

	function StrictTheta:BuildPath(node)
		local Path = {}

		while true do
			insert(Path, node)
			node = node.parent

			if node.id == self.start.id then 
				insert(Path, node)
				break 
			end
		end

		return Path
	end

	function StrictTheta:ComputePath(dyn)
		local overheat = 0

		while not self.openList:empty() and overheat < 25000 do
			local currentNode = self.openList:pop()
			if currentNode.notTaut then
				currentNode.g = currentNode.g - self.Penalty
			end
			--Early Exit
			if currentNode.id == self.finish.id then
				return Core:BuildPath(currentNode)
			end

			self.closed[currentNode.id] = true

			local Neighbors = Core:GetNeighborsVis(currentNode, self.createdNeighbors)
			for i = 1, #Neighbors do
				local Neighbor = Neighbors[i]

				self.createdNeighbors[Neighbor.id] = Neighbor

				if not self.closed[Neighbor.id] then
					if not Neighbor.g then
						self:InitNode(Neighbor)
						Neighbor.parent = currentNode
					end

					self:UpdateNode(currentNode, Neighbor, dyn)
				end
			end

			overheat = overheat + 1
		end

		print("OVERHEAT OF PATHFINDING")
		--Fail return
	end

--[[####	RecursiveStrictTheta Algorithm 	####
--]]

class 'RecursiveStrictTheta'
	
	function RecursiveStrictTheta:FindPath(Start, Finish)
		Core:__init()

		local Path = {}
		local startNode, endNode = Core:Convert(Start), Core:Convert(Finish)
		local dyn = _G.Pathfinding.Settings.weighting:Value()

		self:Initalize(startNode, endNode)
		Path = Core:isWalkable(endNode) and self:ComputePath(dyn) or {}

		return Path
	end

	function RecursiveStrictTheta:InitNode(node)
		local Node = {}
		Node = node
		Node.g = 999999
		Node.parent = nil

		return Node
	end

	function RecursiveStrictTheta:Initalize(startNode, endNode)
		self.openList = BH()
		self.closed = {}
		self.start = self:InitNode(startNode)
		self.finish = self:InitNode(endNode)
		self.createdNeighbors = {}
		self.Penalty = _G.Pathfinding.Settings.Penalty:Value()
		--Declare start
		self.start.parent = self.start
		self.start.g = 0
		self.start.h = Heuristic:Straight(self.start, self.finish)
		self.start.f = self.start.g + self.start.h
		--Insert start
		self.openList:push(self.start)
	end

	function RecursiveStrictTheta:isTaut(P, C, N)
       	if not P then return true end

		return Core:tryTaut(N.x, N.y, C.x, C.y, P.x, P.y)
	end

	function RecursiveStrictTheta:Collinear(P, C, N)
		return (C.y - P.y) * (N.x - C.x) == (N.y - C.y) * (C.x - P.x)
	end

	function RecursiveStrictTheta:outerCorner(C)
		local a = not Core:isWalkable(C.x - Core.v, C.y - Core.v)
		local b = not Core:isWalkable(C.x, C.y - Core.v)
		local c = not Core:isWalkable(C.x, C.y)
		local d = not Core:isWalkable(C.x - Core.v, C.y)

		return ((not a and not c) or (not d and not b)) and (a or b or c or d)
	end

	function RecursiveStrictTheta:Relax(C, N, isTaut)
		local newG = C.g + Heuristic:Straight(C, N)
		if newG < N.g then
			if isTaut then
				N.g = newG
				N.parent = C
				N.taut = true
			else
				N.g = newG + self.Penalty
				N.parent = C
				N.taut = false
			end

			if self:Collinear(C.parent, C, N) and self:outerCorner(C) then
				N.parent = C.parent
			end
		end
	end

	function RecursiveStrictTheta:ComputeCost(C, N)
		if self:isTaut(C.parent, C, N) then
			self:Relax(C, N, true)
		else
			if Core:lineOfSight(C.parent, N) then
				return self:ComputeCost(C.parent, N)
			else
				self:Relax(C, N, false)
			end
		end
	end

	function RecursiveStrictTheta:UpdateNode(C, N, dyn)
		local oldG = N.g
		self:ComputeCost(C, N)

		if N.g < oldG then
			if N.isOpen then
				self.openList:heapify(N)
			else
				local hValue = Heuristic:Straight(N, self.finish)
				N.f = N.g + hValue * dyn
				N.isOpen = true
				self.openList:push(N)
			end
		end
	end

	function RecursiveStrictTheta:ComputePath(dyn)
		local overheat = 0

		while not self.openList:empty() and overheat < 25000 do
			local currentNode = self.openList:pop()

			--Early Exit
			if currentNode.id == self.finish.id then
				return Core:BuildPath(currentNode)
			end

			self.closed[currentNode.id] = true

			local Neighbors = Core:GetNeighborsVis(currentNode, self.createdNeighbors)
			for i = 1, #Neighbors do
				local Neighbor = Neighbors[i]

				self.createdNeighbors[Neighbor.id] = Neighbor

				if not self.closed[Neighbor.id] then
					if not Neighbor.g then
						self:InitNode(Neighbor)
						Neighbor.parent = currentNode
					end

					self:UpdateNode(currentNode, Neighbor, dyn)
				end
			end

			overheat = overheat + 1
		end

		print("OVERHEAT OF PATHFINDING")
		--Fail return
		return {}
	end
