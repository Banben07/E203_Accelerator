ida_database -open -name=SmartLogWaves.db

#Probe log messages to SmartLog DB
ida_probe -log 

# Probe all HDL, all levels
ida_probe -wave -wave_probe_args=" -all -depth all -memories -packed 0 -unpacked 0 -tasks"

run
