;;  Sustained Attention to Response Task (SART)
;;
;;  In each trial the participant sees a letter: "O" or "Q".
;;  They must press a key every time an O appears (90% of trials),
;;  but withhold their response when the stimulus is a Q (10% of trials).
;;
;;  Cognitive Modelling Practical 2025
;;  Updated for ACT-R 7.21 by Loran Knol
;;  2025-01-21 Refactored for ACT-R 7.28 by Stephen Jones


;;===================;;
;;  Experiment code  ;;
;;===================;;


;; Experiment settings
(defvar *stimulus-duration* 2) ; number of seconds the stimulus is shown
(defvar *inter-stimulus-interval* 0.5) ; number of seconds between trials
(defvar *target-trials* 216) ; number of target trials
(defvar *non-target-trials* 24) ; number of non-target trials

(defvar *output-directory* "/Users/hinkebolt/Documents/Artificial Intelligence/Cognitive Modeling Practical/Assignment 6/output/") ; location where output files are stored
(defvar *trace-to-file-only* nil) ; whether the model trace should only be saved to file and not appear in terminal
(defvar *trace-file-name* "sart-trace") ; name of file in which the trace is stored

(defvar *terminal-stream* *standard-output*) ; necessary for stream management

(defvar *visible* nil) ; visibility of the experiment window

;; Global variables for data storage
(defvar *stimuli* nil)
(defvar *trial-response* nil)
(defvar *trial-start* nil)
(defvar *trial-rt* nil)
(defvar *trial-done* nil)
(defvar *all-responses* nil)
(defvar *all-rts* nil)

;; Parallellism management
(defvar *lock* (bt:make-lock))

;;================================;;
;; recording and output functions ;;
;;================================;;

;; Register the model's key presses (ignore the model parameter)
(defun key-event-handler (model key)
  (declare (ignore model))

  ; Prevent race conditions
  (bt:with-lock-held
  (*lock*)
    (setf *trial-rt* (/ (- (get-time) *trial-start*) 1000.0))
    (setf *trial-response* (string key))
    (setf *trial-done* t))
)

;; Write the behavioural results to a file
(defun write-results-to-file (name participant stimuli responses rts)
  (with-open-file
    (out
      (ensure-directories-exist
        (merge-pathnames
          (make-pathname :name name :type "csv")
          *output-directory*))
      :direction :output :if-does-not-exist :create :if-exists :supersede)
    (format out "participant, trial, stimulus, response, rt~%")
    (loop
      for trial from 1
      for stimulus in stimuli
      for response in responses
      for rt in rts
      do (format out "~a, ~a, ~a, ~a, ~a~%" participant trial stimulus response rt)))
)

;;======================;;
;; Experiment functions ;;
;;======================;;

;; Execute a trial with a given stimulus
(defun run-trial (stim)
  (let ((window (open-exp-window "SART Experiment"
                               :visible *visible*
                               :width 300
                               :height 300
                               :x 300
                               :y 300)))

    (add-text-to-exp-window window
                            stim
                            :width 30
                            :height 30
                            :x 145
                            :y 150)

  (add-act-r-command
    "sart-key-press"
    'key-event-handler
    "SART task key press monitor")
  (monitor-act-r-command "output-key" "sart-key-press")

  (setf *trial-response* nil)
  (setf *trial-start* (get-time))
  (setf *trial-rt* nil)
  (setf *trial-done* nil)

  (install-device window)
  (run-full-time *stimulus-duration* *visible*)
  (clear-exp-window)
  (run-full-time *inter-stimulus-interval* *visible*)

  (remove-act-r-command-monitor "output-key" "sart-key-press")
  (remove-act-r-command "sart-key-press"))

  ; Prevent race conditions
  (bt:with-lock-held
    (*lock*)
    (push *trial-response* *all-responses*)
    (push *trial-rt* *all-rts*))
)


