# -*- coding: utf-8 -*-
"""Generate five-element mage skill trees for skill_catalog.gd."""
from __future__ import annotations

import re
from pathlib import Path

CATALOG = Path(__file__).resolve().parents[1] / "scripts/skills/skill_catalog.gd"
OUT = Path(__file__).resolve().parent / "_mage_defs_snippet.txt"

ELEMENTS = {
    "fire": {
        "family": "FAMILY_MAGE_FIRE",
        "prefix": "mgf",
        "element": "fire",
        "status": "burn",
        "colors": {
            "trail": "Color(1.0, 0.42, 0.18, 1.0)",
            "flash": "Color(1.0, 0.58, 0.28, 0.46)",
        },
        "skills": [
            ("ember", 0, 0, "passive", {}, {"burn_dps": 2.0, "burn_dps_per": 1.0, "burn_time": 2.2, "light_dmg": 0.06, "light_dmg_per": 0.04}),
            ("blink", 2, 0, "active", {"style": "mage_blink", "zone": True, "damage": 10.0, "wave_radius": 28.0}, {}),
            ("bolt", 0, 1, "active", {"style": "mage_bolt", "damage": 12.0, "pierce": 1, "proj_speed": 320.0}, {"prereq": "ember"}),
            ("nova", 1, 1, "active", {"style": "mage_nova", "damage": 22.0, "wave_radius": 48.0, "loud": True}, {"prereq": "blink"}),
            ("focus", 2, 1, "passive", {}, {"mind_cut": 0.04, "mind_regen": 0.15, "prereq": "blink"}),
            ("lash", 0, 2, "active", {"style": "mage_beam", "damage": 14.0, "beam_len": 110.0}, {"prereq": "bolt", "level": 10}),
            ("ring", 1, 2, "active", {"style": "mage_orbit", "damage": 8.0, "ticks": 4, "orbit_radius": 52.0}, {"prereq": "nova", "level": 10}),
            ("ward", 2, 2, "passive", {}, {"dr_pct": 0.04, "reflect_burn": 1.5, "prereq": "focus", "level": 10}),
            ("cascade", 0, 3, "active", {"style": "mage_rain", "damage": 10.0, "rain_count": 5, "range": 140.0}, {"prereq": "lash", "level": 15}),
            ("meteor", 1, 3, "active", {"style": "mage_meteor", "damage": 38.0, "wave_radius": 68.0, "fuse": 0.35, "loud": True}, {"prereq": "ring", "level": 15}),
            ("cataclysm", 2, 3, "active", {"style": "mage_field", "damage": 6.0, "wave_radius": 72.0, "field_dur": 4.0, "loud": True}, {"prereq": "ward", "level": 15}),
        ],
    },
    "ice": {
        "family": "FAMILY_MAGE_ICE",
        "prefix": "mgi",
        "element": "ice",
        "status": "chill",
        "colors": {
            "trail": "Color(0.55, 0.85, 1.0, 1.0)",
            "flash": "Color(0.7, 0.92, 1.0, 0.42)",
        },
        "skills": [
            ("frostmark", 0, 0, "passive", {}, {"chill_slow": 0.22, "chill_slow_per": 0.04, "chill_time": 2.4}),
            ("froststep", 2, 0, "active", {"style": "mage_blink", "zone": True, "damage": 9.0, "wave_radius": 28.0}, {}),
            ("shard", 0, 1, "active", {"style": "mage_bolt", "damage": 11.0, "proj_speed": 280.0}, {"prereq": "frostmark"}),
            ("rime", 1, 1, "active", {"style": "mage_nova", "damage": 10.0, "wave_radius": 56.0, "chill_stacks": 2}, {"prereq": "frostmark"}),
            ("permafrost", 2, 1, "passive", {}, {"chill_time_bonus": 0.4, "freeze_at_cut": 1, "prereq": "froststep"}),
            ("wall", 0, 2, "active", {"style": "mage_wall", "damage": 8.0, "wall_len": 72.0}, {"prereq": "shard", "level": 10}),
            ("pulse", 1, 2, "active", {"style": "mage_pulse", "damage": 18.0, "wave_radius": 64.0}, {"prereq": "rime", "level": 10}),
            ("frostarmor", 2, 2, "passive", {}, {"shield_on_chill_hit": 6.0, "prereq": "permafrost", "level": 10}),
            ("rain", 0, 3, "active", {"style": "mage_rain", "damage": 9.0, "rain_count": 6, "range": 130.0}, {"prereq": "wall", "level": 15}),
            ("field", 1, 3, "active", {"style": "mage_field", "damage": 5.0, "wave_radius": 64.0, "field_dur": 3.0}, {"prereq": "pulse", "level": 15}),
            ("shatter", 2, 3, "active", {"style": "mage_shatter", "damage": 32.0, "wave_radius": 48.0}, {"prereq": "frostarmor", "level": 15}),
        ],
    },
    "acid": {
        "family": "FAMILY_MAGE_ACID",
        "prefix": "mga",
        "element": "acid",
        "status": "corrode",
        "colors": {
            "trail": "Color(0.55, 0.92, 0.22, 1.0)",
            "flash": "Color(0.7, 1.0, 0.3, 0.4)",
        },
        "skills": [
            ("stain", 0, 0, "passive", {}, {"corrode_amp": 0.12, "corrode_amp_per": 0.03, "corrode_time": 3.5, "pdef_cut": 2.0}),
            ("acidflash", 2, 0, "active", {"style": "mage_blink", "zone": True, "damage": 9.0, "wave_radius": 28.0}, {}),
            ("spit", 0, 1, "active", {"style": "mage_bolt", "damage": 11.0, "proj_speed": 300.0}, {"prereq": "stain"}),
            ("cloud", 1, 1, "active", {"style": "mage_cloud", "damage": 7.0, "wave_radius": 64.0, "field_dur": 3.0}, {"prereq": "stain"}),
            ("dissolve", 2, 1, "passive", {}, {"pdef_cut_per": 0.8, "corrode_amp_per": 0.04, "prereq": "acidflash"}),
            ("etch", 0, 2, "active", {"style": "mage_beam", "damage": 13.0, "beam_len": 100.0}, {"prereq": "spit", "level": 10}),
            ("corrodering", 1, 2, "active", {"style": "mage_orbit", "damage": 7.0, "ticks": 4, "orbit_radius": 48.0}, {"prereq": "cloud", "level": 10}),
            ("resist", 2, 2, "passive", {}, {"corrode_dmg_bonus": 0.08, "prereq": "dissolve", "level": 10}),
            ("rain", 0, 3, "active", {"style": "mage_rain", "damage": 9.0, "rain_count": 5, "range": 120.0}, {"prereq": "etch", "level": 15}),
            ("field", 1, 3, "active", {"style": "mage_field", "damage": 5.0, "wave_radius": 76.0, "field_dur": 4.0}, {"prereq": "corrodering", "level": 15}),
            ("shatter", 2, 3, "active", {"style": "mage_shatter", "damage": 28.0, "wave_radius": 44.0}, {"prereq": "resist", "level": 15}),
        ],
    },
    "dark": {
        "family": "FAMILY_MAGE_DARK",
        "prefix": "mgd",
        "element": "dark",
        "status": "weaken",
        "colors": {
            "trail": "Color(0.45, 0.18, 0.72, 1.0)",
            "flash": "Color(0.35, 0.12, 0.55, 0.7)",
        },
        "skills": [
            ("shadowbite", 0, 0, "passive", {}, {"weaken_cut": 0.12, "weaken_cut_per": 0.03, "weaken_time": 4.0}),
            ("shadowstep", 2, 0, "active", {"style": "mage_blink", "zone": True, "damage": 9.0, "wave_radius": 28.0}, {}),
            ("bolt", 0, 1, "active", {"style": "mage_bolt", "damage": 11.0, "pierce": 2, "proj_speed": 340.0}, {"prereq": "shadowbite"}),
            ("vortex", 1, 1, "active", {"style": "mage_vortex", "damage": 8.0, "wave_radius": 56.0, "field_dur": 1.5}, {"prereq": "shadowbite"}),
            ("darken", 2, 1, "passive", {}, {"weaken_cut_per": 0.04, "prereq": "shadowstep"}),
            ("chain", 0, 2, "active", {"style": "mage_chain", "damage": 10.0, "chain_count": 3}, {"prereq": "bolt", "level": 10}),
            ("orbit", 1, 2, "active", {"style": "mage_orbit", "damage": 7.0, "ticks": 4, "orbit_radius": 50.0, "lifesteal": 0.05}, {"prereq": "vortex", "level": 10}),
            ("shadow", 2, 2, "passive", {}, {"low_hp_ms": 0.06, "lifesteal": 0.04, "prereq": "darken", "level": 10}),
            ("rain", 0, 3, "active", {"style": "mage_rain", "damage": 9.0, "rain_count": 5, "range": 130.0}, {"prereq": "chain", "level": 15}),
            ("field", 1, 3, "active", {"style": "mage_field", "damage": 5.0, "wave_radius": 68.0, "field_dur": 3.5, "lifesteal": 0.08}, {"prereq": "orbit", "level": 15}),
            ("drain", 2, 3, "active", {"style": "mage_drain", "damage": 34.0, "wave_radius": 40.0, "lifesteal": 0.25}, {"prereq": "shadow", "level": 15}),
        ],
    },
    "light": {
        "family": "FAMILY_MAGE_LIGHT",
        "prefix": "mgl",
        "element": "light",
        "status": "bless",
        "colors": {
            "trail": "Color(1.0, 0.92, 0.55, 1.0)",
            "flash": "Color(1.0, 0.96, 0.7, 0.65)",
        },
        "skills": [
            ("grace", 0, 0, "passive", {}, {"bless_hps": 1.5, "bless_hps_per": 0.5, "bless_shield": 6.0, "bless_time": 3.0}),
            ("lightstep", 2, 0, "active", {"style": "mage_blink", "self_cast": True, "damage": 0.0, "wave_radius": 32.0}, {}),
            ("ray", 0, 1, "active", {"style": "mage_bolt", "self_cast": True, "damage": 10.0, "proj_speed": 360.0}, {"prereq": "grace"}),
            ("aegis", 1, 1, "active", {"style": "mage_nova", "self_cast": True, "damage": 0.0, "wave_radius": 48.0}, {"prereq": "grace"}),
            ("faith", 2, 1, "passive", {}, {"bless_time_bonus": 1.0, "bless_shield_per": 2.0, "prereq": "lightstep"}),
            ("dome", 0, 2, "active", {"style": "mage_dome", "self_cast": True, "damage": 0.0, "dr_pct": 0.2, "field_dur": 3.0}, {"prereq": "ray", "level": 10}),
            ("smite", 1, 2, "active", {"style": "mage_beam", "damage": 16.0, "beam_len": 120.0, "elite_bonus": 0.5}, {"prereq": "aegis", "level": 10}),
            ("holyshield", 2, 2, "passive", {}, {"reflect_on_break": 8.0, "prereq": "faith", "level": 10}),
            ("rain", 0, 3, "active", {"style": "mage_rain", "self_cast": True, "damage": 8.0, "rain_count": 5, "range": 120.0}, {"prereq": "dome", "level": 15}),
            ("field", 1, 3, "active", {"style": "mage_field", "self_cast": True, "damage": 0.0, "wave_radius": 60.0, "field_dur": 4.0}, {"prereq": "smite", "level": 15}),
            ("purge", 2, 3, "active", {"style": "mage_purge", "damage": 24.0, "wave_radius": 56.0, "elite_bonus": 0.5}, {"prereq": "holyshield", "level": 15}),
        ],
    },
}

