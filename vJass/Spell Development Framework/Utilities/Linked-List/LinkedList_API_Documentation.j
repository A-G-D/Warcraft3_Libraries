//! novjass
|-------------------|
| API Documentation |
|-------------------|
/*
    LinkedList library

        If you are looking for a comprehensive listing of API available for each module, see the header of the
        library itself. What you can find here is the description of ALL avaiable API.

        The library supports 4 different implementations of linked-list:
            - Free lists, where you have freedom in linking and dealing with nodes
              without being restricted by the concept of a 'head node' or a 'container node'
            - Static Lists, which turns a struct into a single list, with the 'head node'
              representing the list itself
            - Non-static Lists, which allows you to have multiple lists within a struct
            - Instantiated Lists, similar to non-static lists but comes with its own methods
              for creating and destroying a list (requires allocate() and deallocate() in the
              implementing struct)

        Note: In all these kind of lists, all nodes should be unique together with the head nodes.
              Lists can also be circular or linear.


    |-----------------|
    | STATIC LIST API |
    |-----------------|

        Interfaces:

          */optional interface static method onInsert takes thistype node returns nothing/*
          */optional interface static method onRemove takes thistype node returns nothing/*
                - onInsert() is called after a node is inserted everytime insert(), pushFront(),
                  or pushBack() is called
                - onRemove() is called before a node is removed everytime remove(), popFront(),
                  or popBack() is called
                - <node> is the node being inserted/removed

          */optional interface method onTraverse takes thistype node returns nothing/*
                - Runs in response to traverseForwards()/traverseBackwards() calls
                - <this> is the head node
                - <node> is the currently traversed node


        Fields:

          */readonly thistype prev/*
          */readonly thistype next/*
          */readonly static thistype front/*
          */readonly static thistype back/*
          */static constant thistype head/*
          */readonly static boolean empty/*
                - <front>, <back>, <head>, and <empty> are method operators


        Methods:

          */static method isLinked takes thistype node returns boolean/*
                - Checks if a node currently belongs to a list

          */static method swap takes thistype nodeA, thistype nodeB returns nothing/*
                - Swaps the placement of two nodes

          */static method contains takes thistype node returns boolean/*
                - Checks if <head> contains the given node
          */static method getSize takes nothing returns integer/*
                - Gets the size of the list <head>
                - Time complexity: O(n)

          */static method traverseForwards takes nothing returns nothing/*
          */static method traverseBackwards takes nothing returns nothing/*
                - traverses a list forwards/backwards and calls onTraverse() for
                  each node in the list

          */static method rotateLeft takes nothing returns nothing/*
          */static method rotateRight takes nothing returns nothing/*

          */static method insert takes thistype prev, thistype node returns nothing/*
          */static method remove takes thistype node returns nothing/*

          */static method pushFront takes thistype node returns nothing/*
                - Inlines to insert() if not on DEBUG_MODE
          */static method popFront takes nothing returns thistype/*

          */static method pushBack takes thistype node returns nothing/*
                - Inlines to insert() if not on DEBUG_MODE
          */static method popBack takes nothing returns thistype/*

          */static method clear takes nothing returns nothing/*
                - Does not call remove() for any node, but only unlinks them from the list
          */static method flush takes nothing returns nothing/*
                - Calls remove() for each node on the list starting from the front to the back node


    |---------------------|
    | NON-STATIC LIST API |
    |---------------------|

          */optional interface static method onInsert takes thistype node returns nothing/*
          */optional interface static method onRemove takes thistype node returns nothing/*
                - onInsert() is called after a node is inserted everytime insert(), pushFront(),
                  or pushBack() is called
                - onRemove() is called before a node is removed everytime remove(), popFront(),
                  or popBack() is called
                - <node> is the node being inserted/removed

          */optional interface method onConstruct takes nothing returns nothing/*
          */optional interface method onDestruct takes nothing returns nothing/*
                - This methods will be called when calling create()/destroy()
                - <this> refers to the list to be created/destroyed

          */interface static method allocate takes nothing returns thistype/*
                - The value returned by this method will be the value returned by create()
          */interface method deallocate takes nothing returns nothing/*
                - This method will be called when calling destroy()

          */optional interface method onTraverse takes thistype node returns nothing/*
                - Runs in response to traverseForwards()/traverseBackwards() calls
                - <this> is the head node
                - <node> is the currently traversed node


        Fields:

          */readonly thistype prev/*
          */readonly thistype next/*
          */readonly thistype front/*
          */readonly thistype back/*
          */readonly boolean empty/*
                - <front>, <back>, and <empty> are method operators


        Methods:

          */static method isLinked takes thistype node returns boolean/*
                - Checks if a node currently belongs to a list

          */static method swap takes thistype nodeA, thistype nodeB returns nothing/*
                - Swaps the placement of two nodes

          */method contains takes thistype node returns boolean/*
                - Checks if <head> contains the given node
          */method getSize takes nothing returns integer/*
                - Gets the size of the list <head>
                - Time complexity: O(n)

          */method traverseForwards takes nothing returns nothing/*
          */method traverseBackwards takes nothing returns nothing/*
                - traverses a list forwards/backwards and calls onTraverse() for
                  each node in the list

          */method rotateLeft takes nothing returns nothing/*
          */method rotateRight takes nothing returns nothing/*

          */static method insert takes thistype prev, thistype node returns nothing/*
          */static method remove takes thistype node returns nothing/*

          */method pushFront takes thistype node returns nothing/*
                - Inlines to insert() if not on DEBUG_MODE
          */method popFront takes nothing returns thistype/*

          */method pushBack takes thistype node returns nothing/*
                - Inlines to insert() if not on DEBUG_MODE
          */method popBack takes nothing returns thistype/*

          */method clear takes nothing returns nothing/*
                - Does not call remove() for any node, but only unlinks them from the list
          */method flush takes nothing returns nothing/*
                - Calls remove() for each node on the list starting from the front to the back node

          */static method create takes nothing returns thistype/*
                - Creates a new list
          */method destroy takes nothing returns nothing/*
                - Destroys the list (Also calls flush internally for InstantiatedListEx)


*///! endnovjass