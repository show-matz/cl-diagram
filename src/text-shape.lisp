#|
#|ASD|#				(:file "text-shape"                :depends-on ("cl-diagram"
#|ASD|#																"canvas"
#|ASD|#																"group"
#|ASD|#																"paragraph"
#|ASD|#																"font-info"
#|ASD|#																"fill-info"
#|ASD|#																"stroke-info"
#|ASD|#																"writer"))
#|EXPORT|#				;text-shape.lisp
 |#

(in-package :cl-diagram)

(defparameter *text-shape-font*       nil)
(defparameter *text-shape-fill*    :white)
(defparameter *text-shape-stroke*  :black)
(defparameter *text-shape-align*  :center)
(defparameter *text-shape-valign* :center)
(defparameter *text-shape-margin*      10)

;;------------------------------------------------------------------------------
;;
;; text-shape
;;
;;------------------------------------------------------------------------------
#|
#|EXPORT|#				:text-shape
#|EXPORT|#				:text-shape-calc-size
#|EXPORT|#				:text-shape-paragraph-area
 |#
(defclass text-shape (group)
  ((text	:initform nil :initarg :text)		; (or keyword string)
   (align	:initform nil :initarg :align)		; keyword
   (valign	:initform nil :initarg :valign)		; keyword
   (font	:initform nil :initarg :font)		; (or nil font-info)
   (fill	:initform nil :initarg :fill)		; (or nil fill-info)
   (stroke	:initform nil :initarg :stroke)		; (or nil stroke-info)
   (margin	:initform nil :initarg :margin)))	; number


; calc width & height of whole text-shape.
(defgeneric text-shape-calc-size (txtshp))	;; returns (values w h)

; generate canvas for paragraph inner text-shape.
(defgeneric text-shape-paragraph-area (txtshp))	;; returns canvas



(defmethod initialize-instance :after ((txtshp text-shape) &rest initargs)
  (declare (ignore initargs))
  (with-slots (align valign font fill stroke margin) txtshp
	(setf align   (or align  *text-shape-align*))
	(setf valign  (or valign *text-shape-valign*))
	(setf font    (make-font   (or font   *text-shape-font*   *default-font*  )))
	(setf fill    (make-fill   (or fill   *text-shape-fill*   *default-fill*  )))
	(setf stroke  (make-stroke (or stroke *text-shape-stroke* *default-stroke*)))
	(setf margin  (or margin *text-shape-margin*)))
  txtshp)

(defmethod check ((txtshp text-shape) canvas dict)
  (with-slots (text align valign font fill stroke margin) txtshp
	(check-member   text    :nullable nil :types string)
	(check-member   align   :nullable nil :types keyword)
	(check-member   valign  :nullable nil :types keyword)
	(check-object   font    canvas dict :nullable t :class   font-info)
	(check-object   fill    canvas dict :nullable t :class   fill-info)
	(check-object   stroke  canvas dict :nullable t :class stroke-info)
	(check-member   margin  :nullable nil :types number)
	(check-keywords align   :left :center :right)
	(check-keywords valign  :top  :center :bottom))
  ;; width, height のいずれか（または両方）が省略されている場合は計算で決定
  ;;MEMO : 明示的に w/h を指定された場合、テキストがはみ出す可能性があるがそれは仕方ない
  (with-slots (width height) txtshp
	(unless (and width height)
	  (multiple-value-bind (w h) (text-shape-calc-size txtshp)
		(setf width  (or width  w))
		(setf height (or height h)))))
  ;; this method must call super class' one.
  ;;MEMO : w/h が明示的に指定された場合にそれが数値であるかのチェックは下記の group::check で実施
  (call-next-method))


;; override of group::draw-group
(defmethod draw-group ((txtshp text-shape) writer)
  (let ((canvas (text-shape-paragraph-area txtshp)))
	(let ((width  (canvas-width  canvas))
		  (height (canvas-height canvas)))
	  (macrolet ((register-entity (entity)
				   `(check-and-draw-local-entity ,entity canvas writer)))
		(with-slots (text align valign font margin) txtshp
		  ;; draw text
		  (let ((x (ecase align
					 ((:left)   margin)
					 ((:center) (/ width 2))
					 ((:right)  (- width margin))))
				(y (ecase valign
					 ((:top)     margin)
					 ((:center) (/ height 2))
					 ((:bottom) (- height margin)))))
			(paragraph x y text :align align :valign valign :font font))))))
  nil)

;for debug...
;(defmethod post-draw ((obj text-shape) writer)
;  (call-next-method)
;  (draw-canvas-frame (shape-get-subcanvas obj) writer))
 

(defmethod text-shape-calc-size ((txtshp text-shape))
  (with-slots (text margin font) txtshp
	(multiple-value-bind (w h) (font-calc-textarea font text)
	  (values (+ (* margin 2) w)
			  (+ (* margin 2) h)))))

(defmethod text-shape-paragraph-area ((txtshp text-shape))
  (copy-canvas (group-get-canvas txtshp)))


;;(defmacro text-shape (x y text &key width height align valign font fill stroke margin link layer id)
;;  `(register-entity (make-instance 'text-shape
;;								   :center-x ,x :center-y ,y
;;								   :width ,width :height ,height
;;								   :text ,text :font ,font
;;								   :align ,align :valign ,valign
;;								   :fill ,fill :stroke ,stroke :margin ,margin
;;								   :link ,link :layer ,layer :id ,id)))

