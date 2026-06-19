-- control.lua 


local Stabilizer = require("stabilizer")


if settings.startup["nexus-threat-activation"].value then --"MOD SETTING" MOD-ADDON ON/OFF





 -- control.lua

local function load_nexus_config()
    return {
    PLANET_NAME = "nexus",
    MAX_SHIELD = settings.global["nt-max-shield"].value,				-- CHANGE MAXIMUM SHILD ENERGY:
    DRILL_INCREASE_RATE = settings.global["nt-drill-rate"].value,		-- CHANGE DRILL INCREASING INSTABILITY: 0.01 = 1 % alle 100 Sekunden pro Bohrer
    STORM_CHANCE_MULT = settings.global["nt-storm-chance"].value,		-- CHANGE STORM CHANCE:
    SHIELD_REGEN_RATE = settings.global["nt-shield-regen"].value,		-- CHANGE SHIELD REGENERATION AMOUNT:

    SHIELD_DRAIN_MULT = settings.global["nt-shield-drain"].value,		-- CHANGE DAMAGE TO THE SHIELD:
    
    BASE_DAMAGE = settings.global["nt-base-damage"].value,				-- CHANGE DAMAGE FROM LIGHTNING:
    DAMAGE_INC_PER_INSTAB = settings.global["nt-damage-inc"].value,		-- CHANGE INCREASED DAMAGE DUE TO INSTABILITY:
    STORM_DURATION_BASE = settings.global["nt-storm-dur-base"].value,	-- CHANGE STORM DURATION BASE:
    STORM_DURATION_MULT = settings.global["nt-storm-dur-mult"].value,	-- CHANGE STORM DURATION MULTIPLIER:
    
    
    RECIPE_BONUS_RATE = settings.global["nt-recipe-bonus"].value,		-- CHANGE SHIELD LOADING SPEED: 10.0 = 10 Schild-Energie pro Sekunde
	DRILL_UPDATE_INTERVAL = settings.global["nt-drill-interval"].value,	-- PERFORMANCE: CALCULATE DRILLS EVERY X TICKS (1-60)
    
	WILD_LIGHTNING_CHANCE = 15,     -- MAX CHANCE FOR WILD LIGHTNING (0-100)
    WILD_LIGHTNING_COUNT = 5        -- MAX ATTEMPTS FOR WILD LIGHTNING PER TICK

   }
end
local CONFIG = load_nexus_config()

-- NEW: Feature for creating the main button (Secure Sprite Path)
local function create_toggle_button(player)
    if not player.gui.top.nexus_toggle_button then
        player.gui.top.add{
            type = "sprite-button",
            name = "nexus_toggle_button",
            sprite = "nexus-button-sprite", -- inside date.lua on top
            style = "mod_gui_button",
            tooltip = "Planet Status"
        }
    end
end




script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    CONFIG = load_nexus_config()
end)

-- NEW: This feature scans the planet (OPTIMIZED FOR MEGABASES!)
local function rebuild_entity_lists()
    local surface = game.get_surface(CONFIG.PLANET_NAME)
    if not (surface and surface.valid) then return end

    storage.drills = {}
    storage.assemblers = {}
    storage.combinators = {}
    storage.lightning_targets = {}

    local all_entities = surface.find_entities_filtered{
        force = "player",
        type = {
            "mining-drill", 
            "assembling-machine", 
            "constant-combinator", 
            "radar", 
            "electric-pole", 
            "solar-panel", 
            "accumulator", 
            "lab"
        }
    }

    for _, ent in pairs(all_entities) do
        if ent.valid then
            local e_type = ent.type
            if e_type == "mining-drill" then 
                table.insert(storage.drills, ent)
            elseif e_type == "assembling-machine" then 
                table.insert(storage.assemblers, ent)
            elseif ent.name == "constant-combinator" then 
                table.insert(storage.combinators, ent)
            end

            local target_types = {["radar"]=true, ["electric-pole"]=true, ["solar-panel"]=true, ["accumulator"]=true, ["lab"]=true}
            if target_types[e_type] then
                table.insert(storage.lightning_targets, ent)
            end
        end
    end
