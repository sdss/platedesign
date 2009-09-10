pro check_reachcheck

x=2.5*randomu(seed, 100000)-1.25
y=2.5*randomu(seed, 100000)-1.25

xf=0
yf=-0.1

xh=x+xf
yh=y+yf

ir=where(boss_reachcheck(xf, yf, xh,yh))

scale=217.7358*0.1
splot, xh*scale, yh*scale, psym=3
soplot, xh[ir]*scale, yh[ir]*scale, psym=3, color='red'

end
