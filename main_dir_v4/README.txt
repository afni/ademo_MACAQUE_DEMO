AFNI's Macaque Demo

auth = DR Glen, PA Taylor

Thanks to Adam Messinger, Ben Jung and Jakob Seidlitz for both the
accompanying macaque data set and many processing suggestions/advice.

--------------------------------------------------------------------------

INPUTS and DATA

  ++ Raw (=input) data directory tree:

     data_00_basic/
     └── sub-000/
         └── ses-01/
             ├── anat/
             │   └── anat-sub-000.nii.gz
             └── func/
                 ├── epi-r09-sub-000.nii.gz
                 ├── epi-r10-sub-000.nii.gz
                 ├── epi-r11-sub-000.nii.gz
                 ├── epi-r12-sub-000.nii.gz
                 ├── epi-r13-sub-000.nii.gz
                 ├── epi-r14-sub-000.nii.gz
                 ├── epi-r15-sub-000.nii.gz
                 ├── epi-r16-sub-000.nii.gz
                 ├── epi-r17-sub-000.nii.gz
                 ├── epi-r18-sub-000.nii.gz
                 ├── epi-r19-sub-000.nii.gz
                 ├── epi-r20-sub-000.nii.gz
                 ├── epi-r21-sub-000.nii.gz
                 ├── epi-r22-sub-000.nii.gz
                 ├── epi-r23-sub-000.nii.gz
                 ├── stim_face.1D
                 ├── stim_obj.1D
                 ├── stim_scram_face.1D
                 └── stim_scram_obj.1D

     where:
       anat-*.nii.gz : anatomical (T1w) dataset, whole brain, with skull

       epi-r*.nii.gz : task functional (EPI) datasets, which are raw
                       EPIs, with "place correction" previously
                       performed

       stim_*.1D     : stimulus timing files, already set for the TR removal
                       that will be performed in the processing


  ++ Anatomical nonlinear warp (to NMT2 space) and skullstrip tree:

     data_13_aw/
     └── sub-000/
         └── ses-01/

     which was created by running @animal_warper (via
     ./scripts/run_13_aw.tcsh) and contains:

        sub-000*_ns.nii.gz : skullstripped version of subject anat
                             (still in native space)

        sub-000*_nsu.nii.gz : skullstripped+unifized version of
                             subject anat (still in native space)

        sub-000*_warp2std_nsu.nii.gz 
                           : skullstripped version of subject anat (in
                             template space); has also been "unifized"
                             (brightness normalized across the volume
                             and by tissue)

        sub-000*_composite_linear_to_template.1D,
        sub-000*_shft_WARP.nii.gz 
                           : affine and nonlinear warps, respectively,
                             from anat to template space (need to be
                             concatenated when applied in afni_proc.py)

        QC/                : directory of automatic snapshots created
                             during processing for quick quality control
                             (QC), including new image showing initial
                             overlap for starting alignment

        surfaces/          : directory of SUMA (Isosurface) generated
                             surfaces of all atlas and segmentation
                             followers (that were mapped from template
                             to original space), as well as the template
                             surface (after warping template to original
                             space); there are scripts to view all of
                             these in SUMA in this dir, too

        ... and other, mainly intermediate, files 


  ++ Reference template directory: ./NMT_v2.1_sym/

     This contains macaque standard space data downloaded with
     @Install_NMT, including datasets at 0.5 mm iso voxel size:

       NMT2_*SS.nii.gz     : skullstripped template, in/defining NMT2 
                             space (for more info, see Jung et al., 2020)

       CHARM*_*.nii.gz     : CHARM atlas in the NMT2 space
                             (for more info, see Jung et al., 2020)

       ... and many more datasets and supplementary files

--------------------------------------------------------------------------

