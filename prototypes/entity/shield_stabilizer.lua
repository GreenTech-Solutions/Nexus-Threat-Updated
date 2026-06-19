-- shield_stabilizer.lua (Im Prototypen- / Data-Ordner deines Mods)

if settings.startup["nexus-threat-activation"].value then --"MOD SETTING" MOD-ADDON ON/OFF

local sounds = require("__base__.prototypes.entity.sounds")

-- 1. We define the base machine (Level 1 = 10%)
local base_stabilizer = {
    name = "shield-stabilizer-1", -- Internal name for Level 1
    type = "assembling-machine",
    icon = "__Nexus-Graphics__/graphics/items/shield-stabilizer.png",
    icon_size = 64,
    flags = {"placeable-neutral", "placeable-player", "player-creation"},
    place_result = "shield-stabilizer", -- When placed from the inventory, this item is placed
    minable = {mining_time = 0.8, result = "shield-stabilizer"}, -- Always returns the normal item when dismantled
    max_health = 10000,
    corpse = "assembling-machine-1-remnants",
    dying_explosion = "assembling-machine-1-explosion",
    collision_box = {{-4.9, -3.9}, {4.9, 3.9}},
    selection_box = {{-5.0, -4.0}, {5.0, 4.0}},

    circuit_wire_max_distance = assembling_machine_circuit_wire_max_distance,
    circuit_connector = circuit_connector_definitions["assembling-machine"],
	
    crafting_categories = {"nexus-stabilization"},
    
    -- STUFE 1 RATIO (10%):
    crafting_speed = 0.1,  -- 10% from 1.0 Speed
    energy_usage = "50GW", -- 10% from 500 GW
    
    energy_source = { type = "electric", usage_priority = "secondary-input" },
    
    graphics_set = {
        animation = {
            filename = "__Nexus-Graphics__/graphics/entity/shield-stabilizer-animation.png",
            width = 1024,
            height = 1024,
            line_length = 4,
            frame_count = 16,
            shift = util.by_pixel(0, 0),
            scale = 0.4,
            animation_speed = 0.4,
            run_mode = "backward",
            show_glow_when_working = true,
        },
        working_visualisations = {
            {
                light = { type = "basic", intensity = 1, size = 20 }
            }
        },
    },

    open_sound = sounds.machine_open,
    close_sound = sounds.machine_close,
    impact_category = "metal",
    working_sound = {
      sound = {filename = "__space-age__/sound/entity/fusion/fusion-reactor.ogg", volume = 1.2},
      apparent_volume = 0.5,
    }
}

-- Register Level 1
data:extend({base_stabilizer})

-- 2. We automatically clone levels 2 through 10 into RAM when the game starts
for i = 2, 10 do
    local stabilizer_tier = table.deepcopy(data.raw["assembling-machine"]["shield-stabilizer-1"])
    
    -- Generates exactly the names “shield-stabilizer-2” through “shield-stabilizer-10”
    stabilizer_tier.name = "shield-stabilizer-" .. i
    
    -- Scale the values up in a perfectly linear fashion, maintaining the same ratio!
    stabilizer_tier.crafting_speed = 0.1 * i 
    stabilizer_tier.energy_usage = (50 * i) .. "GW"
    
    stabilizer_tier.localised_name = {"entity-name.shield-stabilizer"} 
    stabilizer_tier.flags = {"placeable-neutral", "player-creation", "not-blueprintable"}
    
    stabilizer_tier.hidden = true
    
    stabilizer_tier.minable = {mining_time = 0.8, result = "shield-stabilizer"}
    
    data:extend({stabilizer_tier})
end


end --"MOD SETTING" MOD-ADDON ON/OFF "END"
