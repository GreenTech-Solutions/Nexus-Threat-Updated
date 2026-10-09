-- stabilizer.lua
-- This file handles the stabilizer overclocking system independently

local Stabilizer = {}

-- Entity names of all tiers, "shield-stabilizer-1" up to "shield-stabilizer-10" (prototypes/entity/shield_stabilizer.lua)
local TIER_NAMES = {}
for tier = 1, 10 do
    TIER_NAMES[tier] = "shield-stabilizer-" .. tier
end

-- 1. Initialize data storage safely
function Stabilizer.init_storage()
    storage.stabilizer_system = storage.stabilizer_system or {}
    storage.stabilizer_system.machines = storage.stabilizer_system.machines or {}
    storage.stabilizer_system.global_tier = storage.stabilizer_system.global_tier or 1
end

-- The stabilizers on the Nexus surface by unit_number. The shield step in control.lua reads only
-- this list, so it does not have to ask every assembler on Nexus every tick. It is kept current by the build and
-- removal events, and by the two places that replace stabilizers without raising events: on_built (control.lua
-- tracks the entity it returns) and safe_morph_all_stabilizers.
-- Only rescan() creates the list (not init_storage): nil means "never scanned", which control.lua repairs on its
-- first tick, because an update of only the script of this mod version raises no on_configuration_changed.
function Stabilizer.rescan(surface)
    Stabilizer.init_storage()
    storage.stabilizers = {}
    storage.stabilizer_crafts = {} -- progress memory of the shield step, per unit_number
    storage.last_machine_progress = nil -- memory of the removed per-tick shield loop (old saves)
    if not (surface and surface.valid) then return end

    local machines = storage.stabilizer_system.machines
    for _, ent in pairs(surface.find_entities_filtered{name = TIER_NAMES}) do
        storage.stabilizers[ent.unit_number] = ent
        -- Register in the independent system too (a job of the removed 60-tick filter over all assemblers)
        if not machines[ent.unit_number] then
            machines[ent.unit_number] = {
                entity = ent,
                tier = tonumber(string.match(ent.name, "%d+$")) or 1
            }
        end
    end
end

-- A save that switches to this mod from another mod name (the original Nexus-Threat) keeps the stabilizers on the map
-- but not the storage of the old mod: the slider tier would start at 1 again, and the next stabilizer built or the next
-- slider move would turn them all into tier 1. Called from on_init after rescan(), it takes the tier back from the
-- stabilizers that stand (they all have the slider tier; if not, the highest wins).
function Stabilizer.restore_global_tier()
    Stabilizer.init_storage()
    local tier
    for _, data in pairs(storage.stabilizer_system.machines) do
        if data.entity and data.entity.valid and (not tier or data.tier > tier) then
            tier = data.tier
        end
    end
    if tier then
        storage.stabilizer_system.global_tier = tier
    end
end

-- A stabilizer was built on the Nexus surface (after on_built, which may have swapped it for another tier)
function Stabilizer.track(ent)
    if not storage.stabilizers then
        Stabilizer.rescan(ent.surface) -- old save; this scan finds ent as well
    end
    storage.stabilizers[ent.unit_number] = ent
end

-- Drop a destroyed stabilizer from everything that remembers it
function Stabilizer.forget(unit_number)
    if storage.stabilizers then storage.stabilizers[unit_number] = nil end
    if storage.stabilizer_crafts then storage.stabilizer_crafts[unit_number] = nil end
    if storage.stabilizer_system and storage.stabilizer_system.machines then
        storage.stabilizer_system.machines[unit_number] = nil
    end
end

-- 2. Clean up dead entities from the vanilla list
local function clean_invalid_assemblers()
    if not storage.assemblers then return end
    for i = #storage.assemblers, 1, -1 do
        local ent = storage.assemblers[i]
        if not (ent and ent.valid) then
            table.remove(storage.assemblers, i)
        end
    end
end

