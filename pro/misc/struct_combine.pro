;+
; NAME:
;   struct_combine
; PURPOSE:
;   Combine two (one-element) structures with overlapping tag names
; CALLING SEQUENCE:
;   str3= struct_combine(str1, str2)
; INPUTS:
;   str1, str2 - input structures
; OUTPUTS:
;   str3 - output structure
; COMMENTS:
;   For overlapping tag names, str2 values and types are used
; REVISION HISTORY:
;   May 7, 2008, MRB, NYU
;-
;------------------------------------------------------------------------------
function struct_combine, str1, str2

names1=tag_names(str1)
names2=tag_names(str2)

;; don't use elements in 1 that are also in 2
use1=bytarr(n_elements(names1))+1
for i=0L, n_elements(names1)-1L do begin
    isame=where(names2 eq names1[i], nsame)
    if(nsame gt 0) then begin
        use1[i]=0
    endif
endfor
iuse1=where(use1, nuse1)

if(nuse1 eq 0) then return, str2

str3=create_struct(names1[iuse1[0]], str1.(iuse1[0]))

for i=1L, nuse1-1L do $
      str3=create_struct(str3, names1[iuse1[i]], str1.(iuse1[i]))

for i=0L, n_elements(names2)-1L do $
      str3=create_struct(str3, names2[i], str2.(i))

return, str3

end
