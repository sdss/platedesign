;+
; Determine if the underlying collection has another element to retrieve.
;
; @returns 1 if underlying collection has another element, 0 otherwise
;-
function mgarraylistiterator::hasNext
    compile_opt strictarr

    return, self.pos lt self.arraylist->count()
end


;+
; Return the next item in the underlying collection.
;
; @returns list item
;-
function mgarraylistiterator::next
    compile_opt strictarr
    on_error, 2

    if (self.pos ge self.arraylist->count()) then begin
       message, 'No more elements'
    endif

    self.arraylist->getProperty, version=version
    if (self.version ne version) then begin
       message, 'Underlying collection has changed'
    endif


    return, self.arraylist->get(position=self.pos++)
end


;+
; Removes from the underlying MGArrayList the last element returned.
;-
pro mgarraylistiterator::remove
    compile_opt strictarr
    on_error, 2

    self.arraylist->getProperty, version=version
    if (self.version ne version) then begin
       message, 'Underlying collection has changed'
    endif

    if (self.pos le 0) then begin
        message, 'No element to remove'
    endif

    self.arraylist->remove, position=--self.pos
    self.arraylist->getProperty, version=version
    self.version = version
end


;+
; Free resources of the iterator (not the underlying collection).
;-
pro mgarraylistiterator::cleanup
    compile_opt strictarr

end


;+
; Initialize an MGArrayListIterator.
;
; @returns 1 for success, 0 otherwise
; @param arraylist {in}{required}{type=object} MGArrayList to iterator over
;-
function mgarraylistiterator::init, arraylist
    compile_opt strictarr

    self.arraylist = arraylist
    self.arraylist->getProperty, version=version
    self.version = version

    self.pos = 0

    return, 1B
end


;+
; Define member variables.
;
; @file_comments This class provides a nice way to iterate through all the 
;                elements of an ArrayList.
; @requires IDL 6.0
; @field arraylist arraylist being interated over
; @field version arraylist version when iterator is created
; @field pos position of the next element in the ArrayList to be returned by the
;       "next" method
;-
pro mgarraylistiterator__define
    compile_opt strictarr

    define = { mgarraylistiterator, inherits mgabstractiterator, $
               arraylist : obj_new(), $
               pos : 0L $
             }
end
