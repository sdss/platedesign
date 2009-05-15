int write_plugprob(double xtarget[],
									 double ytarget[],
									 int nTargets,
									 double xfiber[],
									 double yfiber[],
									 int fiberused[],
									 int toblock[],
									 int nFibers,
									 int nMax,
									 int nFibersBlock,
									 double limitDegree, 
									 int minAvailInBlock,
									 int minFibersInBlock,
									 int maxFibersInBlock,
									 double blockcenx[],
									 double blockceny[],
									 int blockconstrain,
									 char probfile[], 
									 int noycost, 
									 double blockylimits[]);

int read_plugprob(double xtarget[],
									double ytarget[],
									int targetFiber[],
									int targetBlock[],
									int nTargets,
									int nFibersBlock,
									int nFibers,
									int quiet,
									char ansfile[]);

