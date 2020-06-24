library MultidimensionalArray /* v1.3


    */uses /*

    */Table /*  http://www.hiveworkshop.com/threads/snippet-new-table.188084/

    [Resource Link] - http://www.hiveworkshop.com/threads/snippet-multidimensional-array.289785/

    *///! novjass

    /*  This snippet allows you to have array storage. Unlike default arrays, you can use an index beyond 8190
        since this snippet uses Tables which uses hashtable. Therefore, saving data with a really large index
        such as using GetHandleId(handle) as the index would not be a problem.

        But you may ask, why would we want to use this when there is already the Table library which can support
        any type that we want to store? First, this has a feature which supports multidimensions that allows you
        to have up to 5-dimensional array. Table already allows you to create multidimensional storage if you do
        proper nesting but this library removes the need for users to do it on their own and this also helps set
        a standard instead of having redundant scripts that work for the same puspose. Secondly, unlike Table,
        this implements a type specific storage i.e., you can create an array storage that is only exclusive for
        a specific type but of course, this also provides a generic storage like Table but with a nicer API.
        Furthermore, this includes some safety precautions such as compile time safety which throws an error if
        you're using an incorrect number of dimensions, as well as preventing the use of an Array instance which
        isn't allocated in DEBUG_MODE. lastly, this gives users a nice and intuitive syntax which resembles that
        of the original vanilla Jass arrays (call KillUnit(u[1][3])) without having a need for an ugly keyword
        at the end (ex: call KillUnit(u[1].unit[3])).                                                           */


    |=========|
    | Credits |
    |=========|

    /*  AGD : Author
        Bribe : For the Table library, and for the algorithm of making n-dimensional storage by nesting Tables  */


    |-----|
    | API |
    |-----|

        Creating an Array:
        /* Creates a new array for a specific type */
            local Unit1D u = Array.create()
            local Unit3D u3 = Unit3D.create()
            local Unit5D u5 = Timer4D.create()              //You could actually use any of the dimensional array creator
            local Array4D a4 = Array.create()

        Storing inside an Array:
        /* Stores data inside an array */
            set u[GetHandleId(timer)] = GetTriggerUnit()
            set u3[0x2000]['AAAA'] = GetTriggerUnit()       //Syntax error: number of indexes does not match with the number of dimensions
            set u5[1][2][3][4][5] = GetTriggerUnit()
            set a4[1][2][3][4].unit = GetTriggerUnit()

        Retrieving from an Array:
        /* Retrieves data from an array */
            call KillUnit(u[1234567])
            call KillUnit(u3['A']['B']['C'])
            call KillUnit(u5[1][2][3][4])                   //Syntax error: number of indexes does not match with the number of dimensions
            call KillUnit(a4[1][2][3][4].unit)

        Checking storage vacancy:
        /* Checks if there is data stored inside an array index */
            return u.has(index)                             //Similar to Table(u).unit.has(index)
            return u3[1][2].has(3)
            return u5[1].has(2)                             //Checks if the fourth dimension has index 2
            return a4[1][2][3].hasHandle(4)

        Removing an Array index:
        /* Destroys the table instance of an index and clears all its child nodes if there are any */
            call u.remove(1)
            call u3[1].remove(2)
            call u5[1][2][3][4][5].remove(6)                //Syntax error: cannot use remove() on a node which has no children
            call a4[1][2][3].removeHandle(4)

        Flushing an Array Index:
        /* Flushes all child nodes attached to the specific index */
            call u.flush()                                  //Flushes all data inside the array, analogous to flushing a parent hashtable
            call u3[1][2][3].flush()                        //Syntax error: cannot flush a node which has no children, use u3[1][2].remove(3) instead
            call u5[1][2].flush()                           //Flushes all child nodes attached to the index "2" of the second dimension
            call a4[1][2].flush()

        Destroying an Array:
        /* Destroys an array instance, flushing all data inside it */
            call u.destroy()
            call u3.destroy()
            call u5[1].destroy()                            //If destroy() is called upon a node which is not a root node, it will work like clear() instead
            call a4.destroy()

    //! endnovjass

    static if DEBUG_MODE then
        private struct S extends array
            static key allocated
        endstruct

        private function Debug takes string msg returns nothing
            call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 60, "|CFFFFCC00[MultidimensionalArray] |R" + msg)
        endfunction
    endif

    private module Init
        private static method onInit takes nothing returns nothing
            local TableArray table = TableArray[3]
            set prev = table[0]
            set next = table[1]
            set list = table[2]
        endmethod
    endmodule

    private struct Node extends array

        static Table prev
        static Table next
        static Table list

        implement Init

        static method allocate takes nothing returns thistype
            local TableArray table = TableArray[2]
            local Table this = table[0]
            local Table head = table[1]
            set list[this] = head
            set prev[head] = head
            set next[head] = head
            return this
        endmethod

        method allocateIndex takes integer index returns integer
            local Table node = Table(this)[index]
            local Table last
            local Table head
            debug if not Table(S.allocated).boolean[this] then
                debug return 0
            debug endif
            if node == 0 then
                set node = allocate()
                set Table(this)[index] = node
                set head = list[node]
                set last = prev[head]
                set prev[head] = node
                set next[last] = node
                set prev[node] = last
                set next[node] = head
            endif
            debug set Table(S.allocated).boolean[node] = true
            return node
        endmethod

        method deallocateIndex takes nothing returns nothing
            local Table head = list[this]
            local Table prevNode = prev[this]
            local Table nextNode = next[this]
            local Table node = next[head]
            loop
                exitwhen node == head
                call thistype(node).deallocateIndex()
                set node = next[node]
            endloop
            set prev[nextNode] = prevNode
            set next[prevNode] = nextNode
            call head.destroy()
            call node.destroy()
        endmethod

        method flush takes nothing returns nothing
            local Table head = list[this]
            local Table node = next[head]
            loop
                exitwhen node == head
                call Node(node).deallocateIndex()
                set node = next[node]
            endloop
        endmethod

    endstruct

    /*============= For a uniform allocator syntax =) ==============*/
    struct Array extends array
        static method create takes nothing returns thistype
            static if DEBUG_MODE then
                local Node this = Node.allocate()
                set Table(S.allocated).boolean[this] = true
                return this
            else
                return Node.allocate()
            endif
        endmethod
    endstruct
    /*==============================================================*/

    /*====================== Struct methods ========================*/
    private module Methods
        static method create takes nothing returns thistype
            return Array.create()
        endmethod
        static if not thistype.remove.exists then
            method remove takes integer index returns nothing
                call Node(Table(this)[index]).deallocateIndex()
            endmethod
        endif
        static if not thistype.has.exists then
            method has takes integer index returns boolean
                return Table(this).has(index)
            endmethod
        endif
        method flush takes nothing returns nothing
            call Node(this).flush()
        endmethod
        method destroy takes nothing returns nothing
            call .flush()
            call Table(this).destroy()
            debug set Table(S.allocated).boolean[this] = false
        endmethod
    endmodule
    /*==============================================================*/

    /*================= Generic Type Array Storage =================*/
    private struct Type extends array

        static key index

        method operator agent= takes agent value returns nothing
            debug if not Table(S.allocated).boolean[this] then
                debug call Debug("|CFFFF0000[Operator agent= ERROR] : Attempted to use a non-allocated array instance|R")
                debug return
            debug endif
            set Table(this).agent[Table(this)[index]] = value
        endmethod

        //! textmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS takes TYPE
        method operator $TYPE$ takes nothing returns $TYPE$
            return Table(this).$TYPE$[Table(this)[index]]
        endmethod
        method operator $TYPE$= takes $TYPE$ value returns nothing
            debug if not Table(S.allocated).boolean[this] then
                debug call Debug("|CFFFF0000[Operator $TYPE$= ERROR] : Attempted to use a non-allocated array instance|R")
                debug return
            debug endif
            set Table(this).$TYPE$[Table(this)[index]] = value
        endmethod
        //! endtextmacro

        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("integer")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("real")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("string")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("boolean")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("player")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("widget")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("destructable")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("item")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("unit")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("ability")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("timer")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("trigger")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("triggercondition")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("triggeraction")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("event")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("force")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("group")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("location")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("rect")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("boolexpr")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("sound")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("effect")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("unitpool")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("itempool")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("quest")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("questitem")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("defeatcondition")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("timerdialog")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("leaderboard")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("multiboard")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("multiboarditem")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("trackable")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("dialog")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("button")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("texttag")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("lightning")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("image")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("ubersplat")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("region")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("fogstate")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("fogmodifier")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_OPERATORS("hashtable")

    endstruct

    struct Array1D extends array
        //! textmacro GENERIC_DIMENSIONAL_ARRAY_METHODS takes NAME, TYPE
        method has$NAME$ takes integer index returns boolean
            return Table(this).$TYPE$.has(index)
        endmethod
        method remove$NAME$ takes integer index returns nothing
            call Table(this).$TYPE$.remove(index)
        endmethod
        //! endtextmacro
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_METHODS("Integer", "integer")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_METHODS("Real", "real")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_METHODS("String", "string")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_METHODS("Boolean", "boolean")
        //! runtextmacro GENERIC_DIMENSIONAL_ARRAY_METHODS("Handle", "handle")
        method has takes integer index returns boolean
            return .hasInteger(index) /*
              */or .hasReal(index)    /*
              */or .hasString(index)  /*
              */or .hasBoolean(index) /*
              */or .hasHandle(index)
        endmethod
        method remove takes integer index returns nothing
            call .removeInteger(index)
            call .removeReal(index)
            call .removeString(index)
            call .removeBoolean(index)
            call .removeHandle(index)
        endmethod
        implement Methods
        method operator [] takes integer index returns Type
            debug if not Table(S.allocated).boolean[this] then
                debug return 0
            debug endif
            set Table(this)[Type.index] = index
            return this
        endmethod
    endstruct

    //! textmacro NEW_DIMENSIONAL_ARRAY_STRUCT takes DIM, RETURNED
    struct Array$DIM$D extends array
        implement Methods
        method operator [] takes integer index returns Array$RETURNED$D
            return Node(this).allocateIndex(index)
        endmethod
    endstruct
    //! endtextmacro

    //! runtextmacro NEW_DIMENSIONAL_ARRAY_STRUCT("2", "1")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY_STRUCT("3", "2")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY_STRUCT("4", "3")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY_STRUCT("5", "4")
    // If you want to increase the maximum number of available
    // dimensions, just run the textmacros above once again like:
    // runtextmacro NEW_DIMENSIONAL_ARRAY_STRUCT("LAST_MAX_DIM + 1", "LAST_MAX_DIM")
    /*==============================================================*/

    /*================ Type Specific Array Storage =================*/
    //! textmacro NEW_DIMENSIONAL_ARRAY takes NAME, TYPE
    struct $NAME$1D extends array
        method remove takes integer index returns nothing
            call Table(this).$TYPE$.remove(index)
        endmethod
        method has takes integer index returns boolean
            return Table(this).$TYPE$.has(index)
        endmethod
        implement Methods
        method operator [] takes integer index returns $TYPE$
            return Table(this).$TYPE$[index]
        endmethod
        method operator []= takes integer index, $TYPE$ value returns nothing
            debug if not Table(S.allocated).boolean[this] then
                debug call Debug("|CFFFFCC00[ArrayType: $NAME$]|R |CFFFF0000[Operator []= ERROR] : Attempted to use a non-allocated array instance|R")
                debug return
            debug endif
            set Table(this).$TYPE$[index] = value
        endmethod
    endstruct

    struct $NAME$2D extends array
        implement Methods
        method operator [] takes integer index returns $NAME$1D
            return Node(this).allocateIndex(index)
        endmethod
    endstruct

    struct $NAME$3D extends array
        implement Methods
        method operator [] takes integer index returns $NAME$2D
            return Node(this).allocateIndex(index)
        endmethod
    endstruct

    struct $NAME$4D extends array
        implement Methods
        method operator [] takes integer index returns $NAME$3D
            return Node(this).allocateIndex(index)
        endmethod
    endstruct

    struct $NAME$5D extends array
        implement Methods
        method operator [] takes integer index returns $NAME$4D
            return Node(this).allocateIndex(index)
        endmethod
    endstruct
    //! endtextmacro
    // If you want to increase the maximum number of available
    // dimensions, just copy the last struct above and increase the
    // number of dimension in the struct name and the returned struct
    // of the operator [] by 1.
    /*==============================================================*/

    /*======== Implement textmacros for every storage type =========*/
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Integer", "integer")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Real", "real")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Str", "string")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Boolean", "boolean")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Player", "player")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Widget", "widget")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Destructable", "destructable")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Item", "item")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Unit", "unit")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Ability", "ability")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Timer", "timer")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Trigger", "trigger")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("TriggerCondition", "triggercondition")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("TriggerAction", "triggeraction")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("TriggerEvent", "event")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Force", "force")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Group", "group")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Location", "location")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Rect", "rect")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("BooleanExpr", "boolexpr")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Sound", "sound")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Effect", "effect")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("UnitPool", "unitpool")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("ItemPool", "itempool")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Quest", "quest")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("QuestItem", "questitem")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("DefeatCondition", "defeatcondition")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("TimerDialog", "timerdialog")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Leaderboard", "leaderboard")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Multiboard", "multiboard")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("MultiboardItem", "multiboarditem")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Trackable", "trackable")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Dialog", "dialog")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Button", "button")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("TextTag", "texttag")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Lightning", "lightning")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Image", "image")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Ubersplat", "ubersplat")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Region", "region")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("FogState", "fogstate")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("FogModifier", "fogmodifier")
    //! runtextmacro NEW_DIMENSIONAL_ARRAY("Hashtable", "hashtable")
    /*==============================================================*/


endlibrary
