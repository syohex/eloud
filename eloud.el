(setq eloud-speech-rate 270)
(setq eloud-espeak-path "/usr/bin/espeak")


(require 'cl)

(defun eloud-speak (string &optional speed no-kill &rest args)
  "Take a string and pass it to the espeak asynchronous process. Uses the eloud-speech-rate variable if no optional integer speed is specified. Pass additional arguments to espeak as rest arguments. If kill argument non-nil, running speech processes are killed before starting new speech process."
  ;; Defines a function that runs process on list of arguments.
  ;; Defines sensible defaults.
  ;; Run with defaults if no additional args specified in function call, else append additional arguments and run
  (cl-flet ((speak (full-args-list)
		(apply 'start-process full-args-list)))
    (let ((default-args `("eloud-speaking" nil ,eloud-espeak-path ,string "-s" ,(if speed (number-to-string speed) (number-to-string eloud-speech-rate)))))
      (progn
	(if (not no-kill)
	    (progn
	      (start-process "kill-espeak" nil "killall" "espeak")
	      (sleep-for .5)))
	(speak (if (not args)
		   default-args
		 (append default-args args)))))))

;;;;
;; Speech functions
;;;;

(defun eloud-rest-of-line (&optional pre)
  "Speak remainder of line aloud."
  (interactive "^p")
  (eloud-speak 
   (buffer-substring (point) (line-end-position))))

;; (move-beginning-of-line) function requires an additional argument (nil)
;; This function handles this requirement 
(defun eloud-rest-of-line-override (&rest r)
  (eloud-rest-of-line))


(defun eloud-whole-buffer ()
  "Speak whole buffer"
  (interactive)
  (eloud-speak
   (buffer-substring (point-min) (point-max))))


(defun eloud-status-info ()
  "Read status info normally on mode line."
  (interactive)
  (eloud-speak
   (concat (buffer-name) " " (symbol-name major-mode))))


(defun eloud-character-at-point ()
  "Read character at point aloud."
  (interactive)
  (eloud-speak
   (buffer-substring (point) (1+ (point)))
   nil t "--punct"))


(defun eloud-last-character (&rest r)
  (eloud-speak
   (buffer-substring (1- (point)) (point))
   eloud-speech-rate t "--punct"))


(defun eloud-word (&optional arg forward)
  "Reads arg words back or forward. If arg is nil, reads one word by default. If forward is non-nil, reads forward arg words instead."
  (interactive "^p")
  (progn
    (let ((start-point (point)))
      (save-excursion
	(progn
	  (if forward
	      (forward-word arg)
	    (backward-word arg))
	  (eloud-speak (buffer-substring start-point (point))))))))
	   
      


			
;;;;
;; Map speech functions to Emacs commands
;;;;


(setq advice-map '((next-line . eloud-rest-of-line)
		   (previous-line . eloud-rest-of-line)
		   (move-beginning-of-line . eloud-rest-of-line-override)
		   (forward-char . eloud-character-at-point)
		   (backward-char . eloud-character-at-point)
		   (self-insert-command . eloud-last-character)
		   (beginning-of-buffer . eloud-whole-buffer)))


(defun map-commands-to-speech-functions (advice-map &optional unmap)
  "Takes list of cons cells mapping movement commands to eloud speech functions. See variable advice-map for example. If optional upmap parameter is t, removes all bound advice functions instead."
  (mapcar (lambda (x)
	    (let ((target-function (car x))
		  (speech-function (cdr x)))
	      (if (not unmap)
		  (advice-add target-function :after speech-function)
		(advice-remove target-function speech-function))))
	  advice-map))

;;;;
;; Define mode
;;;;

(defun eloud-toggle ()
  "Toggles eloud on or off. Hooked on eloud-mode toggle. Use eloud-mode to turn eloud on or off."
  (if eloud-mode
      (progn
	(map-commands-to-speech-functions advice-map)
	(eloud-speak "eloud on"))
    (progn
      (map-commands-to-speech-functions advice-map t)
      (eloud-speak "eloud off"))))

(define-minor-mode eloud-mode "Minor mode for reading text aloud." nil " eloud" :global t)

(add-hook 'eloud-mode-hook 'eloud-toggle)


(provide 'eloud)
