Glossary
======
We adopt [Communicating Sequential Processes](https://en.wikipedia.org/wiki/Communicating_sequential_processes) (CSP) as the theory for specification description and implementation modeling.
Therefore, many terms are derived from CSP.


## State Machine
A state machine is a labeled directed graph consisting of an initial state and a set of (state, event, state) tuples.


## Event
An event is a trigger for state transitions. Events include UI operations, timer fires, and communication send/receive.


## Internal Transition
An internal transition is an automatic state transition that occurs within a state machine alone.
Timer fires and events hidden within the state machine are the main internal transitions.


## Stable State
A state is stable when no internal transitions can occur from that state. A stable state is called a stable state.


## Interface Parallel
Interface parallel means composing two or more state machines into one state machine by specifying zero or more synchronizing events.
The state of the composed state machine becomes a tuple of all states like (A, B, C, D, ...) where A, B, C, D, ... are the respective states of the state machines before composition.
The initial state is a tuple consisting of the initial states of each state machine.

Starting from the initial state, the state transition graph is constructed according to the following rules:

When there are states P1, P2, Q1, Q2 and event a, where P1 transitions to P2 with event a, and Q1 also transitions to Q2 with event a:

* If the synchronizing events include a, the composed states become (P1, Q1) and (P2, Q2), and (P1, Q1) transitions to (P2, Q2) with event a. Synchronizing events must not include internal transitions
* If the synchronizing events do not include a, the composed states become (P1, Q1), (P2, Q1), and (P1, Q2), and (P1, Q1) transitions to either (P2, Q1) or (P1, Q2) with event a


## Specification
A specification is a mathematical function that determines the correctness of implementation behavior.
If the target system is a reactive system, it is expressed in CSP.
If the target system is a system that eventually stops and returns output when given input, it is expressed as a pair of preconditions and postconditions.


## Requirements
Requirements are properties that the boundary between the problem domain and the system must satisfy.


## Functional Requirements
Functional requirements are those among requirements that can be expressed as a binary true/false value for whether they are satisfied or not.

If the target system is a reactive system, they are typically traces of main cases or constraints on traces expressed in temporal logic formulas.
If the target system is a system that eventually stops and returns output when given input, they are a set of pairs consisting of main case inputs and their expected outputs.


## Non-functional Requirements
Non-functional requirements are those among requirements that cannot be expressed as a binary true/false value for whether they are satisfied or not.
Typically, performance requirements and security requirements fall into this category.