STATUS_COMBAT = {
    "burn": '"burn_dps": 3.0, "burn_time": 2.2, "status": "burn"',
    "chill": '"chill_slow": 0.28, "chill_time": 2.0, "chill_stacks": 1, "status": "chill"',
    "corrode": '"corrode_amp": 0.15, "corrode_time": 3.0, "pdef_cut": 3.0, "status": "corrode"',
    "weaken": '"weaken_cut": 0.18, "weaken_time": 4.0, "status": "weaken"',
    "bless": '"bless_shield": 10.0, "bless_hps": 2.0, "bless_time": 3.0, "status": "bless"',
}


def emit_skill(prefix: str, family: str, element: str, name: str, col: int, row: int, kind: str, combat: dict, extra: dict, colors: dict) -> str:
    sid = f"{prefix}_{name}"
    name_key = f"{prefix}.{name}"
    icon = f"res://assets/ui/icons/skills/{element}_{name}.png"
    if element == "fire":
        icon = f"res://assets/ui/icons/skills/flame_{name}.png"
    if name == "froststep":
        icon = "res://assets/ui/icons/skills/ice_froststep.png"
    if name == "acidflash":
        icon = "res://assets/ui/icons/skills/acid_flash.png"
    level = extra.get("level", 1 if row == 0 else 5 if row == 1 else 10 if row == 2 else 15)
    prereq_name = extra.get("prereq")
    prereq = "{}"
    if prereq_name:
        prereq = f'{{"{prefix}_{prereq_name}": 1}}'
    if row == 0:
        learn_cost = "[0, 1, 2, 2, 3]"
        cast_cost_active = "[10, 11, 12, 13, 14]"
        cooldown_active = "[2.4, 2.3, 2.2, 2.1, 2.0]"
    elif row == 1:
        learn_cost = "[2, 3, 3, 4, 5]"
        cast_cost_active = "[16, 17, 18, 20, 22]"
        cooldown_active = "[2.0, 1.9, 1.8, 1.7, 1.55]"
    else:
        learn_cost = "[3, 4, 5, 6, 8]"
        cast_cost_active = "[14, 15, 16, 18, 20]"
        cooldown_active = "[3.6, 3.4, 3.2, 3.0, 2.8]"
    lines = [
        f'\t"{sid}": {{',
        f'\t\t"family": {family},',
        f'\t\t"name_key": "{name_key}",',
        f'\t\t"icon": "{icon}",',
        f'\t\t"kind": "{kind}",',
        f'\t\t"col": {col},',
        f'\t\t"row": {row},',
        f'\t\t"level_req": {level},',
        f'\t\t"max_rank": 5,',
        f'\t\t"prereq": {prereq},',
        f'\t\t"learn_cost": {learn_cost},',
        f'\t\t"cast_cost": 0,' if kind == "passive" else f'\t\t"cast_cost": {cast_cost_active},',
        f'\t\t"cooldown": 0.0,' if kind == "passive" else f'\t\t"cooldown": {cooldown_active},',
    ]
    if kind == "active":
        lines.append(f'\t\t"range": [88.0, 92.0, 96.0, 100.0, 108.0],')
        lines.append(f'\t\t"loud": {str(combat.get("loud", False)).lower()},')
        lines.append('\t\t"combat": {')
        lines.append(f'\t\t\t"style": "{combat.get("style", "mage_bolt")}",')
        lines.append(f'\t\t\t"element": "{element}",')
        if combat.get("self_cast"):
            lines.append('\t\t\t"self_cast": true,')
        lines.append('\t\t\t"windup": 0.08,')
        lines.append('\t\t\t"active": 0.14,')
        lines.append('\t\t\t"recovery": 0.18,')
        dmg = combat.get("damage", 10.0)
        lines.append(f'\t\t\t"damage": {dmg},')
        lines.append(f'\t\t\t"damage_per_rank": {max(1.5, dmg * 0.18):.1f},')
        if combat.get("style") != "mage_blink" or not combat.get("self_cast"):
            lines.append('\t\t\t"knockback": 80.0,')
            lines.append('\t\t\t"poise": 8.0,')
        if combat.get("zone"):
            lines.append('\t\t\t"spawn_zone": true,')
            lines.append('\t\t\t"zone_dur": 3.0,')
        for k in ["wave_radius", "wave_radius_per_rank", "pierce", "proj_speed", "beam_len", "ticks", "orbit_radius", "rain_count", "range", "fuse", "field_dur", "wall_len", "chain_count", "lifesteal", "dr_pct", "elite_bonus", "chill_stacks"]:
            if k in combat:
                lines.append(f'\t\t\t"{k}": {combat[k]},')
        st = {"fire": "burn", "ice": "chill", "acid": "corrode", "dark": "weaken", "light": "bless"}[element]
        if kind == "active" and (dmg > 0 or st == "bless"):
            existing_keys = set(combat.keys())
            for part in STATUS_COMBAT[st].split(", "):
                key = part.split(":")[0].strip().strip('"')
                if key in existing_keys:
                    continue
                lines.append(f'\t\t\t{part},')
        lines.append('\t\t},')
        lines.append('\t\t"fx": {')
        lines.append(f'\t\t\t"id": "{element}_{name}",')
        lines.append(f'\t\t\t"trail_color": {colors["trail"]},')
        lines.append(f'\t\t\t"flash_color": {colors["flash"]},')
        lines.append('\t\t\t"trail_width": 5.0,')
        lines.append('\t\t\t"flash_radius": 28.0,')
        lines.append('\t\t},')
    else:
        lines.append('\t\t"loud": false,')
        lines.append('\t\t"passive": {')
        passive_keys = [k for k in extra if k not in ("prereq", "level")]
        for k in passive_keys:
            v = extra[k]
            if isinstance(v, float):
                lines.append(f'\t\t\t"{k}": {v},')
            else:
                lines.append(f'\t\t\t"{k}": {v},')
        lines.append('\t\t},')
    lines.append('\t},')
    return "\n".join(lines)


def main() -> None:
    parts = []
    for elem, cfg in ELEMENTS.items():
        for name, col, row, kind, combat, extra in cfg["skills"]:
            parts.append(emit_skill(cfg["prefix"], cfg["family"], cfg["element"], name, col, row, kind, combat, extra, cfg["colors"]))
    snippet = "\n".join(parts)
    OUT.write_text(snippet, encoding="utf-8")
    text = CATALOG.read_text(encoding="utf-8")
    start = text.index('\t"mgf_ember":')
    end = text.index("\n}\n\n\nstatic func def")
    new_text = text[:start] + snippet + text[end:]
    CATALOG.write_text(new_text, encoding="utf-8")
    print(f"Wrote {len(cfg['skills']) if False else 55} skills to catalog")


if __name__ == "__main__":
    main()
