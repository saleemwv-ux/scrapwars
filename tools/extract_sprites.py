"""Cuts Scrapfall concept-art sheets into transparent game sprites.

Usage:
    python3 -m pip install "rembg[cpu]" scipy pillow numpy
    python3 tools/extract_sprites.py            # every sprite
    python3 tools/extract_sprites.py rivet_warden hex_nova   # just these

The sheets go in tools/concept_sheets/ (not committed, they're large).
Each entry below names a sheet and a box (left, top, right, bottom) in the
sheet's 1448x1086 pixel space. The background is removed with an AI cut-out
model, stray bits of neighbouring characters are dropped, and the result is
trimmed and saved to art/sprites/<name>.png.
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image
from rembg import new_session, remove
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
SHEETS = ROOT / "tools" / "concept_sheets"
OUT = ROOT / "art" / "sprites"
MAX_SIZE = 320

# name: (sheet, box, options)
# options: "erase" = boxes painted over with background first (titles),
#          "flip" = mirror so the sprite faces right,
#          "keep_all" = don't drop off-centre pieces (smoke, particles),
#          "key" = also keep anything coloured or dark that the AI model
#                  dropped (stone, glow, see-through wings).
SPRITES = {
    # --- Scrappers -----------------------------------------------------------
    "rivet_warden": ("tanks", (300, 195, 590, 527), {}),
    "scrap_colossus": ("tanks", (5, 195, 302, 527), {}),
    "iron_rammer": ("tanks", (1158, 605, 1448, 992), {}),
    "signal_sniper": ("ranged_support", (300, 205, 590, 502), {}),
    "coil_mechanic": ("ranged_support", (5, 205, 300, 502), {}),
    "turret_tinker": ("ranged_support", (872, 205, 1150, 502), {}),
    "scrap_drone": ("scrap_drone", (170, 320, 1310, 880), {"keep_all": True}),
    "rocket_rider": ("air_assault", (5, 205, 300, 527), {"keep_all": True}),
    "boom_buggy": ("boom_car", (30, 330, 1210, 880), {"keep_all": True}),
    "rocket_barrage": ("scrapper_spells", (495, 320, 955, 905), {"keep_all": True}),
    "scrap_watchtower": ("towers", (0, 300, 292, 875), {}),
    "rocket_nest": ("towers", (272, 365, 532, 875), {}),
    "scrap_rocket": ("scrapper_throwables", (10, 365, 610, 835), {}),
    # --- Infected ------------------------------------------------------------
    "serum_mauler": ("tanks", (5, 605, 305, 992), {}),
    "hazmat_juggernaut": ("tanks", (875, 195, 1156, 527), {}),
    "mutation_marksman": ("ranged_support", (1150, 205, 1448, 502), {}),
    "smog_caster": ("ranged_support", (300, 600, 587, 977), {"keep_all": True}),
    "plague_glider": ("air_assault", (1153, 205, 1448, 527), {}),
    "fat_dragon": ("fat_dragon", (0, 170, 1448, 910), {"erase": [(380, 0, 1090, 322)], "keep_all": True, "key": True}),
    "chem_turret": ("infected_strike_team", (1150, 430, 1448, 895), {}),
    "blight_cloud": ("infected_spells", (435, 365, 1065, 905), {"keep_all": True}),
    "toxic_sprayer": ("towers", (488, 325, 748, 875), {"keep_all": True}),
    "hive_mother": ("infected_faction", (1072, 268, 1448, 678), {"erase": [(1060, 260, 1122, 700)], "key": True}),
    "blight_rocket": ("infected_throwables", (0, 345, 565, 885), {}),
    # --- Dead Crown ----------------------------------------------------------
    "crown_bastion": ("tanks", (305, 605, 590, 992), {}),
    "bone_paladin": ("tanks", (875, 605, 1158, 992), {}),
    "hex_archer": ("ranged_support", (587, 600, 872, 977), {}),
    "soul_seer": ("ranged_support", (872, 600, 1150, 977), {}),
    "soul_harrier": ("air_assault", (322, 605, 587, 967), {"key": True}),
    "bone_dragon": ("bone_dragon", (30, 290, 1420, 905), {"erase": [(420, 0, 1010, 325)], "keep_all": True, "key": True}),
    "obelisk_priest": ("dc_arcane_air", (1175, 300, 1448, 895), {"key": True}),
    "hex_nova": ("dc_spells", (495, 320, 1015, 865), {"keep_all": True, "key": True}),
    "gargoyle_roost": ("towers", (965, 345, 1228, 875), {"key": True}),
    "soul_obelisk": ("towers", (750, 318, 985, 875), {"key": True}),
    "hex_orb": ("dc_throwables", (25, 320, 525, 855), {"keep_all": True}),
}

_session = None


def _cutout(img: Image.Image) -> Image.Image:
    global _session
    if _session is None:
        _session = new_session("isnet-general-use")
    return remove(img, session=_session)


def _colour_key(img: Image.Image, model: np.ndarray) -> np.ndarray:
    """Adds back anything clearly not backdrop that the AI model dropped.

    The backdrop is a bright, nearly grey studio wall, so colourful or dark
    pixels are kept. Soft edges have the wall colour un-mixed out of them.
    """
    c = np.asarray(img, dtype=np.float64)
    h, w, _ = c.shape
    edge = np.concatenate([c[:4].reshape(-1, 3), c[-4:].reshape(-1, 3),
                           c[:, :4].reshape(-1, 3), c[:, -4:].reshape(-1, 3)])
    wall = np.median(edge, axis=0)
    chroma = c.max(axis=-1) - c.min(axis=-1)
    lum = c @ np.array([0.299, 0.587, 0.114])
    score = np.maximum(chroma * 1.3, wall.mean() - 18.0 - lum)
    key = np.clip((score - 22.0) / 30.0, 0.0, 1.0)
    alpha = np.maximum(model[..., 3] / 255.0, key)
    a = np.maximum(alpha, 0.05)[..., None]
    rgb = np.where(alpha[..., None] < 0.98, (c - (1.0 - a) * wall) / a, c)
    out = np.concatenate([np.clip(rgb, 0, 255), alpha[..., None] * 255.0], axis=-1)
    return out.astype(np.uint8)


def _drop_strays(rgba: np.ndarray, keep_all: bool) -> np.ndarray:
    """Clears pieces that belong to neighbouring characters on the sheet."""
    alpha = rgba[..., 3]
    solid = alpha > 96
    labels, n = ndimage.label(solid)
    if n <= 1:
        return rgba
    sizes = ndimage.sum(solid, labels, range(1, n + 1))
    biggest = sizes.max()
    centres = ndimage.center_of_mass(solid, labels, range(1, n + 1))
    w = rgba.shape[1]
    keep = np.zeros(n + 1, bool)
    for i, (size, (_, cx)) in enumerate(zip(sizes, centres), start=1):
        if size == biggest:
            keep[i] = True
        elif keep_all:
            keep[i] = size >= 12
        else:
            keep[i] = size >= biggest * 0.004 and 0.12 * w < cx < 0.88 * w
    kept = keep[labels]
    # Soft edge pixels next to a kept piece survive too.
    near = ndimage.binary_dilation(kept, iterations=3)
    out = rgba.copy()
    out[..., 3] = np.where(near, alpha, 0)
    return out


def extract(name: str) -> None:
    sheet, box, opts = SPRITES[name]
    img = Image.open(SHEETS / f"{sheet}.png").convert("RGB")
    for erase in opts.get("erase", []):
        # Paint the title banner with the sheet's background colour.
        bg = img.getpixel((5, 5))
        img.paste(bg, erase)
    crop = img.crop(box)
    cut = np.array(_cutout(crop))
    if opts.get("key"):
        cut = _colour_key(crop, cut)
    cut = _drop_strays(cut, opts.get("keep_all", False))
    cut[..., 3] = np.where(cut[..., 3] < 10, 0, cut[..., 3])
    out = Image.fromarray(cut)
    bbox = out.getbbox()
    if bbox:
        out = out.crop(bbox)
    if opts.get("flip"):
        out = out.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    out.thumbnail((MAX_SIZE, MAX_SIZE), Image.Resampling.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    out.save(OUT / f"{name}.png", optimize=True)
    print(f"{name}: {out.size[0]}x{out.size[1]}")


def main() -> None:
    names = sys.argv[1:] or list(SPRITES)
    for name in names:
        extract(name)


if __name__ == "__main__":
    main()
