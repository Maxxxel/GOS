--[[
				BinaryHeap Lib LUA

	Store things in a table and sort them by smallest or biggest value (no auto update, but updates by adding/removing/modifying)

	Port by Maxxxel: https://github.com/Maxxxel
	Original Creator: https://github.com/mscansian
--]]

-- DONT CHANGE ANYTHING BELOW --

local VersionBinaryHeaps = 0.1
function AutoUpdate(data)
    if tonumber(data) > tonumber(VersionBinaryHeaps) then
        PrintChat("New version found! " .. data)
        PrintChat("Downloading update, please wait...")
        DownloadFileAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/BinaryHeaps.lua", COMMON_PATH .. "BinaryHeaps.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    end
end

GetWebResultAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/BinaryHeaps.version", AutoUpdate)

BinaryHeap_SORT_SMALLEST = 1
BinaryHeap_SORT_BIGGEST  = 2

local Floor, insert = math.floor, table.insert
local Width = GetResolution().x
local Height = GetResolution().y
local Levels = 0
local OffsetX, OffsetY, Value = 0, 0, 0

class 'BinaryHeap'

	function BinaryHeap:__init(MaxElements, MaxSimultaneous, debug)
		self.BinaryHeap_MaxElements = MaxElements or 1000
		self.BinaryHeap_MaxSimultaneous = MaxSimultaneous or 5
		self.debug = debug or false

		self.Sorting = false
		self.BinaryHeap_Sort = {}
		self.BinaryHeap_Elements = {}
		self.BinaryHeap_Value = {}
		self.BinaryHeap_Data = {}

		if self.debug then
			print("BinaryHeap - Lib loaded")
			print("Your BinaryHeaps will take max. " .. Floor(self.BinaryHeap_MaxSimultaneous * self.BinaryHeap_MaxElements / 1024) .. "kb of RAM.")
		end

		return self
	end

	function BinaryHeap:_New(SortMethod)
		for Cont = 1, self.BinaryHeap_MaxSimultaneous do
			if not self.BinaryHeap_Sort[Cont] then

				self.BinaryHeap_Sort[Cont] = SortMethod
				self.BinaryHeap_Elements[Cont] = {}
				self.BinaryHeap_Value[Cont] = {}
				self.BinaryHeap_Data[Cont] = {}

				return Cont
			end
		end

		return self.BinaryHeap_MaxSimultaneous
	end

	function BinaryHeap:_Delete(BinaryHeapThread)
		if not self.Sorting and (not BinaryHeapThread or not self.BinaryHeap_Sort[BinaryHeapThread] or BinaryHeapThread > self.BinaryHeap_MaxSimultaneous or #self.BinaryHeap_Elements[BinaryHeapThread] >= self.BinaryHeap_MaxElements) then return end
		self.Sorting = true

		self.BinaryHeap_Sort[BinaryHeapThread] = nil
		self.BinaryHeap_Elements[BinaryHeapThread] = nil
		self.BinaryHeap_Value[BinaryHeapThread] = nil
		self.BinaryHeap_Data[BinaryHeapThread] = nil

		self.Sorting = false
		return true
	end

	function BinaryHeap:_Add(BinaryHeapThread, Value, HeapData)
		if not self.Sorting and (not BinaryHeapThread or not self.BinaryHeap_Sort[BinaryHeapThread] or BinaryHeapThread > self.BinaryHeap_MaxSimultaneous or #self.BinaryHeap_Elements[BinaryHeapThread] >= self.BinaryHeap_MaxElements) then return end
		self.Sorting = true
		local MyValue, ParentValue, ParentElement
		--Add 1 to _Elements
		self.BinaryHeap_Elements[BinaryHeapThread][#self.BinaryHeap_Elements[BinaryHeapThread] + 1] = {[Value] = {HeapData}}
		--Get the last element position
		local MyElement = #self.BinaryHeap_Elements[BinaryHeapThread]
		--Add element to the end of the list
		self.BinaryHeap_Value[BinaryHeapThread][MyElement] = Value
		self.BinaryHeap_Data[BinaryHeapThread][MyElement]  = HeapData
		--Get sorting method
		local Sort_Method = self.BinaryHeap_Sort[BinaryHeapThread]

		while true do
			--Get parent position
			ParentElement = Floor(MyElement * .5)
			if ParentElement <= 0 then break end
			--Get elements values
			MyValue = self.BinaryHeap_Value[BinaryHeapThread][MyElement] or 0
			ParentValue = self.BinaryHeap_Value[BinaryHeapThread][ParentElement] or 0
			--Compare data
			if (MyValue >= ParentValue and Sort_Method == BinaryHeap_SORT_SMALLEST) or (MyValue <= ParentValue and Sort_Method == BinaryHeap_SORT_BIGGEST) then
				--Leave it alone
				break
			else
				--Swap elements
				self:_Private_Swap(BinaryHeapThread, MyElement, ParentElement)
				--Get new element position
				MyElement = ParentElement
			end
		end

		self.Sorting = false
		return true
	end

	function BinaryHeap:_RemoveFirst(BinaryHeapThread)
		if not self.Sorting and (not BinaryHeapThread or not self.BinaryHeap_Sort[BinaryHeapThread] or BinaryHeapThread > self.BinaryHeap_MaxSimultaneous or #self.BinaryHeap_Elements[BinaryHeapThread] >= self.BinaryHeap_MaxElements) then return end
		self.Sorting = true
		local MyValue, Child1Value, Child2Value, Child1Active, Child2Active, Child1Element, Child2Element
		local MyElement = 1
		--Delete first element
		self.BinaryHeap_Value[BinaryHeapThread][1] = nil
		self.BinaryHeap_Data[BinaryHeapThread][1] = nil
		--Swap last element with first
		if self:_Private_Swap(BinaryHeapThread, 1, #self.BinaryHeap_Elements[BinaryHeapThread]) then
			--Remove last Element fom _Elements
			self.BinaryHeap_Elements[BinaryHeapThread][#self.BinaryHeap_Elements[BinaryHeapThread]] = nil
			--Get sorting method
			local Sort_Method = self.BinaryHeap_Sort[BinaryHeapThread]

			while true do
				--Get element child
				Child1Element = Floor(MyElement * 2)
				Child2Element = Floor(MyElement * 2) + 1
				--Get elements value
				MyValue = self.BinaryHeap_Value[BinaryHeapThread][MyElement]

				if (Child1Element <= self.BinaryHeap_MaxElements) then
					Child1Value = self.BinaryHeap_Value[BinaryHeapThread][Child1Element]
					Child1Active = (self.BinaryHeap_Data[BinaryHeapThread][Child1Element])
				else
					Child1Value = 0
					Child1Active = false
				end

				if (Child2Element <= self.BinaryHeap_MaxElements) then
					Child2Value = self.BinaryHeap_Value[BinaryHeapThread][Child2Element]
					Child2Active = (self.BinaryHeap_Data[BinaryHeapThread][Child2Element])
				else
					Child2Value = 0
					Child2Active = false
				end

				--Compare data2
				if ((Child1Active and ((MyValue >= Child1Value and Sort_Method == BinaryHeap_SORT_SMALLEST) or (MyValue <= Child1Value and Sort_Method == BinaryHeap_SORT_BIGGEST))) or (Child2Active and ((MyValue >= Child2Value and Sort_Method == BinaryHeap_SORT_SMALLEST) or (MyValue <= Child2Value and Sort_Method == BinaryHeap_SORT_BIGGEST)))) then
					if Child1Active and Child2Active and ((Child1Value <= Child2Value and Sort_Method == BinaryHeap_SORT_SMALLEST) or (Child1Value >= Child2Value and Sort_Method == BinaryHeap_SORT_BIGGEST)) then
						--Swap with child 1
						self:_Private_Swap(BinaryHeapThread, MyElement, Child1Element)
						--Get new element position
						MyElement = Child1Element
					elseif Child2Active	then
						--Swap with child 2
						self:_Private_Swap(BinaryHeapThread, MyElement, Child2Element)
						--Get new element position
						MyElement = Child2Element
					else
						break
					end
				else
					--Leave it alone
					break
				end
			end
		end

		self.Sorting = false
		return true
	end

	function BinaryHeap:_Modify(BinaryHeapThread, Value, HeapData, NewValue)
		if not self.Sorting and (not BinaryHeapThread or not self.BinaryHeap_Sort[BinaryHeapThread] or BinaryHeapThread > self.BinaryHeap_MaxSimultaneous or #self.BinaryHeap_Elements[BinaryHeapThread] >= self.BinaryHeap_MaxElements) then return end
		self.Sorting = true
		local MyValue, ParentValue, ParentElement, MyElement
		--Store number of elements
		local TotalElements = #self.BinaryHeap_Elements[BinaryHeapThread]
		--Search for the element
		for Cont = 1, TotalElements do
			if self.BinaryHeap_Value[BinaryHeapThread][Cont] == Value and self.BinaryHeap_Data[BinaryHeapThread][Cont] == HeapData then
				MyElement = Cont
				break
			elseif Cont == TotalElements then 
				return true
			end
		end

		if MyElement then
			--Change element data
			self.BinaryHeap_Value[BinaryHeapThread][MyElement] = NewValue
			--Get sorting method
			local Sort_Method = self.BinaryHeap_Sort[BinaryHeapThread]
			
			while true do
				--Get parent position
				ParentElement = Floor(MyElement * .5)
				if ParentElement <= 0 then break end
				
				--Get elements values
				MyValue = self.BinaryHeap_Value[BinaryHeapThread][MyElement]
				ParentValue = self.BinaryHeap_Value[BinaryHeapThread][ParentElement]
				
				--Compare data
				if (MyValue >= ParentValue and Sort_Method == BinaryHeap_SORT_SMALLEST) or (MyValue <= ParentValue and Sort_Method == BinaryHeap_SORT_BIGGEST) then
					--Leave it alone=
					break
				else
					--Swap elements
					self:_Private_Swap(BinaryHeapThread, MyElement, ParentElement)
					 
					 --Get new element position
					 MyElement = ParentElement
				end
			end

			return true
		end
	end

	--[[	FOR DEBUGGING PURPOSE	]]--
	function BinaryHeap:_Draw(BinaryHeapThread)
		if self.debug then
			if (not BinaryHeapThread or not self.BinaryHeap_Sort[BinaryHeapThread] or BinaryHeapThread > self.BinaryHeap_MaxSimultaneous or #self.BinaryHeap_Elements[BinaryHeapThread] >= self.BinaryHeap_MaxElements) then return end
			
			--Get total os elements
			local MaxElements = #self.BinaryHeap_Elements[BinaryHeapThread]
			
			--Get number of levels
			local Elements = 0
			local MaxLevels = 0

			while true do
				Elements = Elements * 2
				Elements = Elements + 1
				MaxLevels = MaxLevels + 1

				if Elements >= MaxElements then break end
			end

			if Levels == 0 then Levels = MaxLevels end
			if MaxElements <= 1 then Levels = 2 end
			
			local FirstPosition, LevelSpacing, LevelElements, LevelSpacingSteps, LastLevelSize

			--Get input keys
			if KeyIsDown(38) then OffsetY = OffsetY - 10 end
			if KeyIsDown(40) then OffsetY = OffsetY + 10 end
			if KeyIsDown(37) then OffsetX = OffsetX - 10 end
			if KeyIsDown(39) then OffsetX = OffsetX + 10 end
			if KeyIsDown(33) and Levels < MaxLevels then Levels = Levels + 1 end
			if KeyIsDown(34) and Levels > 1 then Levels = Levels - 1 end

			--Draw header
			DrawText("Exploring BinaryHeap: " .. BinaryHeapThread .." | TotalElements: " .. MaxElements, 10, OffsetX + Width * .5, OffsetY + 5, GoS.White)
			DrawText("Use PAGEUP/DOWN to change the number of levels, keyboard arrows to move.", 10, OffsetX + Width * .5, OffsetY + 25, GoS.White)
			
			-- --Draw Elements
			LastLevelSize = ((2^Levels) * .5) * 20 * 2
			for Level = 1, Levels do
				FirstPosition = 2^(Level-1)
				LevelSpacing = LastLevelSize / 2^Level
				LevelElements = (2^Level) * .5
				LevelSpacingSteps = -(LevelElements-1)
				
				for Pos = 0, LevelElements-1 do			
					--Check if maximum reached
					if FirstPosition+Pos > self.BinaryHeap_MaxElements then break end
					
					--Get element value and data
					Value = self.BinaryHeap_Value[BinaryHeapThread][FirstPosition+Pos]

					--Draw child lines
					if Level < Levels then
						--These lines are a total mess!!
						DrawLine(OffsetX+(Width * .5)+LevelSpacing*(LevelSpacingSteps+2*Pos), OffsetY+Level * 20+50, OffsetX+(Width * .5)+(LastLevelSize / 2^(Level + 1))*((-((2^(Level + 1)) * .5-1))+2*Pos * 2), OffsetY+(Level + 1) * 20+40, 1, GoS.White)
						DrawLine(OffsetX+(Width * .5)+LevelSpacing*(LevelSpacingSteps+2*Pos), OffsetY+Level * 20+50, OffsetX+(Width * .5)+(LastLevelSize / 2^(Level + 1))*((-((2^(Level + 1)) * .5-1))+2*((Pos * 2) + 1)), OffsetY+(Level + 1) * 20+40, 1, GoS.White)
					end
					
					--Draw element value
					DrawText(Value, 10, OffsetX+(Width * .5)+LevelSpacing*(LevelSpacingSteps+2*Pos), OffsetY+Level * 20+40, GoS.Green)
				end
			end

			return Levels
		end
	end
	--[[ 							]]--

	function BinaryHeap:_Private_Swap(BinaryHeapThread, Position1, Position2)
		if not self.Sorting and (not BinaryHeapThread or not self.BinaryHeap_Sort[BinaryHeapThread] or BinaryHeapThread > self.BinaryHeap_MaxSimultaneous or #self.BinaryHeap_Elements[BinaryHeapThread] >= self.BinaryHeap_MaxElements) then return end
		self.Sorting = true
		--Store temp variables
		local TempValue  = self.BinaryHeap_Value[BinaryHeapThread][Position1]
		local TempData   = self.BinaryHeap_Data[BinaryHeapThread][Position1]
		--Change first
		self.BinaryHeap_Value[BinaryHeapThread][Position1] = self.BinaryHeap_Value[BinaryHeapThread][Position2]
		self.BinaryHeap_Data[BinaryHeapThread][Position1] = self.BinaryHeap_Data[BinaryHeapThread][Position2]
		--Change second
		self.BinaryHeap_Value[BinaryHeapThread][Position2] = TempValue
		self.BinaryHeap_Data[BinaryHeapThread][Position2] = TempData
		
		self.Sorting = false
		return true
	end

--[[
		
			API

	require ("BinaryHeaps")

	Init the Lib:
		local Heap = BinaryHeap:__init(MaxElements, MaxSimultaneous, debug)
			MaxElements 		: number	: How many elemnts to be stored in the heap table 	: default 1000
			MaxSimultaneous 	: number	: How many heap tables at maximum 					: default 5
			debug 				: boolean	: Show drawings (debug) 							: default false

	Create new heap table:
		local ID = Heap:_New(SortMethod)
			ID 					: name 	 	: Identifier to access the table
			SortMethod 			: number 	: BinaryHeap_SORT_SMALLEST = 1BinaryHeap_SORT_BIGGEST  = 2

	Add a value to the heap table:
		Heap:_Add(ID, Value, HeapData)
			ID 					: number 	: Identifier to access the table
			Value 				: number 	: Value to sort in the table
			HeapData 			: data 		: Data to store

	Remove first value of the heap table:
		Heap:_RemoveFirst(ID)
			ID 					: number 	: Identifier to access the table

	Delete whole heap table:
		Heap:_Delete(ID)
			ID 					: number 	: Identifier to access the table

	Modify a value in the heap table:
		Heap:__Add(ID, Value, HeapData, NewValue)
			ID 					: number 	: Identifier to access the table
			Value 				: number 	: Value to identify the right position
			HeapData 			: data 		: Data to identify the right position
			NewValue 			: number 	: New Value

			NOTE: HeapData stays unchanged, you can simply modify the order with it only by changing the value.

	DEBUG: Draw the heap table
		Heap:_Draw(ID)
			ID 					: number 	: Identifier to access the table



	Example:

		require ("Pathfinding\\" .. "BinaryHeaps")
		local bheap = BinaryHeap:__init(1000, 5, true)

		local test = bheap:_New(BinaryHeap_SORT_SMALLEST)

		OnTick(function(myHero)
		    valor = math.random(2,100)

		    if KeyIsDown(49) then -- 1
		      bheap:_Delete(test)
		    end

		    if KeyIsDown(50) then -- 2
		      bheap:_Add(test,valor,valor)
		    end

		    if KeyIsDown(51) then -- 3
		      bheap:_RemoveFirst(test)
		    end

		    if KeyIsDown(52) then -- 4
		      valor = 100
		      bheap:_Modify(test, valor, valor, 1)
		    end

		end)

		OnDraw(function(myHero)
		    bheap:_Draw(test)
		end)
--]]
