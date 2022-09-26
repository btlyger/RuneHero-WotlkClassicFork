-- so you wanna add a proc ? 
-- change the RHProcs +1 
-- copy the RHProc[1] 
-- paste it on the end 
-- change the number to match the total 
-- edit away and have fun!!!!!


-- ### NOTE: This is unused in the Wotlk Classic fork.
-- ### Death Trance, Killing Machine, and Freezing Fog are tracked in RuneHero.lua > RuneFrameC_OnEvent > COMBAT_LOG_EVENT_UNFILTERED

-- how many Procs in this file ? 
RHProcs = 2; -- procs
RHProc = {}; -- do not delete me 
-- start of the Procs - copy from here 
RHProc[1] = {
	buff = "Killing Machine", -- whats it called ? 
};
-- end of proc - to here 

RHProc[2] = {
	buff = "Freezing Fog", -- whats it called ? 
};
