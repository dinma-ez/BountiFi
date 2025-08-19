;; Crypto Quest
;; A blockchain-based quest with progressive puzzles and rewards

;; Constants
(define-constant ACCESS-DENIED-ERROR (err u1))
(define-constant CHALLENGE-INACTIVE-ERROR (err u2))
(define-constant WRONG-PHASE-ERROR (err u3))
(define-constant PHASE-ALREADY-COMPLETED-ERROR (err u4))
(define-constant WRONG-ANSWER-ERROR (err u5))
(define-constant SCHEDULE-ERROR (err u6))
(define-constant NOT-ENOUGH-BALANCE-ERROR (err u7))

;; Data Variables
(define-data-var admin-principal principal tx-sender)
(define-data-var challenge-status bool false)
(define-data-var challenge-phase uint u0)
(define-data-var entry-fee uint u1000000) ;; 1 STX
(define-data-var reward-pool uint u0)

;; Quest Phase Structure
(define-map challenge-phases
   uint
   {
       hint: (string-utf8 256),
       solution-hash: (buff 32), ;; SHA256 hash of the solution
       unlock-block: uint,
       phase-reward: uint,
       phase-completed: bool
   }
)

;; Explorer Progress Tracking
(define-map participant-progress
   principal
   {
       active-phase: uint,
       completed-phases: (list 20 uint),
       last-submission-block: uint,
       phases-solved: uint
   }
)

;; Explorer Solutions History
(define-map submission-records
   {phase: uint, participant: principal}
   {
       attempts: uint,
       completion-block: (optional uint)
   }
)

;; Events
(define-map phase-champions
   uint
   (list 10 {participant: principal, completion-block: uint})
)

;; Authorization
(define-private (is-administrator)
   (is-eq tx-sender (var-get admin-principal)))

;; Quest Management Functions
(define-public (start-game)
   (begin
       (asserts! (is-administrator) ACCESS-DENIED-ERROR)
       (var-set challenge-status true)
       (var-set challenge-phase u0)
       (var-set reward-pool u0)
       (ok true)))

(define-public (create-level
   (phase-number uint)
   (phase-hint (string-utf8 256))
   (solution-hash (buff 32))
   (activation-block uint)
   (phase-prize uint))
   (begin
       (asserts! (is-administrator) ACCESS-DENIED-ERROR)
       (map-set challenge-phases phase-number
           {
               hint: phase-hint,
               solution-hash: solution-hash,
               unlock-block: activation-block,
               phase-reward: phase-prize,
               phase-completed: false
           })
       (var-set reward-pool (+ (var-get reward-pool) phase-prize))
       (ok true)))

;; Explorer Registration
(define-public (join-game)
   (begin
       (asserts! (var-get challenge-status) CHALLENGE-INACTIVE-ERROR)
       ;; Require entry fee
       (try! (stx-transfer? (var-get entry-fee) tx-sender (var-get admin-principal)))
       
       (map-set participant-progress tx-sender
           {
               active-phase: u0,
               completed-phases: (list),
               last-submission-block: u0,
               phases-solved: u0
           })
       (ok true)))

;; Gameplay Functions
(define-public (try-solution
   (phase-number uint)
   (submitted-hash (buff 32)))
   (let (
       (phase-data (unwrap! (map-get? challenge-phases phase-number) WRONG-PHASE-ERROR))
       (participant-data (unwrap! (map-get? participant-progress tx-sender) WRONG-PHASE-ERROR))
       )
       ;; Check phase availability
       (asserts! (var-get challenge-status) CHALLENGE-INACTIVE-ERROR)
       (asserts! (>= block-height (get unlock-block phase-data)) SCHEDULE-ERROR)
       (asserts! (not (get phase-completed phase-data)) PHASE-ALREADY-COMPLETED-ERROR)
       
       ;; Verify solution - directly compare the hashes
       (if (is-eq submitted-hash (get solution-hash phase-data))
           (begin
               ;; Update phase status
               (map-set challenge-phases phase-number
                   (merge phase-data {phase-completed: true}))
               
               ;; Update explorer progress
               (map-set participant-progress tx-sender
                   (merge participant-data {
                       active-phase: (+ phase-number u1),
                       completed-phases: (unwrap! (as-max-len? 
                           (append (get completed-phases participant-data) phase-number) u20)
                           WRONG-PHASE-ERROR),
                       phases-solved: (+ (get phases-solved participant-data) u1)
                   }))
               
               ;; Record solution
               (map-set submission-records
                   {phase: phase-number, participant: tx-sender}
                   {
                       attempts: u1,
                       completion-block: (some block-height)
                   })
               
               ;; Award reward
               (try! (stx-transfer? (get phase-reward phase-data) (var-get admin-principal) tx-sender))
               
               ;; Record champion
               (match (map-get? phase-champions phase-number)
                   champion-list (map-set phase-champions phase-number
                       (unwrap! (as-max-len?
                           (append champion-list {participant: tx-sender, completion-block: block-height})
                           u10)
                           WRONG-PHASE-ERROR))
                   (map-set phase-champions phase-number
                       (list {participant: tx-sender, completion-block: block-height})))
               
               (ok true))
           WRONG-ANSWER-ERROR)))

;; Read-only functions
(define-read-only (view-level-clue (phase-number uint))
   (match (map-get? challenge-phases phase-number)
       phase-data (if (>= block-height (get unlock-block phase-data))
           (ok (get hint phase-data))
           SCHEDULE-ERROR)
       WRONG-PHASE-ERROR))

(define-read-only (view-player-progress (user-address principal))
   (map-get? participant-progress user-address))

(define-read-only (view-level-winners (phase-number uint))
   (map-get? phase-champions phase-number))

(define-read-only (view-game-status)
   {
       active: (var-get challenge-status),
       current-level: (var-get challenge-phase),
       total-prize-pool: (var-get reward-pool),
       entry-fee: (var-get entry-fee)
   })