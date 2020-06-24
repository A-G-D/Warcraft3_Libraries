library ItemCharges /*


    */uses /*

    */RegisterPlayerUnitEvent   /*
    */Initializer               /*

    */
    function IsItemCharged takes item whichItem returns boolean
        return GetItemType(whichItem) == ITEM_TYPE_CHARGED
    endfunction

    private function OnItemAcquire takes nothing returns nothing
        local item acquired = GetManipulatedItem()
        local item itemInSlot
        local integer i
        local integer id
        local unit u
        if IsItemCharged(acquired) then
            set id = GetItemTypeId(acquired)
            set u = GetTriggerUnit()
            set i = 6
            loop
                set i = i - 1
                set itemInSlot = UnitItemInSlot(u, i)
                if GetItemTypeId(itemInSlot) == id and itemInSlot != acquired then
                    call SetItemCharges(itemInSlot, GetItemCharges(itemInSlot) + GetItemCharges(acquired))
                    call RemoveItem(acquired)
                endif
                set itemInSlot = null
                exitwhen i == 0
            endloop
            set u = null
        endif
        set acquired = null
    endfunction

    //! runtextmacro INITIALIZER()
    call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, function OnItemAcquire)
    //! runtextmacro END_INITIALIZER()


endlibrary
