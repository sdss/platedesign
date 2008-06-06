#include <stdio.h>
#include <stdlib.h>
#include <string.h> 
#include <math.h>
#include "fiber.h"

/*
 * MaxFlow assignment of targets to fibers.
 * Routine to write the problem out.
 *
 * REQUIRED PRODUCTS:
 *  cs2 (Goldberg's algorithm)
 *
 * AUTHORS:
 *  Mike Blanton (Apr 2000)
 *  Moved to platedesign product (June 2008)
 *
 */

#define COSTFACTOR 1000

static int nBlocks=0;
static int *fiberTargets=NULL;
static int *nFiberTargets=NULL;
static int *nTargetBlocks=NULL;

int write_plugprob(double xtarget[],
									 double ytarget[],
									 int nTargets,
									 double xfiber[],
									 double yfiber[],
									 int fiberused[],
									 int nFibers,
									 int nMax,
									 int nFibersBlock,
									 double limitDegree, 
									 int minAvailInBlock,
									 int minFibersInBlock,
									 char probfile[])
{
	double sep2,limit2;
	int i,j,jFiber,nArcs,nNodes,block;
	long cost;
	FILE *fp;

	nBlocks=nFibers/nFibersBlock;
	nTargetBlocks=(int *) malloc(nBlocks*sizeof(int));
	
	/* 
	 * Find which fibers can be assigned to which targets
	 */
	fiberTargets=(int *) malloc(nTargets*nFibers*sizeof(int));
	nFiberTargets=(int *) malloc(nTargets*sizeof(int));
	limit2=limitDegree*limitDegree;
	for(i=0;i<nTargets*nFibers;i++) 
		fiberTargets[i]=-1;
	for(i=0;i<nTargets;i++) {

		/* add up the number of fibers in each block which
		 * can reach the target */
		for(j=0;j<nBlocks;j++) 
			nTargetBlocks[j]=0;
		for(j=0;j<nFibers;j++) {
			block=(int) floor(j/nFibersBlock);
			sep2=(xtarget[i]-xfiber[j])*(xtarget[i]-xfiber[j])+
				(ytarget[i]-yfiber[j])*(ytarget[i]-yfiber[j]);
			if(sep2<limit2) 
				nTargetBlocks[block]++;
		} /* end for j */

		/* now figure out which fibers can reach the target,
		 * for which a number of fibers >= minAvailInBlock in the
		 * block can actually reach the target */
		nFiberTargets[i]=0;
		for(j=0;j<nFibers;j++) {
			block=(int) floor(j/nFibersBlock);
			if(nTargetBlocks[block]>=minAvailInBlock) {
				sep2=(xtarget[i]-xfiber[j])*(xtarget[i]-xfiber[j])+
					(ytarget[i]-yfiber[j])*(ytarget[i]-yfiber[j]);
				if(sep2<limit2) {
					fiberTargets[i*nFibers+nFiberTargets[i]]=j;
					nFiberTargets[i]++;
				} /* end if */
			} /* end if */
		} /* end for j */
	} /* end for i */

	/* calculate the number of arcs in the flow */
	nArcs=nTargets+nFibers+nBlocks+1;
	for(i=0;i<nTargets;i++) 
		nArcs+=nFiberTargets[i];

	/* calculate the number of nodes, total:
	 * targets + number of tiles + 2 for source & sink nodes */
  nNodes=nTargets+nFibers+nBlocks+2;  
															
  /* Write out the flow problem as an ascii file.  Node ids are as follows:
	 * 
	 *  0                                                 source node
	 *  1 - nTargets                                      target nodes
	 *  nTargets+1 - nTargets+nFibers                     fiber nodes
	 *  nTargets+nFibers+1 - nTargets+nFibers+nBlocks     block nodes
	 *  nNodes-1                                          sink node
	 */

  fp = fopen(probfile, "w");

	/* define the problem */
  fprintf(fp,"c Max flow problem for plug list\n");
  fprintf(fp,"p min %d %d\n", nNodes, nArcs);

	/* source node */
  fprintf(fp,"c source node\n");
  fprintf(fp,"n %d %d\n", 0, nMax);

	/* sink node */
  fprintf(fp,"c sink node\n");
  fprintf(fp,"n %d %d\n", nNodes-1, -nMax);

	/* one arc for each targets node */
  fprintf(fp,"c source to target arcs\n");
  for(i=0;i<nTargets;i++) 
		fprintf(fp,"a %d %d %d %d %d\n", 0, i+1, 0, 1, 0);

	/* one arc for each target to fiber connection */
  fprintf(fp, "c target to fiber arcs\n");
  for(i=0;i<nTargets;i++) {
		for(j=0;j<nFiberTargets[i];j++) {
			jFiber=fiberTargets[i*nFibers+j];
			sep2=(xtarget[i]-xfiber[jFiber])*(xtarget[i]-xfiber[jFiber])+
				(ytarget[i]-yfiber[jFiber])*(ytarget[i]-yfiber[jFiber]);
			cost=(long) floor(0.5*COSTFACTOR*sep2);
			fprintf(fp,"a %d %d %d %d %ld\n",i+1,nTargets+jFiber+1,0,1,cost);
		} /* end for j */
	} /* end for i */

	/* one arc for each fiber to block connection */
  fprintf(fp, "c fiber to block arcs\n");
  for(i=0;i<nFibers;i++) 
		fprintf(fp,"a %d %d %d %d %d\n",nTargets+i+1,
						nTargets+nFibers+i/nFibersBlock+1,0,1-fiberused[i],0);
		
	/* one arc for each block */
  fprintf(fp, "c block to sink arcs\n");
  for(i=0;i<nBlocks;i++) {
    fprintf(fp,"a %d %d %d %d %d\n", nTargets+nFibers+i+1, nNodes-1,
						minFibersInBlock, nFibersBlock, 0);
  } /* end for i */

	/* last arc for impossible galaxies */
  fprintf(fp,"c overflow arc\n");
  fprintf(fp,"a %d %d %d %d %d\n",0,nNodes-1,0,nFibers,100*COSTFACTOR);

  fprintf(fp,"c end of flow problem\n");
  fclose(fp);

	return(1);
} /* end write_plugprob */

