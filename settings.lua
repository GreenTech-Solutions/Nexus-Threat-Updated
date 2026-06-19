--settings.lua

data:extend({
  {
    type = "bool-setting",
    name = "nexus-threat-activation",-- MOD MAINSWITCH:
    setting_type = "startup", 		-- "startup", "runtime-global" oder "runtime-per-user"
    default_value = true,
    order = "a"
  },
  --[[
  {
    type = "bool-setting",
    name = "nt-show-chat-alerts",	-- CHANGE STORM ALERT IN CHAT ON/OFF:
    setting_type = "runtime-global",-- "startup", "runtime-global" oder "runtime-per-user"
    default_value = true,
    order = "a"
  },
  --]]
  {
    type = "int-setting",
    name = "nt-max-shield",			-- CHANGE MAXIMUM SHILD ENERGY:
    setting_type = "runtime-global",
    default_value = 10000,
    minimum_value = 100
  },
  {
    type = "double-setting",
    name = "nt-drill-rate",			-- CHANGE DRILL INCREASING INSTABILITY: 0.01 = 1 % alle 100 Sekunden pro Bohrer
    setting_type = "runtime-global",
    default_value = 0.00004,
    minimum_value = 0
  },
  {
    type = "double-setting",
    name = "nt-storm-chance",		-- CHANGE STORM CHANCE:
    setting_type = "runtime-global",
    default_value = 0.16,
    minimum_value = 0
  },
  {
    type = "double-setting",
    name = "nt-shield-regen",		-- CHANGE SHIELD REGENERATION AMOUNT:
    setting_type = "runtime-global",
    default_value = 0.75,
    minimum_value = 0
  },
  {
    type = "double-setting",
    name = "nt-shield-drain",		-- CHANGE DAMAGE TO THE SHIELD:
    setting_type = "runtime-global",
    default_value = 0.005,
    minimum_value = 0
  },
  {
    type = "int-setting",
    name = "nt-base-damage",		-- CHANGE DAMAGE FROM LIGHTNING:
    setting_type = "runtime-global",
    default_value = 80,
    minimum_value = 0
  },
  {
    type = "double-setting",
    name = "nt-damage-inc",			-- CHANGE INCREASED DAMAGE DUE TO INSTABILITY:
    setting_type = "runtime-global",
    default_value = 1.0,
    minimum_value = 0
  },
  {
    type = "int-setting",
    name = "nt-storm-dur-base",		-- CHANGE STORM DURATION BASE:
    setting_type = "runtime-global",
    default_value = 90,--15
    minimum_value = 1
  },
  {
    type = "double-setting",
    name = "nt-storm-dur-mult",		-- CHANGE STORM DURATION MULTIPLIER:
    setting_type = "runtime-global",
    default_value = 1.0,--2.5
    minimum_value = 0
  },
  {
    type = "double-setting",
    name = "nt-recipe-bonus",		-- CHANGE SHIELD LOADING SPEED: 10.0 = 10 Schild-Energie pro Sekunde
    setting_type = "runtime-global",
    default_value = 10.0,
    minimum_value = 0
  },
  {
    type = "int-setting",
    name = "nt-drill-interval",		-- PERFORMANCE: CALCULATE DRILLS EVERY X TICKS (1-60)
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 60
  } 
})
