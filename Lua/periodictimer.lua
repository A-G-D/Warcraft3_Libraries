--[[ periodictimer.lua v1.0.0 by AGD


	Description:

		Periodic timer


	Requirements:

		- EventListener
			Link: https://www.hiveworkshop.com/threads/323354/
]]--
--[[

	API:

		PeriodicTimer(number: period = 1.00)

		PeriodicTimer:register(function: callback [, ...]) -> self
		PeriodicTimer:deregister(function: callback) -> self

]]--
PeriodicTimer = {
	TIMEOUT_ACCURACY = 7,
	TIMEOUT_OFFSET_TOLERANCE = 0.01
}
do
	local timer = {}
	setmetatable(PeriodicTimer, timer)
	timer.__index = timer

	local cache = {}

	local function GetTimerSlot(self)
		local stack = self.timer_stack
		if stack then
			for i = 1, #stack do
				if 	TimerGetRemaining(stack[i].timer) <= PeriodicTimer.TIMEOUT_OFFSET_TOLERANCE	or
					IsTimerPaused(stack[i].timer) then
					-- timer is available, return its slot
					return stack, i
				end
			end
			-- no available timers in stack, append new timer to stack
			stack[#stack + 1] = {
				timer = CreateTimer(),
				listener = Listener.new(),
				listener_size = 0
			}
			return stack, #stack
		end
		-- stack is not yet created, create now
		stack = {}
		stack[1] = {
			timer = CreateTimer(),
			listener = Listener(),
			listener_size = 0
		}
		self.timer_stack = stack
		return stack, 1
	end

	---@param period number
	local timeout_accuracy = math.pow(10, PeriodicTimer.TIMEOUT_ACCURACY)
	function timer:__call(period)
		period = math.floor(period*timeout_accuracy)
		cache[period] = cache[period] or
			setmetatable({period = period, timer_stack = {}}, timer)
		return cache[period]
	end

	function timer:register(...)
		local stack, i = GetTimerSlot(self)
		stack = stack[i]
		if stack.listener_size == 0 then
			TimerStart(stack.timer, self.period, true, function ()
				stack.listener:execute()
			end)
		end
		stack.listener_size = stack.listener_size + 1
		stack.listener:register(...)
		return self
	end
	function timer:deregister(...)
		for i = 1, #self.timer_stack do
			local stack = self.timer_stack[i]
			stack.listener:deregister(...)
			stack.listener_size = stack.listener_size - 1
			if stack.listener_size == 0 then
				PauseTimer(timer)
			end
		end
		return self
	end

end