if reframework:get_game_name() ~= "re4" then
    return
end

local cfg = {
    smooth_turn_speed = 0.04,
}

local cfg_path = "re4_vr/re4_vr_hmd_aim_movement_config.json"

local function load_cfg()
    local loaded_cfg = json.load_file(cfg_path)

    if loaded_cfg == nil then
        json.dump_file(cfg_path, cfg)
        return
    end

    for k, v in pairs(loaded_cfg) do
        cfg[k] = v
    end
end

load_cfg()

re.on_config_save(function()
    json.dump_file(cfg_path, cfg)
end)

local gamepad_singleton_t = sdk.find_type_definition("via.hid.GamePad")

local function get_right_input_axis()
    if vrmod:is_using_controllers() then
        local axis = vrmod:get_right_stick_axis()
        return axis
    end

    local gamepad_singleton = sdk.get_native_singleton("via.hid.GamePad")
    if not gamepad_singleton then return Vector2f.new(0, 0) end

    local pad = sdk.call_native_func(gamepad_singleton, gamepad_singleton_t, "get_LastInputDevice")
    if not pad then return Vector2f.new(0, 0) end

    return pad:get_AxisR()
end

local turn_yaw_radians = 0
sdk.hook(
    sdk.find_type_definition("chainsaw.TwirlerCameraControllerRoot"):get_method("setYaw"),
    function(args)
        if not vrmod:is_hmd_active() then
            return
        end
        local quat = vrmod:get_rotation(0):to_quat()
        local forward = quat * Vector3f.new(0, 0, 1)
        local yaw_radians = math.atan(forward.x, forward.z)

        vrmod:recenter_view()

        local right_stick_axis = get_right_input_axis()
        local x_axis = right_stick_axis.x
        turn_yaw_radians = turn_yaw_radians - x_axis * cfg.smooth_turn_speed

        args[3] = sdk.float_to_ptr(yaw_radians + turn_yaw_radians)

        local origin = Vector3f.new(0.15,  - 0.02, 0.33)
        vrmod:set_standing_origin(origin)
    end,
    function(retval)
        return retval
    end
)

sdk.hook(
    sdk.find_type_definition("chainsaw.TwirlerCameraControllerRoot"):get_method("setPitch"),
    function(args)
        if not vrmod:is_hmd_active() then
            return
        end
        local quat = vrmod:get_rotation(0):to_quat()
        local forward = quat * Vector3f.new(0, 0, 1)
        local pitch_radians = math.atan(forward.y, math.sqrt(forward.x * forward.x + forward.z * forward.z))

        vrmod:recenter_view()

        args[3] = sdk.float_to_ptr(-pitch_radians)        
    end,
    function(retval)
        return retval
    end
)

sdk.hook(
    sdk.find_type_definition("chainsaw.CameraPositionParam"):get_method("getGazeDistance"),
    function(args)
    end,
    function(retval)
        return sdk.float_to_ptr(0.0)
    end
)