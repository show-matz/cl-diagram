#|
#|ASD|#				(:file "image"                     :depends-on ("cl-diagram"
#|ASD|#																"binutil"
#|ASD|#																"shape"
#|ASD|#																"label-info"
#|ASD|#																"link-info"
#|ASD|#																"point"
#|ASD|#																"filter"
#|ASD|#																"writer"))
#|EXPORT|#				;image.lisp
 |#


(in-package :cl-diagram)

;;------------------------------------------------------------------------------
;;
;; internal uutilities
;;
;;------------------------------------------------------------------------------
(defun __get-size-of-imagefile (file-name)
  (let ((img-type (string-downcase (pathname-type file-name))))
	(cond
	  ((string= img-type "png") ;----------------------------------------
	   (bin/with-read-stream (reader file-name)
		 (bin/seek-relative reader 16)
		 (values (bin/read-value :uint32 reader :endian :big)
				 (bin/read-value :uint32 reader :endian :big))))

	  ((or (string= img-type "jpg") ;------------------------------------
		   (string= img-type "jpeg"))
	   (bin/with-read-stream (reader file-name)
		 (bin/seek-relative reader 2) ; skip SOI mark
		 (let ((mark (bin/read-value :uint16 reader :endian :big))
			   (len  (bin/read-value :uint16 reader :endian :big)))
		   (do ()
			   ((= mark #xFFC0) nil)
			 (bin/seek-relative reader (- len 2))
			 (setf mark (bin/read-value :uint16 reader :endian :big))
			 (setf len  (bin/read-value :uint16 reader :endian :big)))
		   (bin/seek-relative reader 1)
		   (let ((height (bin/read-value :uint16 reader :endian :big))
				 (width  (bin/read-value :uint16 reader :endian :big)))
			 (values width height)))))

	  ((string= img-type "gif") ;----------------------------------------
	   (bin/with-read-stream (reader file-name)
		 (bin/seek-relative reader 6)
		 (values (bin/read-value :uint16 reader :endian :little)
				 (bin/read-value :uint16 reader :endian :little))))

	  ((string= img-type "bmp") ;----------------------------------------
	   (bin/with-read-stream (reader file-name)
		 ;; skip BITMAPFILEHEADER.
		 (bin/seek-relative reader 14)
		 ;; load bcSize ( 40 : windows bitmap, 12 : OS/2 bitmap )
		 (let ((bc-size (bin/read-value :uint32 reader :endian :little)))
		   (if (= bc-size 40)
			   (values (bin/read-value :uint32 reader :endian :little)
					   (bin/read-value :uint32 reader :endian :little))
			   (if (= bc-size 12)
				   (values (bin/read-value :uint16 reader :endian :little)
						   (bin/read-value :uint16 reader :endian :little)))))))

	  (t (values nil nil)))))
	   


;;------------------------------------------------------------------------------
;;
;; class image
;;
;;------------------------------------------------------------------------------
(defclass image (shape)
  ((filename		:initform nil :initarg :filename)	; (or string pathname)
   (width			:initform   0 :initarg :width)		; number
   (height			:initform   0 :initarg :height)		; number
   (center			:initform nil :initarg :center)		; point
   (label			:initform nil :initarg :label)		; (or nil label-info)
   (preserve-ratio	:initform nil)						; boolean
   (filter			:initform nil :initarg :filter)))	; (or nil keyword)


(defmethod initialize-instance :after ((img image) &rest initargs)
  (declare (ignore initargs))
  (with-slots (label filter) img
	(when label
	  (setf label (make-label label)))
	(setf filter (if (eq filter :none)
					 nil
					 (or filter *default-shape-filter*))))
  img)


(defmethod check ((img image) canvas dict)
  ;; this method must call super class' one.
  (call-next-method)
  (with-slots (center filename width height label preserve-ratio filter) img
	(check-member filename :nullable nil :types (or pathname string))
	(check-member width    :nullable   t :types number)
	(check-member height   :nullable   t :types number)
	(check-object label    canvas dict :nullable t :class label-info)
	(check-member filter   :nullable   t :types keyword)
	(let ((path (merge-pathnames filename (path/get-current-directory))))
	  ;; ?????????????????????????????????????????????????????????????????????????????????????????????????????????
	  (unless (path/is-existing-file path)
		(throw-exception "image file '~A' is not exist." path))
	  ;; width, height ????????????????????????????????????????????????????????????????????????????????????????????????
	  (if (and width height)
		  (setf preserve-ratio nil)
		  ;; ?????????????????????????????????????????????????????????????????????????????????
		  (multiple-value-bind (w h) (__get-size-of-imagefile path)
			;; width, height ??????????????? nil ????????????????????????????????????
			(if (and (null width) (null height))
				(setf width  w
					  height h)
				;; ???????????????????????????????????????????????????????????????????????? nil ????????????
				(if (null width)
					(setf width  (* height (/ w h)))
					(setf height (* width  (/ h w))))))))
	(check-member width  :nullable nil :types number)
	(check-member height :nullable nil :types number)
	(setf center (canvas-fix-point canvas center)))
  nil)


(defmethod shape-width ((img image))
  (slot-value img 'width))

(defmethod shape-height ((img image))
  (slot-value img 'height))

(defmethod shape-center ((img image))
  (slot-value img 'center))

;;MEMO : use impelementation of shape...
;;(defmethod shape-connect-point ((img image) type1 type2 arg) ...)
  
;;MEMO : use impelementation of shape...
;;(defmethod shape-get-subcanvas ((img image)) ...)

(defmethod entity-composition-p ((img image))
  (if (slot-value img 'label)
	  t
	  (call-next-method)))

(defmethod draw-entity ((img image) writer)
  (with-slots (width height filename preserve-ratio filter) img
	(let ((id (and (not (entity-composition-p img))
				   (slot-value img 'id)))
		  (topleft (shape-topleft img)))
	  (pre-draw img writer)
	  (writer-write writer
					"<image "
					(write-when id "id='" it "' ")
					"x='" (point-x topleft) "' "
					"y='" (point-y topleft) "' "
					"width='"  width  "' "
					"height='" height "' "
					"xlink:href='" filename "' "
					(unless preserve-ratio
					  "preserveAspectRatio='none' ")
					(write-when filter "filter='url(#" it ")' ")
					"/>")
	  (with-slots (label) img
		(when label
		  (draw-label label img writer)))
	  (post-draw img writer)))
  nil)


;;------------------------------------------------------------------------------
;;
;; macro image
;;
;;------------------------------------------------------------------------------
#|
#|EXPORT|#				:image
 |#
(defmacro image (center filename
				 &key width height label link rotate layer id filter contents)
  (let ((code `(register-entity (make-instance 'diagram:image
											   :center ,center
											   :filename ,filename
											   :width ,width :height ,height
											   :label ,label
											   :link ,link :rotate ,rotate
											   :filter ,filter :layer ,layer :id ,id))))
	(if (null contents)
		code
		(let ((g-obj (gensym "OBJ")))
		  `(let* ((,g-obj ,code)
				  (canvas (diagram:shape-get-subcanvas ,g-obj)))
			 (declare (special canvas))
			 ,@contents)))))

