-- Runs on top of the base config of factorio-mod-tools (lua/luacheckrc.lua), which sets std, the Factorio globals and
-- allow_defined_top: add to its tables here.
-- data-stage globals of __base__/prototypes/entity/ (circuit-connector-sprites.lua, entities.lua)
for _, name in ipairs({ "circuit_connector_definitions", "assembling_machine_circuit_wire_max_distance" }) do
  read_globals[#read_globals + 1] = name
end
-- Style of the upstream code, kept as it is so that the diff with upstream stays readable: whitespace (611-614),
-- unused arguments and loop variables (212, 213)
for _, code in ipairs({ "611", "612", "613", "614", "212", "213" }) do
  ignore[#ignore + 1] = code
end
