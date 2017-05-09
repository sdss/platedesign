#include <stdlib.h>
#include <stdio.h>
#include <math.h>

/****************************************************************
*****************************************************************
**
** <AUTO>
**
** ROUTINE: plAnneal, with associated functions.
**  the functions ran3, metrop, revcst, reverse, trncst, trnspt 
**  are only used within plAnneal.
**
** DESCRIPTION:
** Numerical Recipes function anneal, used to create a path 
** for drilling the plate. It calculates an optimum (shortest) 
** path to drill the plate.
** Using simulated annealling, this attempts to find the minimum
** path length to traverse a list of x,y by shuffling the order.
**
** This is almost the exact N.R. routine pasted in here, with the 
** exception that the loop repeats until MAX_ITER iterations is 
** reached, or if the path length stays the same for MAX_REPEATS
** repeats in a row. (saves it from running MAX_ITER times on 
** a very-nearly optimal path)
**
** </AUTO>
**
** Authors:
**   Jun 1999, A.Merrelli added this as part of W. Siegmund's 
**   plate code.
**
***************************************************************** 
*****************************************************************/

#define MBIG 1000000000
#define MSEED 161803398
#define MZ 0
#define FAC (1.0/MBIG)
float ran3(long *idum)
{
	static int inext,inextp;
	static long ma[56];
	static int iff=0;
	long mj,mk;
	int i,ii,k;

	if (*idum < 0 || iff == 0) {
		iff=1;
		mj=MSEED-(*idum < 0 ? -*idum : *idum);
		mj %= MBIG;
		ma[55]=mj;
		mk=1;
		for (i=1;i<=54;i++) {
			ii=(21*i) % 55;
			ma[ii]=mk;
			mk=mj-mk;
			if (mk < MZ) mk += MBIG;
			mj=ma[ii];
		}
		for (k=1;k<=4;k++)
			for (i=1;i<=55;i++) {
				ma[i] -= ma[1+(i+30) % 55];
				if (ma[i] < MZ) ma[i] += MBIG;
			}
		inext=0;
		inextp=31;
		*idum=1;
	}
	if (++inext == 56) inext=1;
	if (++inextp == 56) inextp=1;
	mj=ma[inext]-ma[inextp];
	if (mj < MZ) mj += MBIG;
	ma[inext]=mj;
	return mj*FAC;
}
#undef MBIG
#undef MSEED
#undef MZ
#undef FAC




#define IB1 1
#define IB2 2
#define IB5 16
#define IB18 131072
int irbit1(unsigned long *iseed)
{
	unsigned long newbit;

	newbit = (*iseed & IB18) >> 17
		^ (*iseed & IB5) >> 4
		^ (*iseed & IB2) >> 1
		^ (*iseed & IB1);
	*iseed=(*iseed << 1) | newbit;
	return (int) newbit;
}
#undef IB1
#undef IB2
#undef IB5
#undef IB18


#define ALEN(a,b,c,d) sqrt(((b)-(a))*((b)-(a))+((d)-(c))*((d)-(c)))

float trncst(float x[], float y[], int iorder[], int ncity, int n[])
{
	float xx[7],yy[7],de;
	int j,ii;

	n[4]=1 + (n[3] % ncity);
	n[5]=1 + ((n[1]+ncity-2) % ncity);
	n[6]=1 + (n[2] % ncity);
	for (j=1;j<=6;j++) {
		ii=iorder[n[j]];
		xx[j]=x[ii];
		yy[j]=y[ii];
	}
	de = -ALEN(xx[2],xx[6],yy[2],yy[6]);
	de -= ALEN(xx[1],xx[5],yy[1],yy[5]);
	de -= ALEN(xx[3],xx[4],yy[3],yy[4]);
	de += ALEN(xx[1],xx[3],yy[1],yy[3]);
	de += ALEN(xx[2],xx[4],yy[2],yy[4]);
	de += ALEN(xx[5],xx[6],yy[5],yy[6]);
	return de;
}