-- 3. The safe morphing logic for all machines (Manually transfer states)
function Stabilizer.safe_morph_all_stabilizers(new_tier)
    Stabilizer.init_storage()
    
    local old_ids = {}
    local neue_maschinen_erstellt = {}

    for old_id, data in pairs(storage.stabilizer_system.machines) do
        local old_entity = data.entity
        if old_entity and old_entity.valid then
            table.insert(old_ids, old_id)

            local surface = old_entity.surface
            local position = old_entity.position
            local direction = old_entity.direction
            local force = old_entity.force
            
            -- Save crucial states from the old machine before destruction
            local current_recipe = old_entity.get_recipe()
            local progress = old_entity.crafting_progress
            local was_tracked = storage.stabilizers ~= nil and storage.stabilizers[old_id] ~= nil
            
----------------------------------------------------------------------------------------------------
            -- 1. Jetzt darf die alte Entity sicher zerstört werden!
            old_entity.destroy()

            -- 2. Spawn der neuen Tier-Maschine...
            local new_entity = surface.create_entity{
                name = "shield-stabilizer-" .. new_tier,
                position = position,
                force = force,
                direction = direction,
                raise_built = false,
                spill = false
            }

            if new_entity and new_entity.valid then
                table.insert(neue_maschinen_erstellt, {entity = new_entity, tier = new_tier})
                
                if current_recipe then
                    new_entity.set_recipe(current_recipe.name)
                    new_entity.crafting_progress = progress
                end

                -- No event is raised for the new machine, so it takes the old one's place in the shield step's list here
                if was_tracked then
                    storage.stabilizers[new_entity.unit_number] = new_entity
                end

                -- Hier kommt der Block von oben hin:
                if storage.assemblers then
                    local replaced_in_list = false
                    for idx, asm in pairs(storage.assemblers) do
                        if asm and (not asm.valid or (asm.position.x == position.x and asm.position.y == position.y)) then
                            storage.assemblers[idx] = new_entity
                            replaced_in_list = true
                            break
                        end
                    end
                    if not replaced_in_list then
                        table.insert(storage.assemblers, new_entity)
                    end
                end
            end
----------------------------------------------------------------------------------------------------
        end
    end


    -- Clear old IDs from our independent system (and from the shield step's list)
    for _, id in ipairs(old_ids) do
        Stabilizer.forget(id)
    end

    -- Register new IDs into our independent system
    for _, m_data in ipairs(neue_maschinen_erstellt) do
        storage.stabilizer_system.machines[m_data.entity.unit_number] = {
            entity = m_data.entity,
            tier = m_data.tier
        }
    end

    clean_invalid_assemblers()
end

-- 4. Handle when a stabilizer is built
function Stabilizer.on_built(ent)
    if not (ent and ent.valid) then return end
    
    Stabilizer.init_storage()

    -- Matches "shield-stabilizer-1" up to "shield-stabilizer-10"
    if string.find(ent.name, "^shield%-stabilizer%-") then
        local target_tier = storage.stabilizer_system.global_tier or 1
        
        -- If the placed entity doesn't match the current slider tier, swap it instantly
        if ent.name ~= "shield-stabilizer-" .. target_tier then
            local surface = ent.surface
            local position = ent.position
            local direction = ent.direction
            local force = ent.force
            
            ent.destroy()
            
            local morphed_ent = surface.create_entity{
                name = "shield-stabilizer-" .. target_tier,
                position = position,
                force = force,
                direction = direction,
                raise_built = false,
                spill = false
            }
            if morphed_ent and morphed_ent.valid then
                ent = morphed_ent
            end
        end

        storage.stabilizer_system.machines[ent.unit_number] = {
            entity = ent,
            tier = target_tier
        }
        return ent
    end
    return nil
end

-- 5. Handle when a stabilizer is destroyed or mined
function Stabilizer.on_destroy(ent)
    if not (ent and ent.valid) then return end
    -- Not every entity has a unit_number (trees, rocks); this is called for every mined or dying entity
    if ent.unit_number then
        Stabilizer.forget(ent.unit_number)
    end
end

return Stabilizer
