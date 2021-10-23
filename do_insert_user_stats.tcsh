#!/bin/tcsh

# script to insert stat/GLT names into the uvar json file, to get APQC
# of all of them in the HTML

# this program creates a new JSON file with the inserted "user_stats"
# uvar, and then re-runs APQC (copying previous QC to a new spot)

# [PT: May 4, 2021] updated with new GLT names... sigh.
# [PT: May 10, 2021] updated with GLT contrasts from modeling.

# -----------------------------------------------------------------------
# Get+check the lone input:  AP results dir name

set dir_ap_res = "$1"

if ( "$dir_ap_res" == "" ) then
    echo "** ERROR: you need to provide an AP results directory as command"
    echo "   line input"
    exit 1
else if ( ! -d "${dir_ap_res}" ) then
    echo "** ERROR: this does not appear to be a valid (AP results) dir:"
    echo ""
    echo "       ${dir_ap_res}"
    exit 2
else
    echo "++ Redo APQC with full stats for:"
    echo ""
    echo "       ${dir_ap_res}"
endif

echo ""

# -----------------------------------------------------------------------
# set vars, for basically constant file and uvar names

set here      = $PWD
set uvar_orig = out.ss_review_uvars.json
set the_uvar  = tsnr_dset
set uvar_mod  = out.ss_review_uvars_EXT.json

# jump to AP res dir
cd "${dir_ap_res}"

# check that we can work here
if ( ! -e "${uvar_orig}" ) then
    echo "** ERROR: no original uvar JSON file: ${uvar_orig}"
    echo "   Cannot continue."
    exit 3
endif

# -----------------------------------------------------------------------
# make new uvar JSON

# get line number after which to insert...
set nnn = `grep -n ${the_uvar} ${uvar_orig} | cut -f1 -d:`
# ... and one greater, for last copy
@   ooo = ${nnn} + 1

# 1) copy first part of JSON file
head -n ${nnn} ${uvar_orig} > ${uvar_mod}

# 2) insert our user stats into file
cat <<EOF >> ${uvar_mod}
   "user_stats" : [ "FACE",
                    "OBJ",
                    "SFACE",
                    "SOBJ",
                    "+F-SF",
                    "+O-SO",
                    "+INTACT-SCRAM",
                    "+F-O",
                    "+.5FO"],
EOF

# 3) copy last part of JSON file
tail -n +${ooo} ${uvar_orig} >> ${uvar_mod}

# -----------------------------------------------------------------------
# redo APQC

# first, check if a QC dir exists already; if so, move it to a
# time-stamped name, old_QC*_TIMESTAMP
set pre_qc = `find . -maxdepth 1 -type d -name "QC*"`
if ( "${pre_qc}" != "" ) then
    set pre_qc_name = `echo ${pre_qc} | cut -b3-`
    set thedate     = `date +%Y_%m_%d_%H_%M_%s`
    \mv ${pre_qc} old_${pre_qc_name}_${thedate}
endif

# now, redo APQC
apqc_make_tcsh.py -review_style pythonic -subj_dir . \
    -uvar_json "${uvar_mod}"
tcsh @ss_review_html |& tee out.review_html_ext

set now_qc = `find . -maxdepth 1 -type d -name "QC*"`
apqc_make_html.py -qc_dir ${now_qc}



