# Go Fish in LISP
The game of go fish implemented in Lisp.

# The Rules
Go Fish is a classic card game with the goal of getting as many complete sets of cards of the same value as possible (e.g. (3 HEARTS) (3 SPADES) (3 DIAMOND) (3 CLUBS)).   The number of players for this game can range anywhere from 2-5.  Typically, the game maxes out at 5.  

The game starts by shuffling the deck and dealing 5 or 7 random cards for each person.    The number of cards to deal depends on the number of players.  For a 2-3 player game, 7 cards are dealt.  For anything above 3 players 5 cards are dealt.  The remaining cards will make up the pool and be placed faced down in between players.  The game starts off by one player asking the player next to them whether they have cards of a particular value.  For example, “Do you have any 3s?”. It is important to note that the player must have at least 1 card of that rank to ask for it.   If the other player has cards of that rank, he/she must turn over all their cards for that rank.  If the other player does not have cards of that value, then the player must “Go Fish” by selecting a card from the pool and placing it in their hand.  After this, the turn switches to the other player.   When a player gets 4 cards of the same rank (a book), he she must display the book for all players to see.  The game is done with there is no cards left in the pool or if 1 of the players run out of cards.  The winner is determined by the player who has the most books.

# Instructions for Use

1.	After starting your preferred LISP editor, load the file by calling (load “gofish”).
2.	Then type the command (play).
3.	You will be prompted to enter the number of human players and the names of each of those players.
4.	You will be prompted to enter the number of AI players and the names and skill levels of each of those players.
5.	After you do that, the game will immediately start.
6.	For the human players, the game will prompt with it is their turn to go.  They can run more than 1 command.  To see the list of acceptable commands, they can type cmd-help.  Once they are done doing everything they need, human players need to type “next” to complete their turn.
7.	For AI players, the program will automatically handle their turn.  If a card is asked by an AI player to a human player and the human player has that value, the game will automatically transfer the cards over to the AI player from the human player’s hand.


# Overall Goals of the Project

The goals of this project involve creating a REPL to initialize and play the card game.   I’ve made the game flexible enough such that it can be played with all human players, all AI players, or a combination of both.  I’ve added also added a strategic element that serves to implement the artificial intelligence component.  Whenever a player asks for a card, I am keeping track of that ask as well as any cards that are received.  This piece of info is available to the human players to aid their decision of what value to ask for.  This piece of info is an input into the heuristic that I have implemented for an AI player to make an optimal decision.   To make the game more interesting, I’ve also implemented 2 skill levels for the AI player.  In the “Basic” level, the AI player randomly chooses a value to ask for based on what values they hold in their hand.  In the “Advanced” level, the AI player uses a combination of heuristics I’ve implemented to intelligently select a value to ask for.

# High-Level Functional Description of Code

There is a lot of methods in my program, therefore, I have described the major stages of my program in this section.

The main entry into the game is through a function called (play).  In this function, the user is prompted for the number of human and ai players as well as their names.  For AI players, the user is required to indicate a skill level for the ai player they are creating.   A game is then started and played through the (start-game (player-list ai-player-hash) function.  This is perhaps the largest and most important function in my program. It creates all the objects needed in the game, deals out cards to players, and figures out which player will go first.  Once it does that, it executes a loop that continues if there are cards in the pool and all players hands are not empty.   Within the loop, I’ve taken advantage of some of the object-oriented features of LISP.  I was able to implement 2 (handle-player) methods which overload the player parameter.  This allowed for a clean implementation within the loop.  For example, when it’s time for a human player to go, the method will prompt the player for commands rather than automatically select a card.  For an AI player, the method will apply heuristics to select a card.   There are many helper methods which support the (handle-player) methods for both player and AI players.  These methods are clearly organized documented in my code.   Note – there is one method which I borrowed from the Land of Lisp textbook.  It’s the method (read-cmd).  It is documented in my code and cited that I borrowed it from Land of Lisp.

When the loop concludes, all books for all players are printed and a winner is declared.  The very last value that is returned in the (start-game) function is either a value of 0 or 1.  0 indicates the user does not want to play another game.  1 indicates that the user wants to play again.

I’ve added logic to gracefully exit the game.  This can only happen when it’s the turn of a human player.  Doing so will interrupt the loop to exit out.  Furthermore, when a player does not want to play again, I’ve also added a message to gracefully exit out of the program.

# What I Learned

I’ve learned a great deal of functional programming throughout this project.  I made sure that each function that my game uses is only responsible for 1 thing only.  This was a challenge at first, but I gradually got used to it as I continued implementing my program.  Due to the nature of functional programming, I found it very challenging to test functions because it’s important to pass and initialize everything going into the functions.  Furthermore, a function should only return 1 thing.    As a result, I had to put careful thought into how I designed my functions both for ease of testing as well as effectiveness in my program.

I challenged myself to use higher order programming as much as possible.  There are many instances where I used functions such as mapcar, maphash or apply as needed.  This condensed the code quite a bit.  For each of those functions I’ve used lambdas to execute special operations on each of the items in the list or map.

As it relates to AI, I learned the importance of preparing my program to have all the data it needs to make heuristics so that an AI player can intelligently select a card.  While my game is relatively simple, I can only imagine how creating heuristics for a more strategic game can be.   The challenge for having the data available came down to deciding the right structures to hold the data.  Due to the nature of my game, I leaned on a lot of hash maps since organizing the cards by value is important to this game.   It also made it very easy when I needed to transfer a set of cards from one player to another.

Programming in LISP can be fun, addicting, and mildly annoying.  There’s a lot of nuances to this language and the errors that the program spits out may not be as obvious.  Through experience I’ve gotten better at debugging the issues as I go along.    I find that using as much higher order programming and making functions as concise is key to being able to troubleshoot any issues while programming.