int read_plugprob(double xtarget[],
									double ytarget[],
									int targetFiber[],
									int targetBlock[],
									int nTargets,
									int nFibersBlock,
									int nFibers,
									char ansfile[])
{
	char key[255],line[255];
	int i,iFiber,iTarget,tail,head,flow,nline=255;
	FILE *fp;

  /* Node ids are as follows:
	 * 
	 *  0                                                 source node
	 *  1 - nTargets                                      target nodes
	 *  nTargets+1 - nTargets+nFibers                     fiber nodes
	 *  nTargets+nFibers+1 - nTargets+nFibers+nBlocks     block nodes
	 *  nNodes-1                                          sink node
	 */

	for(i=0;i<nTargets;i++)
		targetFiber[i]=-1;

	printf("reading in result ...\n");
	fflush(stdout);
  fp=fopen(ansfile,"r");
  while(fgets(line,nline,fp)!=NULL) {
    sscanf(line,"%s",key);
		/* look for f */
    if(!(strcmp(key,"f"))) {
      sscanf(line,"%s %d %d %d",key,&tail,&head,&flow);
			if(tail>=1 && tail<=nTargets 
				 && head>=nTargets+1 && head<=nTargets+nFibers) {
				iTarget=tail-1;
				iFiber=head-nTargets-1;
				if(flow==1) {
					targetFiber[iTarget]=iFiber;
					targetBlock[iTarget]=iFiber/nFibersBlock;
				} else if (flow!=0) {
					fprintf(stderr,"Malformed arc in maxFlowPlugListRead!\n");
					return(0);
				} /* end if..else */
			} /* end if */
		} /* end if */
	} /* end while */	
	fclose(fp);

	for(i=0;i<nTargets;i++)
		if(targetFiber[i]==-1) {
			fprintf(stderr,"Missed a target (%d: %lf %lf)\n",i,xtarget[i],
							ytarget[i]);
			targetBlock[i]=-1;
		}

	printf("done reading ...\n");
	fflush(stdout);

	return(1);

} /* end read_plugprob */