;; Do SART experiment 1 time
(defun do-sart ()
  (setf *all-responses* nil)
  (setf *all-rts* nil)
  (setf *stimuli*
    (permute-list
      (concatenate
        'list
        (make-array *target-trials* :initial-element "O")
        (make-array *non-target-trials* :initial-element "Q"))))
  (setf *visible* nil)
  (loop for stim in *stimuli* do (run-trial stim))
)

;; Do a single SART trial with a target stimulus
(defun do-sart-trial-o ()
  (setf *visible* t)
  (run-trial "O")
)

;; Do a single SART trial with a non-target stimulus
(defun do-sart-trial-q ()
  (setf *visible* t)
  (run-trial "Q")
)

(defun stop-meditating ()
  (pdisable focus-retrieval breath wander-retrieval daydream-about-intention daydream refresh-focus remember-to-focus)
  (write "Stop meditating"))

(defun switch-to-sart ()
  (clear-buffer 'retrieval)
  (clear-buffer 'goal)

  (goal-focus focus)

  (add-dm
    (srtask isa memory goal focus kindm intention type task topic srmapping)
    (press-on-O isa srmapping stimulus "O" hand left)
    (withhold-on-Q isa srmapping stimulus "Q" hand nil)

    (standard-response isa subgoal step standard-response))

  (set-base-levels
    (srtask      100  -10000)
    (task          0  -10000)
    (press-on-O     10000  -10000)
    (withhold-on-Q  10000  -10000)
  )

  (pdisable focus-retrieval breath wander-retrieval daydream-about-intention daydream)
  (penable refresh-focus remember-to-focus retrieve-intention check-sr retrieve-daydream ponder-intention daydream2 identify-stimulus retrieve-response respond-if-O do-not-respond-if-Q give-standard-response)

  
  (spp retrieve-intention :u 1)
  (spp check-sr :u 1)
  (spp retrieve-daydream :u 1)
  (spp ponder-intention :u 1)
  (spp daydream-about-intention :u 1)
  (spp daydream2 :u 1)
  (spp identify-stimulus :u 100)
  (spp give-standard-response :u 100)


  (write "Switching to SART task..."))

(defun do-meditation (c)
  (reset)
  (pdisable retrieve-intention check-sr retrieve-daydream ponder-intention daydream2 identify-stimulus retrieve-response respond-if-O do-not-respond-if-Q give-standard-response)
  (if (eq c 1)
    (schedule-event-relative 480 'stop-meditating)
  )
  (if (eq c 0)
    (schedule-event-relative 0 'stop-meditating)
  )

  (schedule-event-relative 485 'switch-to-sart)
  (run-until-time 485)
  (do-sart)
)

;; Do MEDITATION experiment n times with condition c (c=1:meditation, c=0: no meditation)
(defun do-meditation-n (c n)
  (with-open-file
    (file-stream
      (ensure-directories-exist
        (merge-pathnames
          (make-pathname :name *trace-file-name* :type "txt")
          *output-directory*))
      :direction :output :if-does-not-exist :create :if-exists :supersede)

  (if *trace-to-file-only*
    ; If true, direct standard output only file
    (setf *standard-output* file-stream)
    ; Else, direct standard output to terminal and file
    (setf *standard-output*
      (make-broadcast-stream *terminal-stream* file-stream)))

  ; Direct ACT-R output to the stream contained within *standard-output*
  (echo-act-r-output)

  (setf *visible* nil)
  (format t "Running ~a model participants~%" n)
  (dotimes (i n)
    (let ((participant (1+ i)))
      (format t "Run ~a...~%" participant)
      (do-meditation c)
      (write-results-to-file
        (concatenate 'string "dat" (write-to-string participant))
        participant
        *stimuli*
        (reverse *all-responses*)
        (reverse *all-rts*))))
  (format t "Done~%")

  ; We will close file-stream now, so make sure *standard-output*
  ; no longer points to it
  (setf *standard-output* *terminal-stream*)
  ; We also have to make sure ACT-R knows about the new value of
  ; *standard-output*
  (echo-act-r-output)
  )
)



;;===================;;
;;    Model code     ;;
;;===================;;

(clear-all)

(define-model meditation

;; Model parameters
(sgp :v t ; main trace detail
  :act low ; activation trace detail
  :sact t ; include activation trace in main trace

  :show-focus t ; show where the model is looking
  :esc t ; enable sub-symbolic level
  :rt -5 ; retrieval threshold
  :bll 0.5 ; base-level learning
  :ans 0.5 ;activation noise
  :mas 5
  :ga 1
  :egs 0.2
  :ul t
)

(chunk-type goal state task)
(chunk-type memory goal kindm type topic)
(chunk-type subgoal step)
(chunk-type srmapping stimulus hand)

(add-dm
  (focus isa goal state focus task nil)
  (wander isa goal state wander task nil)

  (task isa memory goal focus kindm intention type task topic breath)
  (meta isa memory goal focus kindm intention type metatask topic focus-attention)

  (memory0 isa memory goal wander kindm daydream topic 0)
  (memory1 isa memory goal wander kindm daydream topic 1)
  (memory2 isa memory goal wander kindm daydream topic 2)
  (memory3 isa memory goal wander kindm daydream topic 3)
  (memory4 isa memory goal wander kindm daydream topic 4)
  (memory5 isa memory goal wander kindm daydream topic 5)
  (memory6 isa memory goal wander kindm daydream topic 6)
  (memory7 isa memory goal wander kindm daydream topic 7)
  (memory8 isa memory goal wander kindm daydream topic 8)
  (memory9 isa memory goal wander kindm daydream topic 9)
  (memory10 isa memory goal wander kindm daydream topic 10)
  (memory11 isa memory goal wander kindm daydream topic 11)
  (memory12 isa memory goal wander kindm daydream topic 12)
  (memory13 isa memory goal wander kindm daydream topic 13)
  (memory14 isa memory goal wander kindm daydream topic 14)
  (memory15 isa memory goal wander kindm daydream topic 15)
  (memory16 isa memory goal wander kindm daydream topic 16)
  (memory17 isa memory goal wander kindm daydream topic 17)
  (memory18 isa memory goal wander kindm daydream topic 18)
  (memory19 isa memory goal wander kindm daydream topic 19)

  (get-response isa subgoal step get-response)
  (make-response isa subgoal step make-response)
)

(set-base-levels
  (focus     10000  -10000)
  (wander    10000  -10000)

  (task      100  -10000)
  (meta      100  -10000)
  (memory0      20  -10000)
  (memory1      30  -10000)
  (memory2      40  -10000)
  (memory3      50  -10000)
  (memory4      60  -10000)
  (memory5      10  -10000)
  (memory6      40  -10000)
  (memory7      25  -10000)
  (memory8      27  -10000)
  (memory9      56 -10000)
  (memory10      38  -10000)
  (memory11      35  -10000)
  (memory12      47  -10000)
  (memory13      52  -10000)
  (memory14      84  -10000)
  (memory15      95  -10000)
  (memory16      34  -10000)
  (memory17      75  -10000)
  (memory18      45  -10000)
  (memory19      11  -10000)
)

(p focus-retrieval
  =goal>
    isa goal
    state focus
  ?retrieval>
    buffer   empty
    state    free
  - state    error
==>
  =goal>
  +retrieval>
    isa      memory
  - kindm     nil
)

(p refresh-focus 
  =goal>
  =retrieval>
    isa           memory
    topic         focus-attention
==>
  +goal>
    isa           goal
    state         focus
  +retrieval>
    isa           memory
    kindm          intention
    type          task
)

(p remember-to-focus
  =goal>
  =retrieval>
    isa       memory
    kindm      daydream
==>
  +retrieval>
    isa       memory
  - kindm      nil
  +goal>
    isa       goal
    state     focus
)


(p breath
  =goal>
    isa           goal
    state         focus
  =retrieval>
    isa           memory
    topic         breath
==>
  =goal>
  -retrieval>
)






(p wander-retrieval
  =goal>
    isa goal
    state wander
  ?retrieval>
    buffer   empty
    state    free
  - state    error
==>
  =goal>
  +retrieval>
    isa      memory
  - kindm     nil
)

(p daydream-about-intention
  =goal>
  =retrieval>
    isa           memory
    kindm          intention
==>
  +goal>
    isa           goal
    state         wander
  -retrieval>
)

(p daydream
  =goal>
    isa goal
    state wander
  =retrieval>
    isa           memory
    kindm          daydream
==>
  +goal>
    isa           goal
    state         wander
  -retrieval>
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(p retrieve-intention
  =goal>
    isa goal
    state focus
  ?retrieval>
    buffer   empty
    state    free
  - state    error
==>
  =goal>
  +retrieval>
    isa      memory
  - kindm     nil
)

(p check-sr
  =goal>
  =retrieval>
    isa           memory
    topic         srmapping
==>
  =goal>
    state nil
  -goal>
  +goal>
    isa goal
    state focus
)

(p identify-stimulus
  =goal>
    isa goal
    state focus
  =visual-location>
  ?visual>
    state       free
  ?retrieval>
    buffer   empty
    state    free
  - state    error
==>
  +visual>
    isa         move-attention
    screen-pos  =visual-location
  +goal>
    isa         subgoal
    step        get-response
)

(p retrieve-response
  =goal>
    isa       subgoal
    step      get-response
  =visual>
    isa       text
    value     =letter
  ?visual>
    state     free
  ?retrieval>
    state     free
==>
  +retrieval>
    isa       srmapping
    stimulus  =letter
  +goal>
    isa       subgoal
    step      make-response
  +visual>
    isa       clear-scene-change
)


(p respond-if-O
  =goal>
    isa       subgoal
    step      make-response
  =retrieval>
    isa       srmapping
    stimulus  =letter
    hand      =hand
  ?manual>
    state     free
==>
  +manual>
    isa       punch
    hand      =hand
    finger    index
  +goal>
    isa goal
    state focus
  -visual-location>
  -visual>
)

(p do-not-respond-if-Q
  =goal>
    isa       subgoal
    step      make-response
  =retrieval>
    isa       srmapping
    stimulus  =letter
    hand      nil
==>
  +goal>
    isa goal
    state focus
  -visual-location>
  -visual>
)




(p retrieve-daydream
  =goal>
    isa goal
    state wander
  ?retrieval>
    buffer   empty
    state    free
  - state    error
==>
  =goal>
  +retrieval>
    isa      memory
  - kindm     nil
)

(p ponder-intention
  =goal>
  =retrieval>
    isa           memory
    kindm         intention
  - topic         srmapping
==>
  +goal>
    isa           goal
    state         wander
  -retrieval>
)

(p daydream2
  =goal>
    isa goal
    state wander
  =retrieval>
    isa           memory
    kindm          daydream
==>
  +goal>
    isa           goal
    state         wander
  -retrieval>
)

(p give-standard-response
  =goal>
    isa           goal
    state         wander
  ?retrieval>
    buffer   empty
  - state         busy
  - state         error
  ?visual-location>
  - buffer  		  empty
  ?visual>
    scene-change  T
  ?manual>
    state         free
==>
  =goal>
  +manual>
    isa           punch
    hand          left
    finger        index
  -visual-location>
  -visual>
  -retrieval>
)

(goal-focus focus)

(spp focus-retrieval :u 1)
(spp refresh-focus :u 1)
(spp remember-to-focus :u 1)
(spp breath :u 1)
(spp daydream-about-intention :u 1)
(spp daydream :u 1)
(spp wander-retrieval :u 1)
(spp breath :reward 10)

)

