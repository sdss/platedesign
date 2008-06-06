int write_plugprob(double xtarget[],
									 double ytarget[],
									 int nTargets,
									 double xfiber[],
									 double yfiber[],
									 int fiberused[],
									 int nFibers,
									 int nFibersBlock,
									 double limitDegree, 
									 int minFibersInBlock,
									 char probfile[]);

int read_plugprob(double xtarget[],
									double ytarget[],
									int targetFiber[],
									int targetBlock[],
									int nTargets,
									int nFibersBlock,
									int nFibers,
									char ansfile[]);

