#|
#|ASD|#				(:file "folder"                    :depends-on ("cl-diagram"
#|ASD|#																"polygon"
#|ASD|#																"filter"
#|ASD|#																"text-shape"))
#|EXPORT|#				;folder.lisp
 |#

(in-package :cl-diagram)

#|
#|EXPORT|#				:*default-folder-tabwidth*
#|EXPORT|#				:*default-folder-tabheight*
#|EXPORT|#				:*default-folder-align*
#|EXPORT|#				:*default-folder-valign*
#|EXPORT|#				:*default-folder-margin*
#|EXPORT|#				:*default-folder-font*
#|EXPORT|#				:*default-folder-fill*
#|EXPORT|#				:*default-folder-stroke*
#|EXPORT|#				:*default-folder-filter*
 |#
(defparameter *default-folder-tabwidth*     50)
(defparameter *default-folder-tabheight*    20)
(defparameter *default-folder-align*        :center)
(defparameter *default-folder-valign*       :center)
(defparameter *default-folder-margin*       10)
(defparameter *default-folder-font*         nil)
(defparameter *default-folder-fill*         nil)
(defparameter *default-folder-stroke*       nil)
(defparameter *default-folder-filter*       nil)

;;------------------------------------------------------------------------------
;;
;; class folder
;;
;;------------------------------------------------------------------------------
(defclass folder (text-shape)
  ((tab-width	:initform nil :initarg :tab-width)    ; number
   (tab-height	:initform nil :initarg :tab-height)   ; number
   (filter		:initform nil :initarg :filter)))     ; (or nil keyword)

(defmethod initialize-instance :after ((fldr folder) &rest initargs)
  (declare (ignore initargs))
  (with-slots (filter) fldr
	(setf filter (if (eq filter :none)
					 nil
					 (or filter *default-folder-filter* *default-shape-filter*))))
  fldr)
  
(defmethod check ((fldr folder) canvas dict)
  ;; this method must call super class' one.
  (call-next-method)
  (with-slots (filter) fldr
	(check-member filter    :nullable   t :types keyword))
  nil)

;; override of group::draw-group
(defmethod draw-group ((box folder) writer)
  (let* ((canvas (group-get-canvas box))
		 (width  (canvas-width  canvas))
		 (height (canvas-height canvas)))
	(macrolet ((register-entity (entity)
				 `(check-and-draw-local-entity ,entity canvas writer)))
	  (with-slots (tab-width tab-height fill stroke filter) box
		(let ((tab-w tab-width)
			  (tab-h tab-height))
		  ;; draw box
		  (polygon `((0 0) (0 ,height)
					 (,width ,height)
					 (,width ,(/ tab-h 2))
					 (,(- width (/ tab-h 2)) 0)
					 (,tab-w 0)
					 (,(- tab-w (/ tab-h 2)) ,(- (/ tab-h 2)))
					 (,(/ tab-h 2) ,(- (/ tab-h 2)))
					 (0 0)) :fill fill :stroke stroke :filter filter)
		  (polygon `((0 0)
					 (,(/ tab-h 2) ,(/ tab-h 2))
					 (,(- tab-w (/ tab-h 2)) ,(/ tab-h 2))
					 (,tab-w 0)
					 (,(- tab-w (/ tab-h 2)) ,(- (/ tab-h 2)))
					 (,(/ tab-h 2) ,(- (/ tab-h 2)))
					 (0 0)) :fill fill :stroke stroke :filter :none)))))
  ;; draw text
  (call-next-method))

;; no override.
;(defmethod text-shape-calc-size ((box folder))
;  (call-next-method))

;; no override.
;(defmethod text-shape-paragraph-area ((box folder))
;  (call-next-method))

;;------------------------------------------------------------------------------
;;
;; macro folder
;;
;;------------------------------------------------------------------------------
#|
#|EXPORT|#				:folder
 |#
(defmacro folder (center text &key width height tab-width tab-height align
								   valign font fill stroke margin link rotate layer filter id contents)
  (let ((code `(register-entity (make-instance 'folder
											   :center ,center
											   :width ,width :height ,height
											   :text ,text
											   :tab-width  (or ,tab-width   *default-folder-tabwidth*)
											   :tab-height (or ,tab-height  *default-folder-tabheight*)
											   :align  (or ,align  *default-folder-align*)
											   :valign (or ,valign *default-folder-valign*)
											   :margin (or ,margin *default-folder-margin*)
											   :font   (or ,font   *default-folder-font*)
											   :fill   (or ,fill   *default-folder-fill*)
											   :stroke (or ,stroke *default-folder-stroke*)
											   :link ,link :rotate ,rotate
											   :filter ,filter :layer ,layer :id ,id))))
	(if (null contents)
		code
		(let ((g-obj (gensym "OBJ")))
		  `(let* ((,g-obj ,code)
				  (canvas (diagram:shape-get-subcanvas ,g-obj)))
			 (declare (special canvas))
			 ,@contents)))))

