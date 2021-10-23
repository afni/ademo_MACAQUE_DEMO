AFNI's Macaque Demo

auth = DR Glen, PA Taylor

Thanks to Adam Messinger, Ben Jung and Jakob Seidlitz for both the
accompanying macaque data set and many processing suggestions/advice.

(See version history below.)

--------------------------------------------------------------------------

INPUTS

    Subject data in dir sub-000/:

        anat-sub-000.nii.gz : anatomical (T1w) dataset
                              + whole brain, with skull

        epi-r*.nii.gz       : task functional (EPI) datasets
                              + raw EPIs, with "place correction" performed

        stim_*.1D           : stimulus timing files
                              + already set for the TR removal that will
                                be performed in the processing


    Subject warp (to NMT space) and skullstrip information in dir
    sub-000.warped/ (created with @animal_warper-- see s00*tcsh script):

        sub-000*_ns.nii.gz : skullstripped version of subject anat
                             (still in native space)

        sub-000*_nsu.nii.gz : skullstripped+unifized version of
                             subject anat (still in native space)

        sub-000*_warp2std_nsu.nii.gz : skullstripped version of
                             subject anat (in template space); has
                             also been "unifized" (brightness
                             normalized across the volume and by tissue)

        sub-000*_composite_linear_to_template.1D,
        sub-000*_shft_WARP.nii.gz : affine and nonlinear warps,
                             respectively, from anat to template space
                             (need to be concatenated when applied in 
                             afni_proc.py)

        QC/ subdirectory   : automatic snapshots created during processing
                             for quick quality control (QC), including new
                             image showing initial overlap for starting
                             alignment

        surfaces/ subdir   : SUMA (Isosurface) generated surfaces
                             of all atlas and segmentation followers
                             (that were mapped from template to original
                             space), as well as the template surface
                             (after warping template to original space);
                             there are scripts to view all of these in SUMA
                             in this dir, too

        [and other, mainly intermediate, files included]


    NMT_v2.0_sym/ contains standard space data downloaded with
    @Install_NMT, including datasets at 0.5 mm iso voxel size in
    NMT_v2.0_sym_05mm/.  :

        NMT2_*SS.nii.gz      : skullstripped template, in/defining NMT2 space
                               (for more info, see Jung et al., 2020)

        CHARM*_*.nii.gz      : CHARM atlas in the NMT2 space
                               (for more info, see Jung et al., 2020)
         

SCRIPTS

    s00_warp_skullstrip.tcsh (already run)

       A script (already run) that performs nonlinear alignment to a
       the standard space template (here, NMT).  All outputs from here 
       are in the directory sub-000.warped/.  Outputs include:

           + the warps to- and from- standard space
           + a skull-stripped version of the anatomical
           + a whole brain mask of the anat
           + a copy of the NMT warped to the anat orig space
           + a copy of the D99 atlas warped to the anat orig space
           + surface versions of the atlases, each with 'driver' scripts
             to view
           + QC images of this processing (alignments, etc.)

       Nonlinear alignment is a bit slow (of order30 mins, using 6
       CPUs on laptop), hence we have run it already.
                  

    s01_ap.tcsh (to be run; QC part of output in main dir)

       A script (to be run) that executes the afni_proc.py command to
       generate a full processing script; the '-execute' option has
       been included, so running this command will both generate the
       script and have it carry out the processing.  Stimulus timing
       files and contrasts of interest have been defined.  This
       command uses the output of the s00*.tcsh warp+skullstrip script.

       A number of reasonable processing parameters have been chosen
       (e.g., 2 mm smoothing for these 1.5 mm isotropic voxels, though
       this is pretty light blurring), but could certainly be tweaked.

       This script uses only the first 4 EPIs for processing, for the
       sake of time/memory (see s11*.tcsh for a script processing
       *all* the EPIs).

    s11_ap_ALLEPI.tcsh (to be run; QC part output in main dir)

       A bonus script: essentially the same afni_proc.py command as
       s01_ap.tcsh, but this will process all 15 EPI dsets.


QC SAMPLES 

    afni_proc.py outputs several form of auto-generated QC assistance.
    As part of this, a full HTML page gets generated, containing
    images showing alignment, stats fitting, possible warnings, and
    other features of the processing.  The default "basic" method will
    be created by the s01*tcsh script. But if you have Python (and its
    matplotlib module) installed on your computer, you can view the
    fancier/more informative "pythonic" version; examples of these are
    provided here (in each case, open the "index.html" file in the
    given subdirectory with your browser, e.g., "firefox
    QC_sub-000_py/index.html" or "afni_open -b
    QC_sub-000_py/index.html"):

        QC_sub-000/           : the "pythonic" form of the QC HTML for
                                the afni_proc.py command in s01*.tcsh 

        QC_sub-000_full/      : the "pythonic" form of the QC HTML for
                                the afni_proc.py command in s11*.tcsh,
                                with an extra (soon-to-be-released)
                                feature of including GLT images from
                                the stats modeling.

============================================================================
============================================================================

Version history
---------------

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

