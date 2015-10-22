pro test_alignment 

gnum=lindgen(16)+1 
theta= dindgen(16)*2.*!DPI/16. 
xg= 40.*cos(theta) 
yg= 40.*sin(theta) 
xg2= yg
yg2= -xg

splot, xg, yg, psym=4 

gfibertype='gfiber2' 
xa= dindgen(16) 
ya= dindgen(16) 
for i=0L, 15L do begin 
    alignment_fiber, gnum[i], xg[i], yg[i], tmp_xa, tmp_ya, gfibertype=gfibertype 
    xa[i]=tmp_xa 
    ya[i]=tmp_ya 
endfor 

gfibertype='gfiber_lco' 
xa2= dindgen(16) 
ya2= dindgen(16) 
for i=0L, 15L do begin 
    alignment_fiber, gnum[i], xg2[i], yg2[i], tmp_xa, tmp_ya, gfibertype=gfibertype 
    xa2[i]=tmp_xa 
    ya2[i]=tmp_ya 
endfor 

xa3= -ya2
ya3= xa2

for i=0L, 15L do begin
    soplot, [xg[i], xa[i]], [yg[i], ya[i]], th=3
    soplot, [xg[i], xa3[i]], [yg[i], ya3[i]], color='red' 
endfor

end
