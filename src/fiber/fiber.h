int write_plugprob(double xtarget[],
									 double ytarget[],
									 int nTargets,
									 double xfiber[],
									 double yfiber[],
									 int fiberblockid[],
									 int fiberused[],
									 int toblock[],
									 int nFibers,
									 int nMax,
									 double limitDegree, 
									 int fiberTargetsPossible[],
									 int inputPossible,
									 int minAvailInBlock,
									 int minFibersInBlock,
									 int maxFibersInBlock,
									 double blockcenx[],
									 double blockceny[],
									 int blockconstrain,
									 int nBlocks,
									 char probfile[], 
									 int noycost, 
									 double blockylimits[]);

int read_plugprob(double xtarget[],
									double ytarget[],
									int targetFiber[],
									int targetBlock[],
									int nTargets,
									int fiberblockid[],
									int nFibers,
									int quiet,
									char ansfile[]);

