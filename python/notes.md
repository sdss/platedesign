This is a collection of notes for a potential platedesign rewrite.

#### Preflight

Code that will verify input files for consistancy and survey-specific constraints. This is run before platedesign.

** All Surveys **

 * Check all input for the presence of `NaN` or `inf` values, stop if any are found
 
** BOSS **

 * Check that the `chunk` field is in the form of "chunkNNN".
 
** APOGEE-2 **

** MaNGA **



#### Plate Design



#### Postflight

Code that will verify the outputs of the platedesign.