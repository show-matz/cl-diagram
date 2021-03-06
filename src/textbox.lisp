#|
#|ASD|#				(:file "textbox"                   :depends-on ("cl-diagram"
#|ASD|#																"rectangle"
#|ASD|#																"filter"
#|ASD|#																"text-shape"))
#|EXPORT|#				;textbox.lisp
 |#

(in-package :cl-diagram)

#|
#|EXPORT|#				:*default-textbox-rx*
#|EXPORT|#				:*default-textbox-ry*
#|EXPORT|#				:*default-textbox-align*
#|EXPORT|#				:*default-textbox-valign*
#|EXPORT|#				:*default-textbox-margin*
#|EXPORT|#				:*default-textbox-font*
#|EXPORT|#				:*default-textbox-fill*
#|EXPORT|#				:*default-textbox-stroke*
#|EXPORT|#				:*default-textbox-filter*
 |#
(defparameter *default-textbox-rx*           nil)
(defparameter *default-textbox-ry*           nil)
(defparameter *default-textbox-align*        :center)
(defparameter *default-textbox-valign*       :center)
(defparameter *default-textbox-margin*       10)
(defparameter *default-textbox-font*         nil)
(defparameter *default-textbox-fill*         nil)
(defparameter *default-textbox-stroke*       nil)
(defparameter *default-textbox-filter*       nil)

;;------------------------------------------------------------------------------
;;
;; class textbox
;;
;;------------------------------------------------------------------------------
(defclass textbox (text-shape)
  ((no-frame	:initform nil :initarg :no-frame)	; number
   (rx			:initform nil :initarg       :rx)	; number
   (ry			:initform nil :initarg       :ry)	; number
   (filter		:initform nil :initarg   :filter))) ; (or nil keyword)
  
(defmethod initialize-instance :after ((box textbox) &rest initargs)
  (declare (ignore initargs))
  (with-slots (filter) box
	(setf filter (if (eq filter :none)
					 nil
					 (or filter *default-textbox-filter* *default-shape-filter*))))
  box)
   
;; override of group::draw-group
(defmethod draw-group ((box textbox) writer)
  (let* ((canvas (group-get-canvas box))
		 (width  (canvas-width  canvas))
		 (height (canvas-height canvas)))
	(macrolet ((register-entity (entity)
				 `(check-and-draw-local-entity ,entity canvas writer)))
	  (with-slots (no-frame rx ry fill stroke filter) box
		(unless no-frame
		  ;; draw box
		  (rectangle (list (/ width 2) (/ height 2)) width height
					 :rx rx :ry ry
					 :fill fill :stroke stroke :filter filter)))))
  ;; draw text
  (call-next-method))

;; no override.
;(defmethod text-shape-calc-size ((box textbox))
;  (call-next-method))

;; no override.
;(defmethod text-shape-paragraph-area ((box textbox))
;  (call-next-method))

;;------------------------------------------------------------------------------
;;
;; macro textbox
;;
;;------------------------------------------------------------------------------
#|
#|EXPORT|#				:textbox
 |#
(defmacro textbox (center text &key no-frame rx ry width height align
								 valign font fill stroke margin link rotate layer id filter)
  `(register-entity (make-instance 'textbox
								   :no-frame ,no-frame
								   :center ,center
								   :width ,width :height ,height
								   :text ,text
								   :rx     (or ,rx     *default-textbox-rx*)
								   :ry     (or ,ry     *default-textbox-ry*)
								   :align  (or ,align  *default-textbox-align*)
								   :valign (or ,valign *default-textbox-valign*)
								   :margin (or ,margin *default-textbox-margin*)
								   :font   (or ,font   *default-textbox-font*)
								   :fill   (or ,fill   *default-textbox-fill*)
								   :stroke (or ,stroke *default-textbox-stroke*)
								   :link ,link  :rotate ,rotate
								   :filter ,filter :layer ,layer :id ,id)))

