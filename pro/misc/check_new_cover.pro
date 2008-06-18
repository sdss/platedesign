;+
; NAME:
;   check_new_cover
;-
;------------------------------------------------------------------------------
pro check_new_cover

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')

for i=3015L, 3028L do begin
    ip=where(plans.plateid eq i)
    designid=plans[ip].designid
    dumdum= yanny_readone(getenv('PLATELIST_DIR')+'/definitions/0000XX/'+ $
                          'plateDefinition-'+$
                          strtrim(string(designid, f='(i6.6)'),2)+ $
                          '.par', hdr=hdr)
    def= lines2struct(hdr)
    
    design= yanny_readone(design_dir(designid)+'/plateDesign-'+ $
                          strtrim(string(designid, f='(i6.6)'),2)+'.par')
    
    p1= yanny_readone(getenv('PLATELIST_DIR')+'/inputs/'+ $
                      def.plateinput1)
    p2= yanny_readone(getenv('PLATELIST_DIR')+'/inputs/'+ $
                      def.plateinput1)

    spherematch, p1.ra, p1. dec, design.target_ra, design.target_dec, $
      1./3600., m1, m2, d12
    got1=lonarr(n_elements(p1))
    got1[m1]=1
    help, got1
    help, where(got1)
    print,got1

    spherematch, p2.ra, p2. dec, design.target_ra, design.target_dec, $
      1./3600., m1, m2, d12
    got2=lonarr(n_elements(p2))
    got2[m1]=1
    help, got2
    help, where(got2)
    print,got2
    
    
endfor

end
