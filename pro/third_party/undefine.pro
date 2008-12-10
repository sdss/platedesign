; Procedure to undefine an IDL variable.
; It's completely obvious now, isn't it?? Stupid IDL.
;
; http://www.dfanning.com/tips/variable_undefine.html
;
PRO UNDEFINE, varname  
   tempvar = SIZE(TEMPORARY(varname))
END
   