# interview

Hands-on session Flutter interview.

In this guessing game, players must type the name of an animal. If they guess correctly, they earn a point and the word becomes visible in a list or grid. The game ends when the time runs out.

# ui design architecture

We will be using a simple custom impl for Bloc pattern to handle UI state. (Notes that there are other state management solution provided as packages: provider, Bloc, Redux, etc)

UI --add event--> GameInteractor.input ----> GameInteractor.handleInput ----> GameModel.whatever

UI.streamBuilder --listen--> GameInteractor.output

The state management for this project could have been handled using setState and interacting with GameModel diractly from the UI, however, we chose to demonstrate a more advanced method.

# to improve

* The UI is currently in wireframe form and requires further refinement. 
* The list or grid displaying the guessed words can be constructed dynamically using a ListView or GridView. 
* The current Bloc impl needs a kind of Bloc.of(context) to have a decent share state management, other wise you will be injecting the Bloc all along the widget tree to get acces to the shared state.
* The StreamBuilder is located at the top widget level, causing all widgets to be rebuilt with each update, even if they haven't changed. To optimize this, we can have more granular Blocs ... one for the text input-score-guess and one for the timer, or, use one stream output for updating the word and score label when a word is guessed, and another stream output for updating the countdown timer label.
* Unit tests for the GameModel should be implemented, even though it is not explicitly required in the task description..
