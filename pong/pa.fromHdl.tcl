
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name test-vga -dir "C:/Users/LENOVO/Desktop/projectDigi/vhdl-example-main/pong/planAhead_run_2" -part xc6slx9tqg144-3
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "MAIN.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {MAIN.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top MAIN $srcset
add_files [list {MAIN.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx9tqg144-3