SCRIPTS 
        
   Processing scripts are all contained in the ./scripts/ directory.

   Each script comes in a pair, such as do_13_aw.tcsh and run_13_aw.tcsh:

     do_*.tcsh     : a script to process one subject

     run_*.tcsh    : a script to loop over one or more subjects, calling
                     the associated do_*.tcsh script

   The processing scripts are made to be run from the scripts/
   directory.  To process the data, users should execute the
   run_*.tcsh scripts, such as with:

     tcsh run_20_ap.tcsh

   The following pairs are included (some have already been run):

   + do_13_aw.tcsh, via run_13_aw.tcsh (already run):

       Run @animal warper to calculate nonlinear warps from the
       anatomical to a template space (here, NMT); map additional data
       (e.g., atlases and segmentations) between the spaces; also
       estimate skullstripping/brainmasking of the anatomical volume.

       These scripts populate the data_13_aw/ directory. Output data
       include:

         - the warps to- and from- standard space
         - a skull-stripped version of the anatomical
         - a whole brain mask of the anat
         - a copy of the NMT warped to the anat orig space
         - a copy of the D99 atlas warped to the anat orig space
         - surface versions of the atlases and 'driver' scripts to visualize
         - QC images of this processing (alignments, etc.)

       Nonlinear alignment is a bit slow (of order 30 mins, using 6
       CPUs on laptop), hence we have run it already.
                  

   + do_20_ap.tcsh, via run_20_ap.tcsh (to be run)

       Run afni_proc.py to generate a full FMRI processing script, and
       carry out the processing.  Stimulus timing files and contrasts
       of interest have been defined.  This command uses the output of
       the *13_aw* scripts.

       A number of reasonable processing parameters have been chosen
       (e.g., 2 mm smoothing for these 1.5 mm isotropic voxels, though
       this is pretty light blurring), but could certainly be tweaked.

       This script uses only the first 4 EPIs for processing, for the
       sake of time/memory (see *21_ap_all*.tcsh for a script
       processing *all* the EPIs).

       See "QC SAMPLES" below.
       NB: the QC HTML of an earlier run of this data is distributed
       in the main directory, for quick viewing, and can be opened
       with any browser, such as via:

           afni_open -b QC_sub-000__FOUREPI/index.html
      

   + do_20_ap_all.tcsh, via run_21_ap_all.tcsh (to be run)

       A bonus script: essentially the same afni_proc.py command as
       do_20_ap.tcsh, but this will process all 15 EPI dsets.

       See "QC SAMPLES" below.

       The QC HTML of an earlier run of this data can be opened with 
       any browser, such as via:

           afni_open -b QC_sub-000__ALLEPI/index.html

--------------------------------------------------------------------------

QC SAMPLES 

    The processing done with afni_proc.py includes several form of
    auto-generated QC assistance.  As part of this, a full HTML page
    gets generated, containing images showing alignment, stats
    fitting, possible warnings, and other features of the processing.
    Here, we assume you have Python and its Matplotlib module
    installed on your computer, so that you can create the
    fancier/more informative "pythonic" version of this HTML; if you
    don't, you should install these things; but if you *really* don't,
    then you can change the html_review_style to 'basic'.

    To view the APQC HTML, you can use any browser and open the
    QC_*/index.html file in the results directory of afni_proc.py
    processing.  For example, either of:

       firefox QC_sub-000/index.html

       afni_open -b QC_sub-000/index.html

    We distribute the "pythonic" APQC HTMLs of the do_ap*.tcsh scripts
    for this demo in the main directory.  

    The output of the shorter, 4-run example from do_20* can be viewed
    directly with:

       afni_open -b QC_sub-000__FOUREPI/index.html

    The output of the longer, all-run example from do_21* (which also
    includes an extra, soon-to-be-released feature of including GLT
    images from the stats modeling) can be viewed directly with:

       afni_open -b QC_sub-000__ALLEPI/index.html

============================================================================
============================================================================

Demo Version history
--------------------

ver  = 4.1; date = Oct 23, 2021

+ Remove old/unuseful file from scripts/ directory

---------------------------------------------------------------------------
ver  = 4.0; date = Oct 23, 2021

+ Now using NMT v2.1
+ a wee bit more afni_proc.py output (TSNR images)
+ reformat scripts to be easier to read (hopefully)

---------------------------------------------------------------------------
ver  = 3.0; date = Oct 19, 2020

+ @animal_warper output is now rearranged in the main dir
  - more subdirectories (surfaces/ and intermediate/)
  - some new QC images (report*1D now in QC)
  - helpfile has more description

---------------------------------------------------------------------------
ver  = 2.2; date = Aug 4, 2020

+ MORE NMT/CHARM dset updates
+ unpack to non-versioned name

---------------------------------------------------------------------------
ver  = 2.1; date = July 30, 2020

+ All NMT/CHARM dsets are updated
+ Now download NMT data directly
+ Check that template is in a findable spot on computer
+ Use more follower dsets in @animal_warper example
+ Update names in AP tcsh scripts a bit
+ Rename pre-made QC dirs (simpler)

---------------------------------------------------------------------------

ver  = 2.0; date = Apr 30, 2020

+ Updated @animal_warper: concatenate shift into warps
+ reran scripts
+ new template space: stereoNMT
+ more APQC features

---------------------------------------------------------------------------
ver  = 1.2; date = Oct 7, 2019

+ Updated @animal_warper: find template/atlases more easily
+ reran scripts
+ Fixed s11*tcsh script (path error)

---------------------------------------------------------------------------
ver  = 1.1 (beta); date = Sep 12, 2019

+ Initial dataset and processing

