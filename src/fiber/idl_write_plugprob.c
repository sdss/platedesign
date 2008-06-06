#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "export.h"
#include "fiber.h"


/********************************************************************/
IDL_LONG idl_write_plugprob (int      argc,
														void *   argv[])
{
	IDL_LONG nTargets, nFibersBlock, nFibers, minFibersInBlock, *fiberused;
	double *xtarget, *ytarget, *xfiber, *yfiber, limitDegree;
	char probfile[1000];
	IDL_STRING idl_probfile;
	
	IDL_LONG i;
	IDL_LONG retval=1;

	/* 0. allocate pointers from IDL */
	i=0;
	xtarget=((double *)argv[i]); i++;
	ytarget=((double *)argv[i]); i++;
	nTargets=*((int *)argv[i]); i++;
	xfiber=((double *)argv[i]); i++;
	yfiber=((double *)argv[i]); i++;
	fiberused=((int *)argv[i]); i++;
	nFibers=*((int *)argv[i]); i++;
	nFibersBlock=*((int *)argv[i]); i++;
	limitDegree=*((double *)argv[i]); i++;
	minFibersInBlock=*((int *)argv[i]); i++;
	idl_probfile=*((IDL_STRING *) argv[i]); i++;
	strncpy(probfile, idl_probfile.s, 1000);
	
	/* 1. run the fitting routine */
	retval=(IDL_LONG) write_plugprob(xtarget, ytarget, nTargets,
																	 xfiber, yfiber, fiberused, nFibers,
																	 nFibersBlock, limitDegree, 
																	 minFibersInBlock, probfile);
	
	/* 2. free memory and leave */
	return retval;
}

/***************************************************************************/