end

-- This feature adds entities to our lists ( storage )
local function on_entity_created(event)
    local ent = event.entity or event.created_entity
    if not (ent and ent.valid) then return end
    
    -- ========================================================================
    -- FIX: Registers both the base name AND all numbered tiers!
    -- Supports "shield-stabilizer" and "shield-stabilizer-1" up to "-10"
    -- ========================================================================
    if ent.name == "shield-stabilizer" or string.find(ent.name, "^shield%-stabilizer") then
        local registrierte_entity = Stabilizer.on_built(ent)
        if registrierte_entity then 
            -- If we are on the Nexus planet, we also add it to your main assembler list
            if registrierte_entity.surface.name == CONFIG.PLANET_NAME then
                storage.assemblers = storage.assemblers or {}
                table.insert(storage.assemblers, registrierte_entity)
            end
            return -- Stop here for the stabilizer so it doesn't get double-processed below
        end
    end
    -- ========================================================================

    if ent.surface.name == CONFIG.PLANET_NAME then
        storage.drills = storage.drills or {}
        storage.assemblers = storage.assemblers or {}
        storage.combinators = storage.combinators or {}
        storage.lightning_targets = storage.lightning_targets or {}

        if ent.type == "mining-drill" then 
            table.insert(storage.drills, ent)
        elseif ent.type == "assembling-machine" then 
            table.insert(storage.assemblers, ent)
        elseif ent.name == "constant-combinator" then 
            table.insert(storage.combinators, ent) 

            -- NEW: Register for object destroyed to handle cleanups later
            local control = ent.get_control_behavior()
            if control then
                local has_nexus_signal = false
                for _, section in pairs(control.sections) do
                    for _, slot in pairs(section.filters) do
                        if slot.value and (slot.value.name == "nexus_charge" or slot.value.name == "shield_energy") then
                            has_nexus_signal = true
                            break
                        end
                    end
                    if has_nexus_signal then break end
                end

                if has_nexus_signal then
                    storage.nexus_connected_combinators = storage.nexus_connected_combinators or {}
                    if not storage.nexus_connected_combinators[ent.unit_number] then
                        script.register_on_object_destroyed(ent)
                        storage.nexus_connected_combinators[ent.unit_number] = ent
                    end
                end
            end
        end
		
        local target_types = {["radar"]=true, ["electric-pole"]=true, ["solar-panel"]=true, ["accumulator"]=true, ["lab"]=true}
        if target_types[ent.type] then
            table.insert(storage.lightning_targets, ent)
        end
    end
end



script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built, defines.events.on_space_platform_built_entity}, on_entity_created)

-- BRIDGE TO STABILIZER FILE: Handle mining and destruction
script.on_event({
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_entity_died,
    defines.events.script_raised_destroy
}, function(event)
    local ent = event.entity
    if ent and ent.valid then
        Stabilizer.on_destroy(ent)
    end
end)


script.on_init(function()
    storage.lightning_targets = {}
    storage.drills = {}
    storage.assemblers = {}
    storage.combinators = {}
    storage.nexus_charge = storage.nexus_charge or 0
    storage.shield_energy = storage.shield_energy or 0
    storage.storm_timer = 0
    storage.gui_enabled = storage.gui_enabled or {}
    
    -- BRIDGE TO STABILIZER FILE: Initialize independent storage
    Stabilizer.init_storage()
    
    rebuild_entity_lists()
    for _, player in pairs(game.players) do
        create_toggle_button(player)
    end
end)


script.on_configuration_changed(function()
    rebuild_entity_lists()
    for _, player in pairs(game.players) do
        create_toggle_button(player)
    end
end)

