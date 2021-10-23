#!/bin/tcsh

time tcsh s00_warp_skullstrip.tcsh
time tcsh s01_ap.tcsh
     tcsh do_insert_user_stats.tcsh sub-000.results
time tcsh s11_ap_ALLEPI.tcsh
     tcsh do_insert_user_stats.tcsh sub-000_full.results
