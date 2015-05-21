#*****************************************************
#
#    makeFanucET
# take a plPlugMapP file (output from makePlates),
# and produce a machine code file for use in the 
# U.Wash FANUC machine
#
# this contains most of the program "g_codes" written by W.Siegmund
# here are his original comments about the program :
#
#
# "This code generates a program to control a computer numerically 
# controlled (CNC) milling machine. The program that is generated is
# compatible with the industry standard controller manufactured by 
# FANUC and, in particular, the Dahlih MCV-2100 milling machine of 
# the University of Washington Physics Instrument Shop. It is not 
# directly compatible with the Dixi 420TPA at Karsten Engineering, 
# however.
# 
# Portions of the CNC program are input data independent and these 
# are copied from three text files. The balance of the program is 
# generated by processing the table of hole locations to correct for
# plate distortion and thermal expansion and to add the drilling 
# depth so that the holes are drilled through the plate. The plate 
# is not flat since it is elastically deformed over a convex drilling 
# fixture during the drilling process."
# 
# Modified from original makeFanuc for ET project plates
# Huan Lin
# 11 Feb 2005
#
# 2008-07-23 MRB: This code imported to platedesign product and 
# put under version control.  It supposedly deals with 2.5mm holes.
#
#*****************************************************

#
# set up for command parsing and help
#

ftclHelpDefine pl makeFanucET \
	"
USAGE: makeFanucET -plan=plPlan.par -verbose
Read plObs file for a list of plate designs, then produce a machine 
code file suitable for the U.Wash drilling machine for ET project plates

optional arguments :
  -plan=plPlan.par
      specify a plan file (default is plPlan.par)
  -verbose
      print status messages; if verbose is not set the program will 
      run quietly. If set to 1, various messages will be printed from 
      the TCL script. If  > 1, messages will be printed from the 
      program.
  -help
      prints this table

"



#*****************************************************************
#
# start the actual proc
#

