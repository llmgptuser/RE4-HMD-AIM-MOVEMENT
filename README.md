Head Aim + Snap/Smooth/Physical turn based on Resident Evil 4 REFramework VR mod

Features:
- Can turn either by Snap/Smooth turn or by Physical turn (to some extent).
- Head Aim for aiming.
- Use a gamepad for controls

Installation:
- Install Praydog's Reframework VR mod
  - Either the latest version from https://github.com/praydog/REFramework or
  - (Recommended) the latest upscaler version from https://github.com/praydog/REFramework/actions?query=branch%3Aupscaler-v2-merge or from Nexus mods.
    - Ensure VR_RenderingTechnique_V2=1 in re2_fw_config.txt before launching (equivalent to setting "Rendering Technique" to "Two Frame Sequential" under "VR" of REFramework in-game menu).
- Place re4_vr_hmd_aim_movement.lua under reframework\autorun under your RE4 game dir.
- Adjust settings in "HMD Aim and Enhanced Movement" under "Script Generated UI".
  - "Camera Orbiting Distance" can be cycled through by tilting up the right stick.
  - Smooth turning speed is adjustable under Script Generated UI not game's settings.

In game settings:
- Disable Aim Assist

Note:
This mod is based on Praydog's REFramework and requires it to work, including the original re4_vr_crosshair.lua script. A clean install is recommended. Additional VR mods might not be compatible with this mod.
