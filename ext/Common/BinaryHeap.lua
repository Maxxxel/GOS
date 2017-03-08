if (...) then
	local store = {}
	local floor = math.floor

	local function f_min(a,b)
		return a.f < b.f
	end

	local indexOf = function(t,v)
		for i = 1,#t do
			if t[i] == v then return i end
		end
		return nil
	end

	local function percolate_up(heap, index)
		if index == 1 then return end
		local pIndex
		if index <= 1 then return end
		if index%2 == 0 then
			pIndex =  index/2
		else pIndex = (index-1)/2
		end
		if not heap._sort(heap._heap[pIndex], heap._heap[index]) then
			heap._heap[pIndex], heap._heap[index] = 
				heap._heap[index], heap._heap[pIndex]
			percolate_up(heap, pIndex)
		end
	end

	local function percolate_down(heap,index)
		local lfIndex,rtIndex,minIndex
		lfIndex = 2*index
		rtIndex = lfIndex + 1
		if rtIndex > heap._size then
			if lfIndex > heap._size then return
			else minIndex = lfIndex  end
		else
			if heap._sort(heap._heap[lfIndex],heap._heap[rtIndex]) then
				minIndex = lfIndex
			else
				minIndex = rtIndex
			end
		end
		if not heap._sort(heap._heap[index],heap._heap[minIndex]) then
			heap._heap[index],heap._heap[minIndex] = heap._heap[minIndex],heap._heap[index]
			percolate_down(heap,minIndex)
		end
	end

	local function newHeap(template,comp)
		return setmetatable({_heap = {},
			_sort = comp or f_min, _size = 0},
		template)
	end

	local heap = setmetatable({},
		{__call = function(self,...)
			return newHeap(self,...)
		end})
	heap.__index = heap

	function heap:empty()
		return (self._size==0)
	end

	function heap:clear()
		self._heap = {}
		self._size = 0
		self._sort = self._sort or f_min
		return self
	end

	function heap:push(item)
		if item then
			self._size = self._size + 1
			self._heap[self._size] = item
			store[item.id] = self._size 
			percolate_up(self, self._size)
		end
		return self
	end

	function heap:pop()
		local root
		if self._size > 0 then
			root = self._heap[1]
			self._heap[1] = self._heap[self._size]
			self._heap[self._size] = nil
			self._size = self._size-1
			if self._size>1 then
				percolate_down(self, 1)
			end
		end
		return root
	end

	function heap:heapify(item)
		if self._size == 0 then return end
		if item then
			local i = indexOf(self._heap,item)
			if i then 
				percolate_down(self, i)
				percolate_up(self, i)
			end
			return
		end
		for i = floor(self._size/2),1,-1 do
			percolate_down(self,i)
		end
		return self
	end

	return heap
end
