#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "export.h"
#include "fiber.h"


/********************************************************************/
IDL_LONG idl_read_plugprob (int      argc,
														void *   argv[])
{
	IDL_LONG *targetFiber, *targetBlock, nTargets, nFibersBlock, nFibers;
	double *xtarget, *ytarget;
	IDL_STRING idl_ansfile;
	char ansfile[1000];
	
	IDL_LONG i;
	IDL_LONG retval=1;

	/* 0. allocate pointers from IDL */
	i=0;
	xtarget=((double *)argv[i]); i++;
	ytarget=((double *)argv[i]); i++;
	targetFiber=((int *)argv[i]); i++;
	targetBlock=((int *)argv[i]); i++;
	nTargets=*((int *)argv[i]); i++;
	nFibersBlock=*((int *)argv[i]); i++;
	nFibers=*((int *)argv[i]); i++;
	idl_ansfile=*((IDL_STRING *) argv[i]); i++;
	strncpy(ansfile, idl_ansfile.s, 1000);
	
	/* 1. run the fitting routine */
	retval=(IDL_LONG) read_plugprob(xtarget, ytarget, targetFiber, 
																	targetBlock, nTargets, nFibersBlock,
																	nFibers, ansfile);
	
	/* 2. free memory and leave */
	return retval;
}

/***************************************************************************/

