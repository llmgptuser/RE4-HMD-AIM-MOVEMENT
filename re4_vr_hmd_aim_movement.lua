if reframework:get_game_name() ~= "re4" then
    return
end

local cfg = {
    gaze_distance = 0.0,
    snap_turn_enabled = true,
    snap_turn_back_enabled = true,
    snap_turn_angle = 45.0,
    recenter_threshold = 0.4,
    tilt_threshold = 0.8,
    smooth_turn_speed = 3.0,
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

local function math_sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
end

local is_stick_centered = true
local is_stick_centered_y = true
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
        local y_axis = right_stick_axis.y
        if cfg.snap_turn_enabled then
            if is_stick_centered then
                if math.abs(x_axis) > cfg.tilt_threshold then
                    is_stick_centered = false
                    snap_turn_sign = math_sign(x_axis)
                    turn_yaw_radians = turn_yaw_radians - math.rad(snap_turn_sign * cfg.snap_turn_angle)
                end
            elseif math.abs(x_axis) < cfg.recenter_threshold then
                is_stick_centered = true
            end
            if cfg.snap_turn_back_enabled and is_stick_centered then
                if is_stick_centered_y then
                    if y_axis < -cfg.tilt_threshold then
                        is_stick_centered_y = false
                        turn_yaw_radians = turn_yaw_radians + math.rad(180.0)
                    end
                elseif math.abs(y_axis) < cfg.recenter_threshold then
                    is_stick_centered_y = true
                end
            end
        else
            turn_yaw_radians = turn_yaw_radians - x_axis * math.rad(cfg.smooth_turn_speed)
        end

        args[3] = sdk.float_to_ptr(yaw_radians + turn_yaw_radians)
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
        return sdk.float_to_ptr(cfg.gaze_distance)
    end
)

re.on_draw_ui(function()
    local changed = false
    if imgui.tree_node("HMD Aim and Enhanced Movement") then
        changed, cfg.gaze_distance = imgui.drag_float("Camera Orbiting Distance", cfg.gaze_distance, 0.1, 0.0, 1.5)
        changed, cfg.snap_turn_enabled = imgui.checkbox("Snap Turn Enabled", cfg.snap_turn_enabled)
        if cfg.snap_turn_enabled then
            changed, cfg.snap_turn_angle = imgui.drag_float("Snap Turn Angle", cfg.snap_turn_angle, 15.0, 15.0, 90.0)
            changed, cfg.tilt_threshold = imgui.drag_float("Snap Turn Tilt Threshold", cfg.tilt_threshold, 0.05, 0.1, 1.0)
            changed, cfg.recenter_threshold = imgui.drag_float("Snap Turn Recenter Threshold", cfg.recenter_threshold, 0.05, 0.1, 1.0)
            changed, cfg.snap_turn_back_enabled = imgui.checkbox("Tild Down to Turn Back Enabled", cfg.snap_turn_back_enabled)
        else
            changed, cfg.smooth_turn_speed = imgui.drag_float("Smooth Turn Speed", cfg.smooth_turn_speed, 1.0, 1.0, 50.0)
        end
        imgui.tree_pop()
    end
end)
