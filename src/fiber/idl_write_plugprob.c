#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "export.h"
#include "fiber.h"


/********************************************************************/
IDL_LONG idl_write_plugprob (int      argc,
														void *   argv[])
{
	int nTargets, nFibersBlock, nFibers, minFibersInBlock, *fiberused;
	int nMax,minAvailInBlock, maxFibersInBlock, *toblock, blockconstrain;
	int noycost;
	double *xtarget, *ytarget, *xfiber, *yfiber, limitDegree;
	double *blockcenx, *blockceny, *blockylimits;
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
	toblock=((int *)argv[i]); i++;
	nFibers=*((int *)argv[i]); i++;
	nMax=*((int *)argv[i]); i++;
	nFibersBlock=*((int *)argv[i]); i++;
	limitDegree=*((double *)argv[i]); i++;
	minAvailInBlock=*((int *)argv[i]); i++;
	minFibersInBlock=*((int *)argv[i]); i++;
	maxFibersInBlock=*((int *)argv[i]); i++;
	blockcenx=((double *)argv[i]); i++;
	blockceny=((double *)argv[i]); i++;
	blockconstrain=*((int *)argv[i]); i++;
	idl_probfile=*((IDL_STRING *) argv[i]); i++;
	strncpy(probfile, idl_probfile.s, 1000);
	noycost=*((int *)argv[i]); i++;
	blockylimits=((double *)argv[i]); i++;
	
	/* 1. run the fitting routine */
	retval=(IDL_LONG) write_plugprob(xtarget, ytarget, nTargets,
																	 xfiber, yfiber, fiberused, toblock, nFibers,
																	 nMax, nFibersBlock, limitDegree, 
																	 minAvailInBlock, minFibersInBlock, 
																	 maxFibersInBlock, blockcenx, blockceny, 
																	 blockconstrain, probfile, noycost, 
																	 blockylimits);
	
	/* 2. free memory and leave */
	return retval;
}

/***************************************************************************/

