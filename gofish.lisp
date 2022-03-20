;;;Anna-Lisa Vu
;;;ID: 0619091
;;;CSC458 Winter 2022
;;;Final Project - Go Fish with Strategic Elements

;;Run order for output to look complete when running functions.
(defparameter tpl:*print-length* nil)

(defvar *standard-suits* '(hearts diamonds clubs spades))
(defvar *standard-values* '(ace king queen jack 10 9 8 7 6 5 4 3 2))
(defvar *max-3-deal* '7)
(defvar *max-5-deal* '5)
(defvar *ret-success* '0)
(defvar *ret-interrupt* '-1)
(defvar *play-again* 1)
(defparameter *current-game* nil)

;;;;;CARD & DECK Related methods and classes ;;;;;;;;;;;
;;These were copied from previous homework assignments
(defmethod make-deck-helper (suits cards)
  (when suits
    (append
     (make-cards (car suits) cards)
     (make-deck-helper (cdr suits) cards))))

(defmethod make-cards (suit cards-left)
  (when cards-left
    (cons (make-instance 'card :value (car cards-left) :suit suit)
          (make-cards suit (cdr cards-left)))))

;;Defines the class for card
(defclass card ()
  ((card-suit :initarg :suit
	 :initform ""
	 :accessor card-suit)
   (card-value :initarg :value
	  :initform ""
	  :accessor card-value)))

;;Print object for card.  Allows the cards to be printed nicely.
(defmethod print-object ((obj card) out)
  (with-slots (card-suit card-value) obj
    (format out "[~A of ~A]" card-value card-suit)))

;;A method to make a deck.  It takes the suits and values as parameters.
;;This method contains a closure which is the deck
;;It then definesmethods that interact with the deck.
(defmethod make-deck (suits values)
  (let ((deck (make-deck-helper suits values)))
    (defun deal ()
      (let ((card-removed (nth 0 deck)))
	(setf deck (remove card-removed deck))
	card-removed))
    (defun shuffle-deck ()
      (setf deck (shuffle-helper deck '())))
    (defun show-deck (num &optional (stream t))
      (show-deck-helper deck num stream))
    (defun len-deck ()
      (length deck))
    (defun show-full-deck (&optional (stream t))
      (show-deck-helper deck (len-deck) stream))
    (format t "A deck has been made.~%")))

;;This is a helper function that shuffles the deck recursively.
;;This was a function that I copied from my assignment 1
(defun shuffle-helper (orig-deck shuffled-deck)
  (if (null orig-deck) shuffled-deck
    (progn (setf card (nth (random (length orig-deck)) orig-deck));
	   (push card shuffled-deck)
	   (shuffle-helper (remove card orig-deck) shuffled-deck))))

;;This is a helper function takes in 2 parameters and 1 optional parameter.
;;It takes the deck and the number of cards to show.  A third optional parameter
;;is a stream which is passed into the format function. 
;;If not provided, the default is "t".
;;that show n cards from a deck
(defun show-deck-helper (deck num &optional (stream t))
  (format stream "~{~a~^ ~}" (subseq deck 0 num)))

;;;;;;;;;;;;PLAYER Related methods and classes ;;;;;;;;;;;
;;A basic player class that contains the following slots:
;;name-The name of the player
;;hand-a hash table to keep track of the player's hand by value
;;books-a hash table to keep track of the player's books by value
;;asks-gots-a hash table that keeps track of what cards
;;a player asks and what they received
(defclass player ()
  ((name :initarg :name
	 :initform ""
	 :accessor name)
  (hand :initarg :hand
	 :initform (make-hash-table)
	 :accessor hand)
  (books :initarg :books
	 :initform (make-hash-table)
	 :accessor books)
  (asks-gots :initarg :asks-gots
	     :initform (make-hash-table)
	     :accessor asks-gots))
  (:documentation "This is the class that represents a player."))

;;A special class to represent the ai-player.
;;It inherits from player
;;There are 2 supported skill levels:
;;0-Basic (this player will randomly select a card when asking)
;;1-Advanced (this player will intelligently select a card when asking)
(defclass ai-player(player)
  ((skill-level :initarg :skill-level
		:initform 1
		:accessor skill-level)))

;;A special method to print a player
;;Used mostly during testing
(defmethod print-object ((obj player) out)
  (with-slots (name hand books asks-gots) obj
    (format out "[Player: ~A Hand: ~A Books: ~A Cards
  (Asks:Received):~A ]~%" name hand books asks-gots))) 

;;;;;;;;;;;;;;;GAME Related methods and classes ;;;;;;;;;;;
;;A special class to represent a single game of gofish
;;players-a hash table which keeps track of players by name and player object
;;opponents-a hash table which keeps track of who players will
;;asked cards or receive from
(defclass game()
  ((players :initarg :players
	    :initform (make-hash-table)
	    :accessor players)
   (opponents :initarg :opponents
	      :initform (make-hash-table)
	      :accessor opponents))
  (:documentation "This is the class that represents a single go fish game."))

;;A method to print the game object
(defmethod print-object ((obj game) out)
  (with-slots (players opponents) obj
    (format out "GAME: Players: ~A Opponents: ~A" players opponents)))

;;;;;;;;;;;;;;;;;;;;;;;Commands for game play;;;;;;;;;;;;;;

;;A command to "go fish" specific to the player object. 
;;It deals a single card from the pool
;;and puts it in the player's hand.
;;It prints the card that was dealt from the deck.
(defmethod go-fish ((obj player))
  (let ((dealt-card (deal)))
    (setf (gethash (card-value dealt-card) (hand obj)) 
      (cons dealt-card (gethash (card-value dealt-card) (hand obj))))
    (format t "~A has fished the card ~A.~%" (name obj) dealt-card)))

;;A command to ask a card from a particular player.
;;player-the player who is asking
;;opponent-the player who the card is being asked from
;;card-value-the value that is being asked for
;;Note: A player can only ask for a value from an opponent only
;;if they currently have at least 1 card of that value.
;;This method must also update the asks-gots hash tables
;;as well as the hand hash tables.
(defun ask-card (player opponent card-value)
  (let ((num-cards-to-transfer nil))
    (format t "~A has asked ~A for ~As.~%" (name player)
	    (name opponent) card-value)
    ;;first check if the player has the card-value they are asking for
    (cond ((null (gethash card-value (hand player)))
	   (format t "You cannot ask for a card value that you do not have.~%"))
	  ;;the case of when the opponent does not have a value asked for
	  ((null (gethash card-value (hand opponent)))
	   (progn
	     (format t "~A says I do not have any ~As.  Go Fish!~%" (name opponent) card-value)
	     (update-asks-gots player opponent card-value 0)
	     (go-fish player)))
	  ;;the case of when the opponent does have the value asked for
	  (t (progn
	       (setf num-cards-to-transfer (length (gethash card-value (hand opponent))))
	       (update-asks-gots player opponent card-value num-cards-to-transfer)
	       (transfer-ask-card player opponent card-value)
	       (format t "~A had ~A ~A(s) and now they belong to ~A.~%"
		       (name opponent) num-cards-to-transfer card-value (name player)))))
    player))
	   
;;A command to transfer a card from the opponent to the player
;;This command updates all the datastructures that need to be updated
(defun transfer-ask-card (player opponent card-value)
  (let ((transfer-cards (gethash card-value (hand opponent)))
	(num-cards-to-transfer (length (gethash card-value (hand opponent)))))
    (setf (gethash card-value (hand player))
      (append transfer-cards (gethash card-value (hand player))))
    (remhash card-value (hand opponent)))) 

;;A command for updating each player's asks-gots tables.
;;The player that receives the cards should have the counts incremented in their table.
;;The player getting giving the cards should have the counts decremented in their table.
(defun update-asks-gots (receiver giver card-value num-cards)
  (let ((receiver-table (asks-gots receiver))
	(giver-table (asks-gots giver)))
    (if (null (gethash card-value receiver-table))
	(setf (gethash card-value receiver-table) num-cards)
      (setf (gethash card-value receiver-table) (+ num-cards (gethash card-value receiver-table))))
    (if (not (null (gethash card-value giver-table)))
	;;remove the card since the giver won't have it anymore
	(remhash card-value giver-table))))

;;A command to make a book with a player has all 4 values of cards.
;;Each card would be from a different suit.  This command checks that
;;the values of all the cards being passed in is the same.  If it's not,
;;a book will not be made.
(defun make-book (player value card-list)
  (if (equal (length card-list) 4)
      (progn
	(remhash value (hand player))
	(format t "~A has declared a book for the value ~A. ~A~%"
		(name player) value (setf (gethash value (books player)) card-list)))
    (format t "You must have 4 cards of the same value to create a book.~%")))

;;The method to handle a human player
;;This method will prompt the human player when it is his/her turn.
;;The player will have the option to do the following during his/her turn:
;;-ask [value] - asks their opponent for a particular value.
;;Note: this can only happen 1x a turn.
;;-declare-book [value] - if the player realizes they have a book,
;;they can officially declare it so it can be counted
;; when the winner is determined. Note: one must declare a book in order it
;;to count when winners are tallied.
;;-show-asks [player-name] - shows the asks/receives table for a player.
;;This can be helpful to determine what value to ask for.
;;-show-books [player-name] - show all of the declared books for a particular player
;;-show-hand - shows the hand of the current player
;;-next - signifies that the player is finish with their turn and
;;the game will move on to the next player
;;-quit - will quit out of the game
(defmethod handle-player ((obj player) current-game)
  (let ((value nil)
	(opponent (get-opponent obj current-game))
	(user-cmd nil)
	(show-asks-count 0))
    (format t "~A it's your turn to go. Type cmd-help to view commands you can execute.~%
Here is your current hand:~A" (name obj) (hand obj))
    (setf user-cmd (read-cmd))
    (if (equal (car user-cmd) 'quit) 
	(progn
	(format t "~A has decided to quit.~%" (name obj)) 
	*ret-interrupt*)
      (progn
	(loop while (and (not (equal (car user-cmd) 'next))
			 (not (equal (car user-cmd) 'quit)))
	    do(handle-cmd user-cmd obj opponent show-asks-count)
	    do(if (and (equal (car user-cmd) 'ask) (equal show-asks-count 0) (setf show-asks-count 1)))
	    do(setf user-cmd (read-cmd)))
	(if (equal (car user-cmd) 'quit) *ret-interrupt* *ret-success*)))))

;;This command is responsible for reading words from the REPL
;;and making commands out of them.  It was taken from
;;Chapter 6 from the Land of Lisp text book by Conrad Barski.
(defun read-cmd()
  (let ((cmd (read-from-string (concatenate 'string "(" (read-line) ")"))))
    (flet ((quote-it (x)
	     (list 'quote x)))
      cmd)))

;;This command handles what actions a certain command
;;should do when a user types it in the REPL.
;;It takes in the cmd, player, opponent, and the 
;;show-asks-count.  These are all information that is
;;needed to handle the commands.
(defun handle-cmd(cmd player opponent show-asks-count)
  (let ((action (car cmd))
	(param (cadr cmd)))
    (cond ((equal action 'ask)
	   (if (equal show-asks-count 0) 
	       (ask-card player opponent param)
	     (format t "~A has already asked ~A for a value.
~A cannot ask for another value.~%" (name player) (name opponent) (name player))))
	  ((equal action 'declare-book) (make-book player param (gethash param (hand player))))
	  ((equal action 'show-asks)
	   (format t "~A's Cards (Asks:Received):~A" param (asks-gots (get-player param))))
	  ((equal action 'show-books) (format t "~A Books:~A" param (books (get-player param))))
	  ((equal action 'next) (format t "~A is done with their hand.~%" (name player)))
	  ((equal action 'show-hand) (format t "Current hand:~A" (hand player)))
	  ((equal action 'cmd-help) (cmd-help))
	  (t (format t "~A is not a recognized command.~%" action)))))

;;A basic function to print all of the commands
;;available to a human player.
(defun cmd-help()
  (format t "ask [value] - asks their opponent for a particular value.
Note: this can only happen 1x a turn.~%
declare-book [value] - if the player realizes they have a book,
they can officially declare it so it can be counted when the game is over.~%
show-asks [player-name] - shows the asks/receives table for a player.
This can be helpful to determine what value to ask for.~%
show-books [player-name] - show all of the declared books for a particular player.~%
show-hand - shows the hand of the current player.~%
next - signifies that the player is finished with their turn
and the game will move on to the next player.~%
quit - will quit out of the game.~%"))

;;This command is responible for declaring the winner of the game.
;;The winner of the game is determined by the player who has the most
;;books.  There could be a tie so we properly declare multiple players
;;as the winner if that is the case.
;;It takes in the current-game as a parameter.
(defun declare-winner (current-game)
  (let* ((num-books-hash (create-player-num-books-hash (players current-game)))
	 (num-books-list (get-keys num-books-hash)))
    (gethash (apply 'max num-books-list) num-books-hash)
    ))

;;This is a helper function that is used to declare
;;the winner of the game.  It create a hash table
;;where the key is the number of books for a player
;;and the value is the player's name.
(defun create-player-num-books-hash (players)
  (let ((hash-to-return (make-hash-table)))
    (maphash
     (lambda (name player)
       (if (null (gethash (hash-table-count (books player)) hash-to-return))
	   (setf (gethash (hash-table-count (books player)) hash-to-return)
	     (list name))
	 (setf (gethash (hash-table-count (books player)) hash-to-return)
		   (cons name (gethash (hash-table-count (books player)) hash-to-return)))))
	     players)
    hash-to-return))


;;;;;;;;;;;;;;;;Commands specific for AI Players ;;;;;;;;;;;;;;
;;The method to handle an ai player
;;This method will handle the actions that an ai player will do when it is their turn.
;;This method will always return a value of 0 since the idea is that this type of player never
;;interrupt a game.  This return value is used to determine whether the game will continue or stop (since a human
;;player can chose to stop a game if they want to).
(defmethod handle-player ((obj ai-player) current-game)
  (let* ((opponent (get-opponent obj current-game))
	 (value (compute-ask-value (skill-level obj) (hand obj) (asks-gots opponent))))
    (format t "~A it's your turn to go.~%" (name obj))
    (ask-card obj opponent value)
    (check-for-books obj)
    *ret-success*))

;;A command to "go fish" specific to the ai-player object. 
;;It deals a single card from the pool
;;and puts it in the player's hand.
;;It does not print the card that was dealt.
(defmethod go-fish ((obj ai-player))
  (let ((dealt-card (deal)))
    (setf (gethash (card-value dealt-card) (hand obj))
      (cons dealt-card (gethash (card-value dealt-card) (hand obj))))
    (format t "~A has fished a card.~%" (name obj))))

;;This method is responsible for computing which value that 
;;the AI player should ask for.  It takes in the skill-level
;;of the AI player, the hand, and the ask-gots of the opponent
;;of the player.
(defmethod compute-ask-value (skill-level hand ask-gots-opponent)
  (let ((values-at-hand (get-keys hand)))
    (cond ((equal skill-level 0) (nth (random (length values-at-hand)) values-at-hand))
	  ((equal skill-level 1) (ai-advanced-ask-value hand ask-gots-opponent)))))

;;This method is responsible for computing the
;;ask value that the ai player should ask for in an
;;intelligent way.  It takes in the hand and the 
;;ask-gots of the opponent.
;;This two values are used to determine the best
;;value to ask for.  The method iterates through the hand
;;and checks whether the value exists in the asks-gots of the opponent.
;;If the value exists, then it adds it to a list.
;;A random item from that list is selected for the ai
;;player to ask for.
;;If there are no values in the list
;;it selects a random value from the ai player's hand.
(defun ai-advanced-ask-value (hand ask-gots-opponent)
  (let ((return-value nil)
	(values-at-hand (get-keys hand))
	(values-opponent-has (list)))
    (mapcar (lambda (value)
	      (if (gethash value ask-gots-opponent)
		  (push value values-opponent-has)))
	    values-at-hand)
    (setf return-value (if (> (length values-opponent-has) 0)
			   (nth (random (length values-opponent-has)) values-opponent-has)
			 (nth (random (length values-at-hand)) values-at-hand)))
    return-value))

;;An attempt to refine the method above but this method errors out.
;;This method along with the helpers remain unused.
(defun ai-advanced-ask-value-2 (hand ask-gots-opponent)
  (let ((values-in-asks-gots (get-values-in-asks-gots hand ask-gots-opponent))
	(sum-of-values (make-hash-table))
	(values-at-hand (get-keys hand))
	(highest-sum nil)
	(return-value nil))
    (format t "hand:~A" hand)
    (format t "values in asks gots:~A" values-in-asks-gots)
   
    ;;if there are no values in asks-gots, just randomly select a value at hand
    ;;if there are values, add the number of cards of that value
    ;;at hand with the number of cards of that value in
    ;;the opponents hand
    ;;then return the value with the highest sum
    ;;if there is a tie for the highest sum, randomly select a value
    (cond ((null values-in-asks-gots)  
	   (progn
	     (setf return-value (nth (random (length values-at-hand)) values-at-hand))
	     (format t "returning:~A" return-value)))
	  (t (progn
	       (mapcar (lambda (value)
			 (let ((sum (add-asks-gots-with-values-at-hand hand ask-gots-opponent value)))
			   (if (null (gethash sum sum-of-values))
			       (setf (gethash sum sum-of-values) (list value))
			     (setf (gethash sum sum-of-values)
			       (cons value (gethash sum sum-of-values))))))
		       values-in-asks-gots)
	       (setf highest-sum (apply 'max (get-keys sum-of-values)))
	       (if (> (length(gethash highest-sum sum-of-values)) 1)
		   (nth (random (length(gethash highest-sum sum-of-values)))
			(gethash highest-sum sum-of-values))
		 (gethash highest-sum sum-of-values)))))))

;;A helper method to add values at hand with the values from the asks-gots table    
(defun add-asks-gots-with-values-at-hand (hand asks-gots-opponent value)
  (let ((num-at-hand (length (gethash value hand)))
	(num-at-opponent (gethash value asks-gots-opponent)))
    (if (equal num-at-opponent 0)
	(+ num-at-hand 1)
      (+ num-at-hand num-at-opponent))))
     
;;retrieves values from a player's hand which is part
;;of the opponents ask-gots table
(defun get-values-in-asks-gots (hand ask-gots-opponent)
  (let ((values-at-hand (get-keys hand))
	(values-in-asks-gots (list)))
    (mapcar (lambda (x)
	      (if (gethash x ask-gots-opponent) (push x values-in-asks-gots)))
	    values-at-hand)
    values-in-asks-gots))

;;Responsible for checking whether an ai-player has a book after
;;playing their hand. A hand is played whenever they receive a card 
;;from an ask or go fish.
(defun check-for-books (ai-player)
  (let ((hand (hand ai-player)))
    (maphash (lambda (key value)
	       (if (equal (length value) 4)
		   (make-book ai-player key value)))
	     hand)
    (books ai-player)))


;;;;;;;;;;;;;;;Commands specific for game initialization;;;;;;;;;;;;;; 
;;Makes a hash table to hold the players in the game
;;The key of the hash table is the name of the player
;;The value of the hash table is the player object itself
;;It takes in a list of player and ai player objects
(defun make-player-hash (player-list ai-player-list)
  (let ((player-hash (make-hash-table)))
    (loop for player in player-list
	do(setf (gethash (name player) player-hash) player))
    (loop for ai-player in ai-player-list
	do(setf (gethash (name ai-player) player-hash) ai-player))
    player-hash))

    
;;Deals cards to each player's hand
;;Each player's hand is represented as a hash table
;;It takes in a list of players and an initial
;;amount of cards to deal
(defun deal-to-players (players initial-deal) 
  (let ((dealt-card nil))
    (format t "Dealing ~A cards to each player.~%" initial-deal)
    (loop for i from 1 to initial-deal
      do(loop for player in players
	    do(setf dealt-card (deal))
	    do(setf (gethash (card-value dealt-card) (hand player))
		(cons dealt-card (gethash (card-value dealt-card) (hand player))))))))

;;Assigns opponents to each player in the game
;;It takes a list of player names and assigns the player 
;;each player will ask a card from
;;It returns a hash table of each player and which 
;;player they will ask a card from
(defun assign-opponents (player-names-lis)
  (let ((player-opponent (make-hash-table)))
    (loop for i from 0 to (- (length player-names-lis) 2)
	do(setf (gethash (nth i player-names-lis) player-opponent)
	    (nth (1+ i) player-names-lis)))
    (setf (gethash (nth (1- (length player-names-lis)) player-names-lis)
		   player-opponent)
      (nth 0 player-names-lis))
    (format t "Opponents have been assigned: ~A" player-opponent) player-opponent)) 

;;Select a random player to start the game
;;Takes in a list of player names and hash map consisting of 
;;player names and player objects
(defun select-random-player (player-name-list player-hash)
  (gethash (nth (random (length player-name-list))
					     player-name-list)
				     player-hash))
  
;;;;;;;;;;;;;;Random Helper Methods;;;;;;;;;;;;;;;;;;;;;;;;; 

;;A helper method to create a list of keys from a hash table
(defun get-keys (hashtable)
  (let ((keys ()))
    (maphash (lambda (key value) (push key keys)) hashtable)
    keys))
;;A helper method to create a list of values from a hash table
(defun get-values (hashtable)
  (let ((values ()))
    (maphash (lambda (key value) (push value values)) hashtable)
    values))
;;A general method to print hash tables the way I prefer to show
;;them in my program.
(defmethod print-object ((obj hash-table) stream)
  (maphash (lambda (key value)
	     (format stream "~%~A : ~A" key value)) 
	   obj)
  (format stream "~%"))

;;A helper method to get the opponent of a current player in the game
;;It takes the player and the current-game object
(defun get-opponent (player current-game)
  (let ((opponent-name (gethash (name player) (opponents current-game))))
    (gethash opponent-name (players current-game))))

;;;;;;;;;;;;;;;;;;;;Helpful Macros;;;;;;;;;;;;;;;;;;;;;;;
;;A macro to get a player
(defmacro get-player (player-name)
  `(gethash ,player-name (players current-game)))

;;A macro to get opponents
(defmacro get-opponents (current-game)
  `(opponents current-game))

;;;;;;;;;;;;;;;;;;;;Main Methods to Execute the Game;;;;;;;;;;;;;;;;;;;;;;;
;;Main entry method to the the game
;;Initializes and then starts a game
(defun play ()
  (let ((num-human-players 0)
	(num-ai-players 0)
	(players-list (list))
	(ai-players-hash (make-hash-table))
	(ai-player-name nil))
    
    (format t "Welcome to Go Fish!  Let's play!~%")
    (format t "How many human players will play:")
    (setf num-human-players (read))
    
    (loop for i from 1 to num-human-players
	do(format t "Enter name of human player ~A:" i)
	do(push (read) players-list))
    
    (format t "How many ai players will play:")
    (setf num-ai-players (read))
    
    (loop for i from 1 to num-ai-players
	do(format t "Enter name of ai player ~A:" i)
	do(setf ai-player-name (read))
	do(format t "Enter the skill level of ai player ~A (0-Basic/1-Advanced):" i)  
	do(setf (gethash ai-player-name ai-players-hash) (read)))
    
    (loop while (equal *play-again* (start-game players-list ai-players-hash))))
  (format nil "Thanks for playing goodbye!"))

;;Starts a game and executes the main game through a main loop
;;It takes in a list of player names and a hash table of ai players with skill level
(defun start-game (players-list ai-players-hash)
  (let ((player-list nil)
	(ai-player-list nil)
	(player-hash nil)
	(player-name-list nil)
	(player-opponent-hash nil)
	(player-to-go nil)
	(return-code nil)
	(num-of-turns 0)
	(play-again nil))

    ;;create players
    (setf player-list (mapcar (lambda (x) (make-instance 'player :name x :hand (make-hash-table))) players-list))
    (setf ai-player-list (mapcar (lambda (x)
				   (make-instance 'ai-player :name x :hand (make-hash-table)
						  :skill-level (gethash x ai-players-hash)))
					 (get-keys ai-players-hash))) 
    
    (setf player-hash (make-player-hash player-list ai-player-list))
    (setf player-name-list (get-keys player-hash))
   
    ;;make a deck
    (make-deck *standard-suits* *standard-values*)

    ;;shuffle the deck randonly n times
    (loop for i from 1 to (+ 2 (random 8))
	do(shuffle-deck))
	  
    (format t "The deck has been shuffled.~%")
  
    ;;deal cards to players
    (if (<= (hash-table-count player-hash) 3)
	(deal-to-players (get-values player-hash) *max-3-deal*)
      (deal-to-players (get-values player-hash) *max-5-deal*))
    
    ;;create a game instance
    (setf current-game (make-instance 'game
			 :players player-hash
			 :opponents (assign-opponents (get-keys player-hash))))
    
    (format t "Starting the game now...~%")
    
    ;;randomly select the player to play first
    (setf player-to-go (select-random-player player-name-list player-hash))
    (format t "~A has been selected to go first.~%" (name player-to-go))
    
    (loop while (and (not (equal (len-deck) 0))
		     (not (equal return-code *ret-interrupt*))
		     (not (equal (hash-table-count (hand player-to-go)) 0))
		     (not (equal (hash-table-count(hand (get-opponent player-to-go current-game))) 0)))
	do(format t "========================================~%")
	do(setf num-of-turns (1+ num-of-turns))
	do(format t "Turn #:~A~%" num-of-turns)
        do(format t "# of cards left in pool:~A~%" (len-deck))
	do(setf return-code (handle-player player-to-go current-game))
	do(setf player-to-go (get-opponent player-to-go current-game)))
	
    (if (not (equal return-code *ret-interrupt*))
      (progn
	(format t "========================================~%")
	(format t "GAME OVER. The pool or a player's hand is now empty.~%")
	(maphash (lambda (key value) (format t "~A has ~A Books: ~A~%"
					     key (hash-table-count (books value)) (books value))) 
		 (players current-game))
	(format t "After ~A turns, the winner of the game is ~{~A ~}!~%"
		num-of-turns (declare-winner current-game))
	(format t "Would you like to play again (0-No/1-Yes):~%")
	(setf play-again (read))
	))
    play-again))




  
					    


