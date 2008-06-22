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
-- Title  : Interchangeable Disjoint Cyclic Sets                              --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local global = require "_G"
local table  = require "loop.table"
local oo     = require "loop.base"

local next   = global.next
local rawget = global.rawget
local copy   = table.copy
local rawnew = oo.rawnew

module(..., oo.class)

function contains(self, item)
	return (self.next or self)[item] ~= nil
end

function successor(self, item)
	return (self.next or self)[item]
end

function forward(self, item)
	return rawget, (self.next or self), item
end

-- []:add(item)                   : item --> [item]
-- []:add(place, item)            : item --> [place, item]
-- [place]:add(place, item)       : item --> [place, item]
-- [item]:add(place, item)        : nil  --> [item]
-- [place, item]:add(place, item) : nil  --> [place, item]
function add(self, place, item)
	local next = self.next or self
	if next[item] == nil then
		local replaced
		if place == nil then
			place, replaced = item, item
		else
			replaced = next[place]
			if replaced == nil then
				replaced = place
			end
		end
		next[item] = replaced
		next[place] = item
		return item
	end
end

-- []:remove(place)            : nil  --> []
-- [item]:remove(place)        : nil  --> [item]
-- [place, item]:remove(place) : item --> [place]
function removefrom(self, place)
	local next = self.next or self
	local item = next[place]
	if item ~= nil then
		next[place] = next[item]
		next[item] = nil
		return item
	end
end

-- []:moveto(new, old)                           : nil  --> []
-- [new]:moveto(new, old)                        : nil  --> [new]
-- [old, item]:moveto(new, old)                  : item --> [old|new, item]
-- [old, item|new]:moveto(new, old)              : item --> [old|new, item]
-- [old, item...last|new]:moveto(new, old, last) : item --> [old|new, item...last]
-- [old, item|new]:moveto(new, old, last)        : item --> INCONSISTENT STATE
-- [old, item|last...]:moveto(new, old, last)    : item --> INCONSISTENT STATE
function movetofrom(self, new, old, last)
	local next = self.next or self
	local item = next[old]
	if last == nil then last = item end
	if item ~= nil then
		next[old] = next[last]
		next[last] = next[new]
		next[new] = item
		return item
	end
end

function disjoint(self)
	local items = self.next or self
	local result = {}
	local missing = copy(items)
	local start = next(missing)
	while start do
		result[#result+1] = start
		local item = start
		repeat
			missing[item] = nil
			item = items[item]
		until item == start
		start = next(missing)
	end
	return result
end

function __tostring(self, tostring, concat, delimiter)
	tostring = tostring or global.tostring
	concat = concat or global.table.concat
	local items = self.next or self
	local result = {}
	local missing = copy(items)
	local start = next(missing)
	while start do
		result[#result+1] = "[ "
		local item = start
		repeat
			result[#result+1] = tostring(item)
			result[#result+1] = ", "
			missing[item] = nil
			item = items[item]
		until item == start
		result[#result] = " ]"
		start = next(missing)
	end
	return concat(result)
end
