--data.lua


if settings.startup["nexus-threat-activation"].value then --"MOD SETTING" MOD-ADDON ON/OFF


--data.lua

require("prototypes.entity.shield_stabilizer")

-- Create sprite for button
data:extend({
  {
    type = "sprite",
    name = "nexus-button-sprite", -- Ein eindeutiger interner Name
    filename = "__Nexus-Graphics__/graphics/other/button-icon.png",
    width = 64,  -- Hier die echte Breite deines PNGs eintragen
    height = 64, -- Hier die echte Höhe deines PNGs eintragen
    flags = {"icon"}
  }
})

-- Create a custom category
data:extend({
  {
    type = "recipe-category",
    name = "nexus-stabilization"
  },
---------------------------------------------
  {
    type = "item-subgroup",
    name = "omega-threat",
    group = "nexus",
    order = "y"
  }
})

-- Create Your Own Item
data:extend({
  {
	name = "shield-stabilizer",
	type = "item",
	stack_size = 1,
	weight = 20*kg,
	icon = "__Nexus-Graphics__/graphics/items/shield-stabilizer.png",
	icon_size = 64,
	subgroup = "omega-threat",
	order = "y-a",
	place_result = "shield-stabilizer-1"
},
})

-- Recipe for shield stabilizer
data:extend({
  {
	name = "shield-stabilizer",
	type = "recipe",
	enabled = false,
	ingredients = {
		{type = "item", name = "electronic-circuit",amount = 600},
		{type = "item", name = "copper-cable",amount = 800},
		{type = "item", name = "tungsten-plate",amount = 1200},
		{type = "item", name = "supercapacitor",amount = 4200},
		{type = "item", name = "superconductor",amount = 800},
		{type = "item", name = "electric-engine-unit",amount = 400},
		{type = "item", name = "quantum-processor",amount = 1000},
	},
	surface_conditions =
    {
      {
        property = "pressure",
        min = 10000,
        max = 10000
      },
	  {
        property = "gravity",
        min = 180,
        max = 180
      },
      {
        property = "magnetic-field",
        min = 120,
		max = 120
      }
    },
	results = {
	{type = "item", name = "shield-stabilizer", amount = 1}
	},
	energy_required = 60.0,
--	localised_description = "-----------------",
	category = "crafting-with-fluid",
	subgroup = "omega-threat",
	order = "y-a",
	--always_show_made_in = true,
	allow_productivity = false,
	allow_quality = false,
},
})

-- Define a recipe without output
data:extend({
  {
    type = "recipe",
    name = "nexus-stabilization-process",
    category = "nexus-stabilization",
    icons = {
      {
        icon = "__base__/graphics/icons/signal/signal_blue.png",
        icon_size = 64,
        icon_mipmaps = 4
      }
    },
	surface_conditions =
    {
      {
        property = "pressure",
        min = 10000,
        max = 10000
      },
	  {
        property = "gravity",
        min = 180,
        max = 180
      },
      {
        property = "magnetic-field",
        min = 120,
		max = 120
      }
    },
    enabled = true,
    --ingredients = {
    --  {},
    --},
    energy_required = 2,
    results = {},
    always_show_made_in = true
  }
})

-- Define technology

data:extend({
  {
    type = "technology",
    name = "nexus-storm-prediction",
    icon = "__Nexus-Graphics__/graphics/tech/nexus-storm-prediction.png", 
    icon_size = 256,
    effects = {}, -- Does not unlock any recipes, as it is purely a "script unlock"
    prerequisites = {"omega-components"},
    unit = {
      count = 1000,
      ingredients = {
        {"omega-automation-science-pack", 1},
        {"omega-logistic-science-pack", 1},
        {"omega-military-science-pack", 1},
        {"omega-chemical-science-pack", 1},
        {"omega-production-science-pack", 1},
        {"omega-utility-science-pack", 1},
        {"omega-space-science-pack", 1},
        {"omega-metallurgic-science-pack", 1},
        {"omega-electromagnetic-science-pack", 1},
        {"omega-agricultural-science-pack", 1},
        {"omega-cryogenic-science-pack", 1},
		{"promethium-882-science-pack", 1},
      },
      time = 45
    },
    order = "g-b-e"
  }
})

--[[
-- Standard-Maschinen die Kategorie zuweisen
table.insert(data.raw["assembling-machine"]["assembling-machine-1"].crafting_categories, "nexus-stabilization")
table.insert(data.raw["assembling-machine"]["assembling-machine-2"].crafting_categories, "nexus-stabilization")
table.insert(data.raw["assembling-machine"]["assembling-machine-3"].crafting_categories, "nexus-stabilization")
--]]


-- tips and tricks GUI
-- Image not working: Still looking for the error
data:extend({
  {
    type = "tips-and-tricks-item",
    name = "tipp-instabilitaet-shild",
    category = "nexus-threat-kombinator-tipp",
    order = "b",
    indent = 0,
    -- Thumbnail
    small_example_image = "__Nexus-Graphics__/graphics/other/button-icon.png",
  }
})




---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------








---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

data:extend({
  -- Custom independent virtual signal named after the variable 'shield_energy'
  {
    type = "virtual-signal",
    name = "shield_energy",
    icon = "__Nexus-Graphics__/graphics/other/shield-signal.png",
    icon_size = 64,
    subgroup = "virtual-signal-letter",
    order = "a[custom]-a[shield]"
  },
  -- Custom independent virtual signal named after the variable 'nexus_charge'
  {
    type = "virtual-signal",
    name = "nexus_charge",
    icon = "__Nexus-Graphics__/graphics/other/instability-signal.png",
    icon_size = 64,
    subgroup = "virtual-signal-letter",
    order = "a[custom]-b[nexus]"
  }
})





---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------



end --"MOD SETTING" MOD-ADDON ON/OFF "END"