void trnspt(int iorder[], int ncity, int n[])
{
	int m1,m2,m3,nn,j,jj,*jorder;

	jorder = (int *) malloc((ncity+2) * sizeof(int));
	/*	jorder=ivector(1,ncity);*/
	m1=1 + ((n[2]-n[1]+ncity) % ncity);
	m2=1 + ((n[5]-n[4]+ncity) % ncity);
	m3=1 + ((n[3]-n[6]+ncity) % ncity);
	nn=1;
	for (j=1;j<=m1;j++) {
		jj=1 + ((j+n[1]-2) % ncity);
		jorder[nn++]=iorder[jj];
	}
	if (m2>0) {
		for (j=1;j<=m2;j++) {
			jj=1+((j+n[4]-2) % ncity);
			jorder[nn++]=iorder[jj];
		}
	}
	if (m3>0) {
		for (j=1;j<=m3;j++) {
			jj=1 + ((j+n[6]-2) % ncity);
			jorder[nn++]=iorder[jj];
		}
	}
	for (j=1;j<=ncity;j++)
		iorder[j]=jorder[j];
	free((char *) jorder);
	/*	free_ivector(jorder,1,ncity);*/
}


float revcst(float x[], float y[], int iorder[], int ncity, int n[])
{
	float xx[5],yy[5],de;
	int j,ii;

	n[3]=1 + ((n[1]+ncity-2) % ncity);
	n[4]=1 + (n[2] % ncity);
	for (j=1;j<=4;j++) {
		ii=iorder[n[j]];
		xx[j]=x[ii];
		yy[j]=y[ii];
	}
	de = -ALEN(xx[1],xx[3],yy[1],yy[3]);
	de -= ALEN(xx[2],xx[4],yy[2],yy[4]);
	de += ALEN(xx[1],xx[4],yy[1],yy[4]);
	de += ALEN(xx[2],xx[3],yy[2],yy[3]);
	return de;
}

void reverse(int iorder[], int ncity, int n[])
{
	int nn,j,k,l,itmp;

	nn=(1+((n[2]-n[1]+ncity) % ncity))/2;
	for (j=1;j<=nn;j++) {
		k=1 + ((n[1]+j-2) % ncity);
		l=1 + ((n[2]-j+ncity) % ncity);
		itmp=iorder[k];
		iorder[k]=iorder[l];
		iorder[l]=itmp;
	}
}


int metrop(float de, float t)
{
	float ran3(long *idum);
	static long gljdum=1;

	return de < 0.0 || ran3(&gljdum) < exp(-de/t);
}


#define T_INIT		0.5
#define NOVER_MAX	40
#define MAX_ITER        100
#define MAX_REPEATS      3

int anneal ( float in_x[], float in_y[], int in_iorder[], int ncity, float tfactor )

{

  int numRepeats=0, *iorder;
  float lastLength, *x, *y;

  int ans,nover,nlimit,i1,i2;
  int i,j,k,nsucc,nn,idec;
  static int n[7];
  long idum;
  unsigned long iseed;
  float path,de,t;

	x = in_x - 1;
	y = in_y - 1;
	iorder = in_iorder - 1;

  nover=NOVER_MAX*ncity;
  nlimit=NOVER_MAX*ncity/10;
  path=0.0;
  t=T_INIT;

  for (i=1;i<ncity;i++) {
    i1=iorder[i];
    i2=iorder[i+1];
    path += ALEN(x[i1],x[i2],y[i1],y[i2]);
  }

  i1=iorder[ncity];
  i2=iorder[1];
  path += ALEN(x[i1],x[i2],y[i1],y[i2]);
  idum = -1;
  iseed=111;

  lastLength = path;
  j=0;
  numRepeats=0;
  do {
    nsucc=0;
    for (k=1;k<=nover;k++) {
      do {
	n[1]=1+(int) (ncity*ran3(&idum));
	n[2]=1+(int) ((ncity-1)*ran3(&idum));
	if (n[2] >= n[1]) ++n[2];
	nn=1+((n[1]-n[2]+ncity-1) % ncity);
      } while (nn<3);
      idec=irbit1(&iseed);
      if (idec == 0) {
	n[3]=n[2]+(int) (abs(nn-2)*ran3(&idum))+1;
	n[3]=1+((n[3]-1) % ncity);
	de=trncst(x,y,iorder,ncity,n);
	ans=metrop(de,t);
	if (ans) {
	  ++nsucc;
	  path += de;
	  trnspt(iorder,ncity,n);
	}
      } else {
	de=revcst(x,y,iorder,ncity,n);
	ans=metrop(de,t);
	if (ans) {
	  ++nsucc;
	  path += de;
	  reverse(iorder,ncity,n);
	}
      }
      if (nsucc >= nlimit) break;
    }
    j++;
    if(lastLength == path)
      numRepeats++;
    else
      numRepeats = 0;
    lastLength = path;
    t *= tfactor;
  } while ((numRepeats < MAX_REPEATS) && (j < MAX_ITER));

	return(0);
}

#undef MAX_ITER
#undef T_INIT
#undef NOVER_MAX
