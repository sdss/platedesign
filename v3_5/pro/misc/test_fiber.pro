xtarget= 2.*1.49*get_platescale('APO')*(randomu(seed,10000)-0.5)
ytarget= 2.*1.49*get_platescale('APO')*(randomu(seed,10000)-0.5)
rt=sqrt(xtarget^2+ytarget^2)

ii=(where(rt lt 1.49*get_platescale('APO')))[0:319]
xtarget1=xtarget[ii]
ytarget1=ytarget[ii]

ii=(where(rt lt 1.49*get_platescale('APO')))[320:639]
xtarget2=xtarget[ii]
ytarget2=ytarget[ii]

sdss_plugprob, xtarget1, ytarget1, fiberid1

sdss_plugprob, xtarget2, ytarget2, fiberid2, fiberused=[fiberid1,fiberid2]
