--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Sorted Map Implemented with Skip Lists                            --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local global = _G -- only if available
local math   = require "math"
local oo     = require "loop.base"

local random = math.random
local rawnew = oo.rawnew

module(..., oo.class)
--------------------------------------------------------------------------------
levelprob = .5

function getnode(self)
	local pool = self.nodepool
	if pool then
		local node = pool.freenodes
		if node then
			pool.freenodes = node[1]
			return node
		end
	end
end

function freenode(self, node, last)
	local pool = self.nodepool
	if pool then
		if last == nil then last = node end
		last[1] = pool.freenodes
		pool.freenodes = node
	end
end

function newlevel(self)
	local level = 1
	local prob = self.levelprob
	local max  = self.levelmax or (#self + 1)
	while level < max and random() < prob do
		level = level + 1
	end
	return level
end

function findnode(self, key, path)
	local prev, node = self
	for level = #self, 1, -1 do
		node = prev
		repeat
			prev, node = node, node[level]
		until not node or node.key >= key
		if path then path[level] = prev end
	end
	return node, prev
end
--------------------------------------------------------------------------------
local function iterator(holder)
	node = holder[1][1]
	if node then
		holder[1] = node
		return node.key, node.value
	end
end
function pairs(self)
	return iterator, {self}
end

function get(self, key, orGreater)
	local node = self:findnode(key)
	if node and (orGreater or node.key == key) then
		return node.value, node.key
	end
end

function put(self, key, value, onlyAdd, orGreater)
	local path = self:getnode() or {}
	local node = self:findnode(key, path)
	if node and (orGreater or node.key == key) then
		self:freenode(path)
		if not onlyAdd then node.value = value end
	else
		local newlevel = self:newlevel()
		if newlevel > #self then
			for level = #self+1, newlevel do
				path[level] = self
			end
		end
		while #path > newlevel do path[#path] = nil end
		node = path
		for level = 1, newlevel do
			local prev  = path[level]
			node[level] = prev[level]
			prev[level] = node
		end
		node.key = key
		node.value = value
	end
	return node.value, node.key
end

function remove(self, key, orGreater)
	local path = {}
	local node = self:findnode(key, path)
	if node and (orGreater or node.key == key) then
		for level = 1, #self do
			local prev = path[level]
			if prev[level] ~= node then break end
			prev[level] = node[level]
		end
		self:freenode(node)
		return node.value, node.key
	end
end

function pop(self)
	local node = self[1]
	for level = 1, #self do
		if self[level] ~= node then break end
		self[level] = node[level]
	end
	self:freenode(node)
	return node.value, node.key
end

function crop(self, key, orGreater)
	local path = {}
	local node = self:findnode(key, path)
	if orGreater or (node and node.key == key) then
		if path[1] ~= self then
			local start = self[1]
			for level = 1, #self do
				self[level] = path[level][level]
			end
			self:freenode(start, path[1])
		end
		if node then
			return node.value, node.key
		end
	end
end
--------------------------------------------------------------------------------

function __tostring(self, tostring, concat)
	tostring = tostring or global.tostring
	concat = concat or global.table.concat
	local result = { "{ " }
	local node = self[1]
	while node ~= nil do
		result[#result+1] = "["
		result[#result+1] = tostring(node.key)
		result[#result+1] = "]="
		result[#result+1] = tostring(node.value)
		result[#result+1] = ", "
		node = node[1]
	end
	result[#result] = " }"
	return concat(result)
end

-- | | | [3] = table: 0xa97fe88
-- +-+-+-[6] = table: 0xa97fe88
--   | | [7] = table: 0xa97fe88
--   | +-[9] = table: 0xa97fe88
--   | | [12] = table: 0xa97fe88
--   | | [19] = table: 0xa97fe88
--   | | [21] = table: 0xa97fe88
--   +-+-[25] = table: 0xa97fe88
--       [26] = table: 0xa97fe88
function debug(self, tostring, concat)
	tostring = tostring or global.tostring
	concat = concat or global.table.concat
	local current = {global.unpack(self)}
	while #current > 0 do
		local node = current[1]
		for level = #self, 2, -1 do
			if level > #current then
				global.io.write "  "
			elseif node == current[level] then
				global.io.write "+-"
				current[level] = node[level]
			else
				global.io.write "| "
			end
		end
		current[1] = node[1]
		global.io.write "["
		global.io.write(tostring(node.key))
		global.io.write "] = "
		global.io.write(tostring(node.value))
		global.io.write ",\n"
	end
end