-- NEW: Event handler for button clicks
script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "nexus_toggle_button" then
        local player = game.players[event.player_index]
        storage.gui_enabled = storage.gui_enabled or {}
        
        if player.gui.top.nexus_frame then
            player.gui.top.nexus_frame.destroy()
            storage.gui_enabled[player.index] = false
        else
            storage.gui_enabled[player.index] = true
            -- The GUI will be automatically created in the next on_tick
        end
    end
end)

script.on_event(defines.events.on_tick, function(event)

    -- BRIDGE TO STABILIZER FILE: Safely morph machines outside the GUI tick
    if storage.stabilizer_system and storage.stabilizer_system.needs_morph then
        storage.stabilizer_system.needs_morph = false
        local target_tier = storage.stabilizer_system.global_tier or 1
        
        -- DEBUG 3: Zeigt an, dass der on_tick den Befehl erhalten hat
        --game.print("DEBUG 3: on_tick hat 'needs_morph' erkannt! Starte Tausch auf Stufe: " .. target_tier)
        
        Stabilizer.safe_morph_all_stabilizers(target_tier)
    end

    local surface = game.get_surface(CONFIG.PLANET_NAME)
    if not surface or not surface.valid then return end


    -- 2. INSTABILITY & LAZY CLEANUP (Drills)
    -- Runs every X ticks based on DRILL_UPDATE_INTERVAL for better performance
    if event.tick % CONFIG.DRILL_UPDATE_INTERVAL == 0 then
        local factor = CONFIG.DRILL_UPDATE_INTERVAL
        for i = #storage.drills, 1, -1 do
            local d = storage.drills[i]
            if d and d.valid then
                if d.status == defines.entity_status.working then
                    -- We calculate: (Rate / 60 = value per tick) * factor
                    storage.nexus_charge = math.min(100, (storage.nexus_charge or 0) + (CONFIG.DRILL_INCREASE_RATE / 60 * factor))
                end
            else table.remove(storage.drills, i) end
        end
    end

    -- 2.1 SHIELD CALCULATION (Assemblers)
    -- Runs every tick for maximum precision when intercepting lightning bolts
    for i = #storage.assemblers, 1, -1 do
        local machine = storage.assemblers[i]
        if machine and machine.valid then
            if machine.status == defines.entity_status.working or machine.status == defines.entity_status.low_power then
                local recipe = machine.get_recipe()
                if recipe and recipe.name == "nexus-stabilization-process" then
                    
                    -- 1. We retrieve the current progress of the recipe (value ranging from 0.0 to 1.0)
                    local current_progress = machine.crafting_progress
                    
                    -- 2. We retrieve the previous tick's progress (stored in a table)
                    storage.last_machine_progress = storage.last_machine_progress or {}
                    local machine_unit_number = machine.unit_number or i -- If there is no unit_number, we use the index
                    local last_progress = storage.last_machine_progress[machine_unit_number] or 0
                    
                    -- 3. We calculate how far the bar has moved in THIS tick (the delta)
                    local progress_delta = current_progress - last_progress
                    
                    -- If the recipe finished in this tick and starts over from the beginning, the delta is negative. 
                    -- In that case, we simply set the value to the maximum to account for calculation errors.
                    if progress_delta < 0 then
                        progress_delta = (machine.crafting_speed / 60) / recipe.energy
                    end
                    
                    -- 4. We calculate how fast the machine SHOULD run at 100% power:
                    -- (crafting_speed / 60 ticks) divided by the recipe duration in seconds
                    local expected_progress_per_tick = (machine.crafting_speed / 60) / recipe.energy
                    
                    -- 5. The continuous power factor: Actual progress divided by expected progress!
                    local power_factor = 1.0
                    if expected_progress_per_tick > 0 then
                        power_factor = math.min(1.0, progress_delta / expected_progress_per_tick)
                    end
                    
                    -- Safety net: When progress is extremely slow or the machine is idle
                    if progress_delta == 0 or machine.status == defines.entity_status.no_power then
                        power_factor = 0.0
                    end
                    
                    -- Save the value for the next tick to memory
                    storage.last_machine_progress[machine_unit_number] = current_progress
                    
                    -- CALCULATION: The shield charges continuously!
                    -- If the C++ engine throttles the recipe by 40% due to a power shortage, exactly 40% less shield power is generated.
                    local bonus = (CONFIG.RECIPE_BONUS_RATE / 60) * machine.crafting_speed * power_factor
                    storage.shield_energy = math.min(CONFIG.MAX_SHIELD, (storage.shield_energy or 0) + bonus)
                end
            else
                -- When the machine stops running, we reset its progress memory
                if storage.last_machine_progress then
                    local machine_unit_number = machine.unit_number or i
                    storage.last_machine_progress[machine_unit_number] = nil
                end
            end
        else table.remove(storage.assemblers, i) end
    end









    -- 3. STORM LOGIC (EXACT SECONDS)
    if event.tick % 60 == 0 then
        if storage.storm_timer > 0 then
            -- We subtract 1 only once per second (every 60 ticks)
            storage.storm_timer = storage.storm_timer - 1
            
            -- Transition from warning to active steering
            if storage.storm_timer <= 0 and storage.is_warning then
                storage.is_warning = false 
                storage.storm_timer = CONFIG.STORM_DURATION_BASE + math.ceil((storage.nexus_charge or 0) * CONFIG.STORM_DURATION_MULT)
                surface.print("CRITICAL: Nexus-Storm impact imminent!", {1, 0, 0})
            end
        else
            -- New storm check (only if no storm is active)
            local instability_val = storage.nexus_charge or 0
            if math.random(1, 1000) <= (instability_val * CONFIG.STORM_CHANCE_MULT) then
                local tech = game.forces["player"].technologies["nexus-storm-prediction"]
                if tech and tech.researched then
                    storage.storm_timer = math.random(120, 600) 
                    storage.is_warning = true 
                    surface.print({"nexus-mod.msg-detected", storage.storm_timer}, {1, 0.8, 0})
                else
                    storage.storm_timer = CONFIG.STORM_DURATION_BASE + math.ceil(instability_val * CONFIG.STORM_DURATION_MULT)
                    storage.is_warning = false 
                    surface.print({"nexus-mod.warning-event", CONFIG.PLANET_NAME}, {1, 0.2, 0.2})
                end
            end
        end
    end

    -- 4. GUI UPDATE & SIGNALS (Only every 60 ticks for performance)
    if event.tick % 60 == 0 then
        -- GUI Update for All Players
        local instability = storage.nexus_charge or 0
        local shield = storage.shield_energy or 0
        local storm_t = storage.storm_timer or 0

        -- ========================================================================
        -- HIGH-PERFORMANCE: Update only registered combinators (CRITICAL BUGFIX HERE!)
        -- ========================================================================
        if storage.nexus_connected_combinators then
            for id, comb in pairs(storage.nexus_connected_combinators) do
                -- CRITICAL ENGINE FIX: Strictly verify that it is actually a valid constant-combinator
                -- to prevent Factorio from throwing random progressbar pointer errors during fast_replace!
                if comb and comb.valid and comb.type == "constant-combinator" then
                    local control = comb.get_control_behavior()
                    if control then
                        -- Loop through sections and slots to update our specific signals
                        for _, section in pairs(control.sections) do
                            for slot_index, slot in pairs(section.filters) do
                                if slot.value then
                                    if slot.value.name == "nexus_charge" then
                                        section.set_slot(slot_index, {
                                            value = slot.value,
                                            count = math.floor(instability),
                                            min = math.floor(instability),
                                            max = math.floor(instability)
                                        })
                                    elseif slot.value.name == "shield_energy" then
                                        section.set_slot(slot_index, {
                                            value = slot.value,
                                            count = math.floor(shield),
                                            min = math.floor(shield),
                                            max = math.floor(shield)
                                        })
                                    end
                                end
                            end
                        end
                    end
                else
                    -- Remove any invalid or corrupted entities safely
                    storage.nexus_connected_combinators[id] = nil
                end
            end
        end
		
		
        -- ========================================================================

        -- ========================================================================
        -- INDEPENDENT FILTER: Register stabilizers directly from your assembler list
        -- This is NOT a surface scan! It only reads the local lua table.
        -- ========================================================================
        Stabilizer.init_storage()
        if storage.assemblers then
            for _, asm in pairs(storage.assemblers) do
                if asm and asm.valid and string.find(asm.name, "^shield%-stabilizer") then
                    -- If this stabilizer is not yet tracked in our independent system, add it!
                    if not storage.stabilizer_system.machines[asm.unit_number] then
                        local tier = tonumber(string.match(asm.name, "%d+$")) or 1
                        storage.stabilizer_system.machines[asm.unit_number] = {
                            entity = asm,
                            tier = tier
                        }
                    end
                end
            end
        end
        -- ========================================================================

        -- We retrieve the current global tier state from memory
        local current_global_tier = 1
	if storage.stabilizer_system and storage.stabilizer_system.global_tier then
		current_global_tier = storage.stabilizer_system.global_tier
	end

        for _, p in pairs(game.players) do
            if p.valid then
                create_toggle_button(p) -- Ensure the main button exists

                -- Show only if player is on the planet AND has the GUI toggled open
                if p.surface and p.surface.name == CONFIG.PLANET_NAME and storage.gui_enabled and storage.gui_enabled[p.index] then
                    
                    local gui = p.gui.top.nexus_frame
                    
                    -- Savegame check: If old verbugged elements are cached, wipe it once
                    if gui and (not gui.row1 or not gui.pbar_instability) then
                        gui.destroy()
                        gui = nil
                    end
                    
                    -- BUILD THE GUI ONLY ONCE (No lag!)
                    if not gui then
                        gui = p.gui.top.add{type="frame", name="nexus_frame", direction="vertical"}
                        
                        -- ROW 1: Instability Text
                        local r1 = gui.add{type="flow", name="row1", direction="horizontal"}
                        local lbl_instab = r1.add{type="label", caption={"nexus-mod.instability"}}
                        lbl_instab.style.font = "default-bold"
                        lbl_instab.style.minimal_width = 120 -- Fixed size stops GUI from shaking!
                        
                        r1.add{type="empty-widget"}.style.horizontally_stretchable = true
                        r1.add{type="label", name="lbl_instab_val"}
                        
                        -- Progressbar sits cleanly below the text now
                        local bar_i = gui.add{type="progressbar", name="pbar_instability"}
                        bar_i.style.minimal_width = 240
                        bar_i.style.color = {1, 0, 0}
                        
                        -- ROW 2: Shield Energy Text
                        local r2 = gui.add{type="flow", name="row2", direction="horizontal"}
                        local lbl_shield = r2.add{type="label", caption={"nexus-mod.shield"}}
                        lbl_shield.style.font = "default-bold"
                        lbl_shield.style.minimal_width = 120 -- Fixed size stops GUI from shaking!
                        
                        r2.add{type="empty-widget"}.style.horizontally_stretchable = true
                        r2.add{type="label", name="lbl_shield_val"}
                        
                        -- Progressbar sits cleanly below the text now
                        local bar_s = gui.add{type="progressbar", name="pbar_shield_energy"}
                        bar_s.style.minimal_width = 240
                        bar_s.style.color = {0, 0.5, 1}
                        
                        gui.add{type="line", name="line1", direction="horizontal"}
                        gui.add{type="label", name="lbl_status"}

                    -- STABILIZER SLIDER SECTION
                    gui.add{type="line", name="stabilizer_line", direction="horizontal"}
                    
                    local s_flow = gui.add{type="flow", name="stabilizer_flow", direction="vertical"}
                    local s_row = s_flow.add{type="flow", name="tier_row", direction="horizontal"}
                    

                    local lbl_limit = s_row.add{type="label", caption={"nexus-mod.nexus-mod-stabilizer-limit"}}
                    lbl_limit.style.font = "default-bold"
                    lbl_limit.style.minimal_width = 120
                    
                    s_row.add{type="label", name="lbl_stab_tier_val"}

                        
                        local slider = s_flow.add{
                            type = "slider",
                            name = "stabilizer_global_slider",
                            minimum_value = 1,
                            maximum_value = 10,
                            value = current_global_tier,
                            value_step = 1
                        }
                        slider.style.minimal_width = 240
                    end

                    -- INDEPENDENT UPDATE PATHS (No more layout pushing!)
                    if gui.pbar_instability then
                        gui.pbar_instability.value = instability / 100
                    end
                    if gui.row1 and gui.row1.lbl_instab_val then
                        gui.row1.lbl_instab_val.caption = string.format("%.2f%%", instability)
                    end
                    
                    if gui.pbar_shield_energy then
                        gui.pbar_shield_energy.value = shield / CONFIG.MAX_SHIELD
                    end
                    if gui.row2 and gui.row2.lbl_shield_val then
                        gui.row2.lbl_shield_val.caption = math.floor(shield) .. " / " .. CONFIG.MAX_SHIELD
                    end

                    -- Status Text Logic
                    if gui.lbl_status then
                        if storm_t > 0 then
                            if storage.is_warning then
                                gui.lbl_status.caption = {"nexus-mod.status-warning", storm_t}
                                gui.lbl_status.style.font_color = {1, 0.8, 0.2}
                            else
                                gui.lbl_status.caption = {"nexus-mod.status-active", storm_t}
                                gui.lbl_status.style.font_color = {1, 0.2, 0.2}
                            end
                        else
                            gui.lbl_status.caption = {"nexus-mod.status-stable"}
                            gui.lbl_status.style.font_color = {0.2, 1, 0.2}
                        end
                    end

                    -- Live-Update for stabilizer text
                    if gui.stabilizer_flow and gui.stabilizer_flow.tier_row and gui.stabilizer_flow.tier_row.lbl_stab_tier_val then
                        gui.stabilizer_flow.tier_row.lbl_stab_tier_val.caption = (current_global_tier * 10) .. "% (" .. (current_global_tier * 50) .. " GW)"
                    end

                else
                    if p.gui.top.nexus_frame then p.gui.top.nexus_frame.destroy() end
                end
            end
        end
    end










    -- 5. BLITZ LOGIC (ORIGINAL MASS + PERFORMANCE FIX)
    if storage.storm_timer > 0 and not storage.is_warning then
        local instability = storage.nexus_charge or 0
        
        -- PERFORMANCE: We calculate the number of lightning strikes for this tick
        -- At 100% instability, we attempt up to 3 lightning strikes per tick (180 per second!)
        local blitz_attempts = 1
        if instability >= 50 then 
            blitz_attempts = math.random(1, 3) 
        end

        for a = 1, blitz_attempts do
            -- GLOBAL CHECK
            if math.random(1, 100) <= (5 + instability) then
                -- PERFORMANCE:
                local pool_selector = math.random(1, 3)
                local current_pool = storage.drills
                if pool_selector == 2 then current_pool = storage.assemblers
                elseif pool_selector == 3 then current_pool = storage.lightning_targets end
                
                if current_pool and #current_pool > 0 then
                    local rand_idx = math.random(#current_pool)
                    local anchor = current_pool[rand_idx]
                    
                    if anchor and anchor.valid then
                        local strike_pos = {
                            x = anchor.position.x + math.random(-15, 15), 
                            y = anchor.position.y + math.random(-15, 15)
                        }
                        
                        surface.create_entity{name = "lightning", position = strike_pos}
                        
                        -- DAMAGE LOGIC WITH IMPACT
                        local damage_amount = CONFIG.BASE_DAMAGE + (instability * CONFIG.DAMAGE_INC_PER_INSTAB)
                        local current_shield = storage.shield_energy or 0

                        if current_shield > (damage_amount * CONFIG.SHIELD_DRAIN_MULT) then
                            -- The shield is strong enough to withstand this blow
                            storage.shield_energy = current_shield - (damage_amount * CONFIG.SHIELD_DRAIN_MULT)
                        else
                            -- The shield is no longer enough! 
                            -- Set the shield to 0
                            storage.shield_energy = 0
                            
                            -- 2. Calculate residual damage (penetration)
                            local blocked_damage = current_shield / CONFIG.SHIELD_DRAIN_MULT
                            local leaked_damage = math.max(0, damage_amount - blocked_damage)
                            
                            -- 3. Hit nearby buildings (only if there is damage remaining)
                            if leaked_damage > 0 then
                                local targets = surface.find_entities_filtered{position = strike_pos, radius = 3, force = "player"}
                                for _, t in pairs(targets) do
                                    if t.valid and t.health then 
                                        t.damage(leaked_damage, "neutral", "electric") 
                                    end
                                end
                            end
                        end
                    else
                        -- If the anchor was no longer valid (e.g., destroyed), remove it from the list
                        table.remove(current_pool, rand_idx)
                    end
                end
            end
        end

        -- Wild lightning (CONFIGURABLE VERSION)
        local wild_attempts = 1
        if instability >= 50 then 
            wild_attempts = math.random(1, CONFIG.WILD_LIGHTNING_COUNT) 
        end

        for w = 1, wild_attempts do
            local current_chance = (CONFIG.WILD_LIGHTNING_CHANCE / 100) * instability
            if instability < 10 then current_chance = 5 end 

            if math.random(1, 100) <= current_chance then
                local chunk = surface.get_random_chunk()
                if chunk then
                    surface.create_entity{
                        name = "lightning", 
                        position = {
                            x = chunk.x * 32 + math.random(0, 31), 
                            y = chunk.y * 32 + math.random(0, 31)
                        }
                    }
                end
            end
        end
    end
end)



-- COMMANDS
commands.add_command("reset_nexus", "Setzt die Nexus-Instabilität auf 0", function()
    storage.nexus_charge = 0
    game.print({"nexus-mod.cmd-reset"})
end)

commands.add_command("sturm_start", "Löst sofort ein Energie-Event (Sturm) aus", function()
    local instability = storage.nexus_charge or 50
    -- We estimate the duration of the storm
    storage.storm_timer = CONFIG.STORM_DURATION_BASE + math.ceil(instability * CONFIG.STORM_DURATION_MULT)
    
    -- IMPORTANT: We tell the game that the warning is OVER
    storage.is_warning = false 
    
    game.print({"nexus-mod.cmd-storm-manual"}, {1, 0.2, 0.2})
end)


commands.add_command("sturm_start_timer", "Löst sofort ein Energie-Event (Sturm) mit Vorwarnung aus", function()
    -- Simulates the random lead time (120–600 seconds)
    storage.storm_timer = math.random(120, 600) 
    storage.is_warning = true 
    
    -- Displays the message in the chat (uses locale)
    game.print({"nexus-mod.msg-detected", storage.storm_timer}, {1, 0.8, 0})
end)



commands.add_command("sturm_stop", "Beendet den aktuellen Sturm sofort", function()
    storage.storm_timer = 0
    game.print({"nexus-mod.cmd-storm-stop"}, {0, 1, 0})
end)

commands.add_command("set_nexus", "Set instability (0-100)", function(event)
    local eingabe = tonumber(event.parameter)
    if not eingabe or eingabe < 0 or eingabe > 100 then
        game.print("Error: Invalid value. Please enter a number between 0 and 100.")
        return
    end
    storage.nexus_charge = eingabe
    game.print("Nexus-instability set to " .. storage.nexus_charge .. "%")
end)


commands.add_command("check_storage", "Zeigt die Anzahl der gespeicherten Objekte", function()
    local d = #storage.drills
    local a = #storage.assemblers
    local z = #storage.lightning_targets
    game.print("Speicher-Check: Bohrer: " .. d .. " | Maschinen: " .. a .. " | Blitz-Ziele: " .. z)
end)

-- Konsolen-Befehl: /nexus-refresh
commands.add_command("nexus-refresh", "Initialisiert alle Listen der Nexus-Mod neu", function()
    rebuild_entity_lists()
    game.print("Nexus-Listen wurden erfolgreich neu geladen!")
end)







---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------






-- Event: Fires when a player closes any GUI (including combinators)
script.on_event(defines.events.on_gui_closed, function(event)
    -- Check if the closed GUI was an entity and if it is a constant combinator
    if event.entity and event.entity.valid and event.entity.name == "constant-combinator" then
        local entity = event.entity
        local control = entity.get_control_behavior()
        if not control then return end

        -- Check all sections and slots to see if our custom signals are being used
        local has_nexus_signal = false
        for _, section in pairs(control.sections) do
            for _, slot in pairs(section.filters) do
                if slot.value and (slot.value.name == "nexus_charge" or slot.value.name == "shield_energy") then
                    has_nexus_signal = true
                    break
                end
            end
            if has_nexus_signal then break end
        end

        -- Ensure the storage table exists
        storage.nexus_connected_combinators = storage.nexus_connected_combinators or {}

        if has_nexus_signal then
            -- Only register if it's not already in our list
            if not storage.nexus_connected_combinators[entity.unit_number] then
                -- Register the entity for the global object destroyed event
                script.register_on_object_destroyed(entity)
                -- Add the combinator to our high-performance update list using its unique ID
                storage.nexus_connected_combinators[entity.unit_number] = entity
            end
        else
            -- Remove it if the player cleared the custom signals
            storage.nexus_connected_combinators[entity.unit_number] = nil
        end
    end
end)

-- Event: Fires when any registered entity is destroyed, mined, or deleted
script.on_event(defines.events.on_object_destroyed, function(event)
    if storage.nexus_connected_combinators then
        -- Find the entity by its unit_number (stored in event.useful_id)
        local unit_number = event.useful_id
        if unit_number and storage.nexus_connected_combinators[unit_number] then
            -- Clean it up from our storage list immediately
            storage.nexus_connected_combinators[unit_number] = nil
        end
    end
end)




---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------




-- EVENT HANDLER FOR THE STABILIZER SLIDER
script.on_event(defines.events.on_gui_value_changed, function(event)
    local element = event.element
    if not (element and element.valid) then return end

    -- DEBUG 1: Zeigt im Chat an, welches GUI-Element Factorio gerade registriert hat
    --game.print("DEBUG 1: GUI Element geändert! Name: " .. tostring(element.name) .. " | Typ: " .. tostring(element.type))

    if element.name == "stabilizer_global_slider" and element.type == "slider" then
        local neue_stufe = math.floor(element.slider_value)
        
        storage.stabilizer_system = storage.stabilizer_system or {}
        local alte_stufe = storage.stabilizer_system.global_tier or 1

        -- DEBUG 2: Zeigt an, welche Stufen das Event berechnet hat
        --game.print("DEBUG 2: Slider bewegt! Alte Stufe: " .. alte_stufe .. " -> Neue Stufe: " .. neue_stufe)

        if neue_stufe ~= alte_stufe then
            storage.stabilizer_system.global_tier = neue_stufe
            storage.stabilizer_system.needs_morph = true
        end
    end
end)





---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------


--end --"MOD SETTING" MOD-ADDON ON/OFF "END"






else
    -- This section is executed when the setting from the mod is set to OFF
    script.on_event(defines.events.on_tick, function(event)
        -- clean up every 60 ticks
        for _, p in pairs(game.players) do
            if p.valid then
                if p.gui.top.nexus_frame then p.gui.top.nexus_frame.destroy() end
                if p.gui.top.nexus_toggle_button then p.gui.top.nexus_toggle_button.destroy() end
            end
        end
        -- disable the event handler for this game state.
        script.on_event(defines.events.on_tick, nil)
    end)
end -- MOD SETTING" MOD-ADDON ON/OFF "END"