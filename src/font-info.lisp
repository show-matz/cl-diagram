#|
#|ASD|#				(:file "font-info"                 :depends-on ("cl-diagram"))
#|EXPORT|#				;font-info.lisp
 |#


(in-package :cl-diagram)

;; default parameter for font-info
#|
#|EXPORT|#				:*default-font*
 |#
(defparameter *default-font* nil)

;;------------------------------------------------------------------------------
;;
;; font-info
;;
;;------------------------------------------------------------------------------
#|
#|EXPORT|#				:font-info
 |#
(defclass font-info ()
  ((family			;:type     string
					:initform nil
					:initarg  :family
					:accessor font-family)
   (size			;:type     number
					:initform nil
					:initarg  :size
					:accessor font-size)
   (color			;:type     (or keyword or string)
					:initform nil
					:initarg  :color
					:accessor font-color)
   (style			;:type list	;;  :normal :italic :oblique
					:initform nil
					:initarg :style
					:accessor font-style)
   (decoration		;:type list
					:initform nil
					:initarg :decoration
					:accessor font-decoration)
   (weight			;:type list
					:initform nil
					:initarg :weight
					:accessor font-weight)
   (line-spacing	;:type list
					:initform nil
					:initarg :line-spacing
					:accessor font-line-spacing)
   (width-spice		;:type list
					:initform nil
					:initarg :width-spice
					:accessor font-width-spice)))


(defmethod initialize-instance :after ((font font-info) &rest initargs)
  (declare (ignore initargs))
  font)

(defmethod check ((ent font-info) canvas dict)
  (declare (ignore canvas dict))
  (check-member (family       (font-family       ent)) :nullable   t :types string)
  (check-member (size         (font-size         ent)) :nullable   t :types number)
  (check-member (color        (font-color        ent)) :nullable   t :types (or string keyword))
  (check-member (style        (font-style        ent)) :nullable   t :types keyword)
  (check-member (decoration   (font-decoration   ent)) :nullable   t :types keyword)
  (check-member (weight       (font-weight       ent)) :nullable   t :types (or fixnum keyword))
  (check-member (line-spacing (font-line-spacing ent)) :nullable nil :types number)
  (check-member (width-spice  (font-width-spice  ent)) :nullable nil :types number)
  (when (font-style ent)
	(check-keywords (style (font-style ent)) :normal :italic :oblique))
  (when (font-decoration ent)
	(check-keywords (decoration (font-decoration ent))
					:none :underline :overline :line-through))
  (when (keywordp (font-weight ent))
	(check-keywords (weight (font-weight ent)) :normal :bold :bolder :lighter))
  (when (numberp (font-weight ent))
	(check-numbers (weight (font-weight ent)) 100 200 300 400 500 600 700 800 900))
  nil)

(defmethod to-property-strings ((fnt font-info))
  (macrolet ((add-when (member &rest args)
			   `(let ((it ,member))
				  (when it
					(setf buf (concatenate 'string buf (format-string ,@args)))))))
	(let ((buf ""))
	  (add-when (font-family     fnt)     "font-family='" it "' ")
	  (add-when (font-size       fnt)       "font-size='" it "pt' ")
	  (add-when (font-color      fnt)            "fill='" it "' ")
	  (add-when (font-style      fnt)      "font-style='" it "' ")
	  (add-when (font-decoration fnt) "text-decoration='" it "' ")
	  (add-when (font-weight     fnt)     "font-weight='" it "' ")
	  buf)))

(defmethod to-style-strings ((fnt font-info))
  (macrolet ((add-when (member &rest args)
			   `(let ((it ,member))
				  (when it
					(setf buf (concatenate 'string buf (format-string ,@args)))))))
	(let ((buf ""))
	  (add-when (font-family     fnt)     "font-family: " it "; ")
	  (add-when (font-size       fnt)       "font-size: " it "pt; ")
;;	  (add-when (font-color      fnt)            "fill: " it "; ")	;;ToDo : スタイルシート内部で、fill-info とカブるけど？
	  (add-when (font-style      fnt)      "font-style: " it "; ")
	  (add-when (font-decoration fnt) "text-decoration: " it "; ")
	  (add-when (font-weight     fnt)     "font-weight: " it "; ")
	  buf)))


#|
#|EXPORT|#				:make-font
 |#
(defun make-font (&rest params)
  (if (= 1 (length params))
	  (let ((param (car params)))
		(cond
		  ((typep param 'font-info) param)
		  ((numberp param) (make-font :size   param))
		  ((listp   param) (apply #'make-font param))
		  (t               (make-font :family param))))
	  (if (and (null params) *default-font*)
		  *default-font*
		  (destructuring-bind (&key (family       nil       family-p)
									(size         nil         size-p)
									(color        nil        color-p)
									(style        nil        style-p)
									(decoration   nil   decoration-p)
									(weight       nil       weight-p)
									(width-spice  nil  width-spice-p)
									(line-spacing nil line-spacing-p) base) params
			(let ((base (or base *default-font*)))
			  (labels ((fixval (val-p val base-fnc default)
						 (if val-p val (if base (funcall base-fnc base) default))))
				(make-instance 'font-info
							   :family       (fixval family-p       family       #'font-family       nil)
							   :size         (fixval size-p         size         #'font-size          12)
							   :color        (fixval color-p        color        #'font-color     :black)
							   :style        (fixval style-p        style        #'font-style        nil)
							   :decoration   (fixval decoration-p   decoration   #'font-decoration   nil)
							   :weight       (fixval weight-p       weight       #'font-weight       nil)
							   :width-spice  (fixval width-spice-p  width-spice  #'font-width-spice 0.65)
							   :line-spacing (fixval line-spacing-p line-spacing #'font-line-spacing   2))))))))

#|
#|EXPORT|#				:font-calc-textarea
 |#
(defun font-calc-textarea (font text)
  (let ((lst     (string/split text #\newline))
		(size    (font-size         font))
		(spice   (font-width-spice  font))
		(spacing (font-line-spacing font)))
	(let ((line-count (length lst))
		  (width-fnc  (lambda (line)
						(* (length line) size spice))))    ;ToDo : what can I do ?
	  ;;ToDo : implement... fix width-fnc.
	  (values (apply #'max (mapcar width-fnc lst))
			  (+ (* size line-count)
				 (* spacing (1- line-count)))))))


(setf *default-font* (make-font :family        nil
								:size           12
								:color      :black
								:style         nil
								:decoration    nil
								:weight        nil
								:width-spice  0.65
								:line-spacing    2))

;;(to-property-strings (make-font))
;;(to-property-strings (make-font "Courier New"))
;;(to-property-strings (make-font 18))
;;(to-property-strings (make-font :family "Vernada" :color :red :size 10))
;;(to-property-strings (make-font '(:family "Vernada" :color :red :size 10)))