proc makeFanucET { args } {

    #
    # Parse the command-line args and flags
    #

    set context plate
    ftclParseSave $context

    ftclFullParse { -plan=plPlan.par -verbose -oneway} $args
    set planFile [ftclGetStr plan]
    if {[ftclPresent verbose]} {
	set verbose [ftclGetStr verbose]
	# if user just typed "-verbose", set it to 1
	if { $verbose == "" } {
	    set verbose 1
	}
    } else {
	set verbose 0
    }

    ftclParseRestore $context

    if { $verbose } {
	echo "makeFanucET  : done parsing args, starting program"
    }

    #
    # read in the plan file
    #
    if { ![file exists $planFile] } {
	echo "Error: unable to locate plan file"
	return
    }

    param2Chain $planFile planHead
    foreach keyName { parametersDir parameters plObsFile outFileDir tileDir } {
	set $keyName [ keylget planHead $keyName ]
    }

    #
    # read in the parameter file
    #
    set paramFile $parametersDir/$parameters
    if { ![file exists $paramFile] } {
	echo "makeFanucET  : Error: unable to locate parameter file"
	return
    }

    param2Chain $paramFile paramHead
    foreach keyName { tempShop thermalExpand ZOffset ZOffsetR bendDistScale\
	    bendDistParity bendDistXcenter bendDistYcenter bendDistCoeff\
	    plateShapeScale plateShapeParity plateShapeXcenter\
	    plateShapeYcenter plateShapeCoeff maxRadius objectCodesFile\
	    etobjectCodesFile trapCodesFile alignCodesFile endCodesFile } {
	set $keyName [ keylget paramHead $keyName ]
    }

    set objectCodesFileName [format %s/%s $parametersDir $objectCodesFile]
    set etobjectCodesFileName [format %s/%s $parametersDir $etobjectCodesFile]
    set trapCodesFileName [format %s/%s $parametersDir $trapCodesFile]
    set alignCodesFileName [format %s/%s $parametersDir $alignCodesFile]
    set endCodesFileName [format %s/%s $parametersDir $endCodesFile]
    if {![file exists $objectCodesFileName]} {
	echo "makeFanucET : cannot find code file $objectCodesFileName"
	return
    }
    if {![file exists $etobjectCodesFileName]} {
	echo "makeFanucET : cannot find code file $etobjectCodesFileName"
	return
    }
    if {![file exists $trapCodesFileName]} {
	echo "makeFanucET : cannot find code file $trapCodesFileName"
	return
    }
    if {![file exists $endCodesFileName]} {
	echo "makeFanucET : cannot find code file $endCodesFileName"
	return
    }

    set bendDistort [ genericNew PLATEDISTORT ]
    handleSet $bendDistort.parity    1
    handleSet $bendDistort.scale     1.0
    handleSet $bendDistort.xCenter   0.0
    handleSet $bendDistort.yCenter   0.0
    loop ct2 0 20 {
	handleSet $bendDistort.coeff<$ct2> [ lindex $bendDistCoeff $ct2 ]
    }
    set surfaceShape [ genericNew PLATEDISTORT ]
    handleSet $surfaceShape.parity    1
    handleSet $surfaceShape.scale     1.0
    handleSet $surfaceShape.xCenter   0.0
    handleSet $surfaceShape.yCenter   0.0
    loop ct2 0 20 {
	handleSet $surfaceShape.coeff<$ct2> [ lindex $plateShapeCoeff $ct2 ]
    }

    if { ![file exists $plObsFile] } {
	echo "makeFanucET  : Error: unable to locate plObsFile file"
	return
    }

    set plObsCh [param2Chain $plObsFile plObsHdr]

    if { $verbose } {
	echo "makeFanucET  : beginning loop over plObs chain"
	echo "             making [chainSize $plObsCh] fanuc files"
    }

    set R2Max [expr $maxRadius*$maxRadius]

    set plateInfo [genericNew PLATEINFO]
    handleSet $plateInfo.ZOffset       $ZOffset
    handleSet $plateInfo.ZOffsetR      $ZOffsetR
    handleSet $plateInfo.maxRadius     $maxRadius
    handleSet $plateInfo.thermalExpand $thermalExpand
    handleSet $plateInfo.tempShop      $tempShop

    loop i 0 [chainSize $plObsCh] {

	set plObs [chainElementGetByPos $plObsCh $i]
	handleSet $plateInfo.tempObs [exprGet $plObs.temp]
	handleDel $plObs

	set plObs [chainElementGetByPos $plObsCh $i]
	set plateId [exprGet $plObs.plateId]
	set mjd [exprGet $plObs.mjdDesign]
	set obsTemp [exprGet $plObs.temp]
	handleDel $plObs

	set plugMapFileName [format plPlugMapP-%d.par $plateId]
	set plugMapFilePath [format %s/%s $outFileDir $plugMapFileName]
   echo $plugMapFilePath
	set plugMapData [ param2Chain $plugMapFilePath plugMapHdr ]

	if {$verbose} {
	    echo "makeFanucET : calling C program to minimize path"
	}
	if {$verbose > 1} {
	    set return [plDrillPath $plugMapData -verbose 1]
	} else {
	    set return [plDrillPath $plugMapData ]
	}
	if {$verbose} {
	    echo "makeFanucET : returned from C program to minimize path"
	}

#	set objHolesChn [keylget return objects]
        set allHolesChn [keylget return objects]
        set objHolesChn [chainSearch $allHolesChn "{holeType == OBJECT}"]
        set guideHolesChn [chainSearch $allHolesChn "{holeType == GUIDE}"]

	set trapHolesChn [keylget return lighttraps]
	set alignHolesChn [keylget return alignment]

	set fanucFileName [format plFanuc-%d.par $plateId]
	set fanucFilePath [format %s/%s $outFileDir $fanucFileName]
	set fanucFile [open $fanucFilePath w]

	puts $fanucFile "%"
#	puts $fanucFile [format "O%d(SDSS PLUG-PLATE %d)"\
#		$plateId $plateId]
	puts $fanucFile [format "O%d(SDSS/ET PLUG-PLATE %d)"\
		[expr $plateId % 7000] $plateId]
	puts $fanucFile [format "(Drilling temperature %5.1f degrees F)"\
		[expr 32 + $tempShop * 1.8] ]
	puts $fanucFile "(INPUT FILE NAME: $plugMapFileName)"
	puts $fanucFile "(CNC PROGRAM NAME: $fanucFileName)"
	    
#	copyGCodeFile $objectCodesFileName $fanucFile
	copyGCodeFile $etobjectCodesFileName $fanucFile

	if {[chainSize $objHolesChn] == 0} {
			echo "No objects found! returning"
			echo  [chainSize $plugMapData] 
			echo  [chainSize $objHolesChn] 
			echo  [chainSize $allHolesChn] 
			echo  [chainSize $guideHolesChn] 
      exit
	}

	close $fanucFile
	if {$verbose} {
	    echo "makeFanucET : calling C program to write codes"
	}
	if {$verbose > 1} {
	    set numPathFixed [ plMakeFanucCodes $objHolesChn $plateInfo\
		    $bendDistort $surfaceShape $fanucFilePath 9 -verbose 1 ]
#		    $bendDistort $surfaceShape $fanucFilePath 1 -verbose 1 ]
	} else {
	    set numPathFixed [ plMakeFanucCodes $objHolesChn $plateInfo\
		    $bendDistort $surfaceShape $fanucFilePath 9 ]
#		    $bendDistort $surfaceShape $fanucFilePath 1 ]
	}
	set fanucFile [open $fanucFilePath a]

	copyGCodeFile $objectCodesFileName $fanucFile

	close $fanucFile
  if {[chainSize $guideHolesChn]} {
	  if {$verbose > 1} {
	      set numPathFixed [ plMakeFanucCodes $guideHolesChn $plateInfo\
	  	    $bendDistort $surfaceShape $fanucFilePath 1 -verbose 1 ]
	  } else {
	      set numPathFixed [ plMakeFanucCodes $guideHolesChn $plateInfo\
	  	    $bendDistort $surfaceShape $fanucFilePath 1 ]
	  }
	} else {
			set numPathFixed 0
	}
	set fanucFile [open $fanucFilePath a]

	copyGCodeFile $trapCodesFileName $fanucFile

	close $fanucFile
	if {[chainSize $trapHolesChn]} {
	    if {$verbose > 1} {
		set numPathFixed2 [ plMakeFanucCodes $trapHolesChn $plateInfo\
			$bendDistort $surfaceShape $fanucFilePath 2 -verbose 1 ]
	    } else {
		set numPathFixed2 [ plMakeFanucCodes $trapHolesChn $plateInfo\
			$bendDistort $surfaceShape $fanucFilePath 2 ]
	    }
	} else {
	    set numPathFixed2 0
	}
	set fanucFile [open $fanucFilePath a]
	    
	copyGCodeFile $alignCodesFileName $fanucFile

	close $fanucFile
  if {[chainSize $alignHolesChn]} {
			if {$verbose > 1} {
					set numPathFixed3 [ plMakeFanucCodes $alignHolesChn $plateInfo \
																	$bendDistort $surfaceShape $fanucFilePath \ 
															3 -verbose 1 ]
			} else {
					set numPathFixed3 [ plMakeFanucCodes $alignHolesChn $plateInfo\
																	$bendDistort $surfaceShape $fanucFilePath 3 ]
			}
	} else {
			set numPathFixed3 0
	}

	# tclMakeFanucCodes will return a -1 if there was a bad hole 
	# position; check for that and remove the fanuc file if that 
	# happened.
	if {($numPathFixed == -1) || ($numPathFixed2 == -1)\
	    || ($numPathFixed3 == -1)} {
	    if {$verbose} {
		echo "makeFanucET : plMakeFanucCodes reported a bad hole\
			position, renaming plFanuc file"
	    }
	    exec mv $fanucFilePath [format %s/%s.BAD\
		    $outFileDir $fanucFileName]
	} else {
	    if {$verbose} {
		echo "makeFanucET : plMakeFanucCodes reports\
			[expr $numPathFixed + $numPathFixed2] paths fixed"
	    }
	    set fanucFile [open $fanucFilePath a]	    
	    copyEndGCodeFile $endCodesFileName $fanucFile [format %d $plateId]
	    puts $fanucFile %
	    close $fanucFile
	}

	chainDel $allHolesChn
	chainDel $objHolesChn
	chainDel $guideHolesChn
	chainDel $trapHolesChn
	chainDel $alignHolesChn
	chainDestroy $plugMapData
	flush stdout

    }

    chainDestroy $plObsCh

    if { $verbose } {
	echo "makeFanucET  : done"
    }

}

