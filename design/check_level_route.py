"""Validate the full expedition design and blockout data with Python's standard library."""
from collections import deque
from functools import lru_cache
from hashlib import blake2b
from math import ceil, dist
from pathlib import Path
import json
import random

ROUTE = json.loads(Path(__file__).with_name("LEVEL_ROUTE.json").read_text(encoding="utf-8-sig"))
ZONES = ROUTE["zones"]
ROOMS = [room for zone in ZONES for room in zone["rooms"]] + [ROUTE["final"]]


def graph():
    edges = {"start": [("01", None)]}
    for index, zone in enumerate(ZONES, 1):
        teach, develop, test, boss = [room["id"] for room in zone["rooms"]]
        vestibule, archive = f"rest-{index}", f"archive-{index}"
        hub, organ, socket = f"hub-{index}", f"organ-{index}", f"socket-{index}"
        next_room = ZONES[index]["rooms"][0]["id"] if index < len(ZONES) else "rest-final"
        edges.update({
            teach: [(develop, None)],
            develop: [(test, None)],
            test: [(vestibule, None), (archive, None)],
            archive: [(test, None)],
            vestibule: [(boss, None), (test, None)],
            boss: [(hub, organ)],
            hub: [(next_room, socket)],
        })
    edges["rest-final"] = [("29", "all-sockets"), ("hub-7", None)]
    edges["29"] = [("terminal", None)]
    edges["10"].append(("maintenance-lift", "previous-clear"))
    edges["maintenance-lift"] = [("10", None), ("early-terminal", None)]
    grants = {zone["rooms"][-1]["id"]: f"organ-{index}" for index, zone in enumerate(ZONES, 1)}
    grants.update({f"hub-{i}": f"socket-{i}" for i in range(1, 8)})
    return edges, grants


def visit(edges, grants, start, keys=frozenset()):
    pending = deque([(start, keys)])
    seen = set()
    required_sockets = {f"socket-{i}" for i in range(1, 8)}
    while pending:
        room, keys = pending.popleft()
        if room in grants:
            keys = keys | {grants[room]}
        if required_sockets <= keys:
            keys = keys | {"all-sockets"}
        if (room, keys) in seen:
            continue
        seen.add((room, keys))
        pending.extend((target, keys) for target, gate in edges.get(room, []) if gate is None or gate in keys)
    return seen


def validate_graph():
    ids = [room["id"] for room in ROOMS]
    assert ids == [f"{i:02d}" for i in range(1, 30)]
    assert len({zone["organ"] for zone in ZONES}) == 7
    assert [i for i, zone in enumerate(ZONES, 1) if zone["isolation"]] == [2, 5, 7]
    edges, grants = graph()
    seen = visit(edges, grants, "start")
    assert any(room == "terminal" and "all-sockets" in keys for room, keys in seen)
    assert not any(room == "29" for room, _ in visit(edges, grants, "rest-final"))
    assert not any(room == "early-terminal" for room, _ in seen)
    returning = visit(edges, grants, "start", frozenset({"previous-clear"}))
    assert {"early-terminal", "terminal"} <= {room for room, _ in returning}
    for room, keys in seen:
        if room.startswith(("archive-", "rest-", "hub-")):
            assert any(end == "terminal" for end, _ in visit(edges, grants, room, keys)), room
    runs = 0
    for zone in ZONES:
        teach, develop, test, boss = zone["rooms"]
        assert teach["kind"] == "teach" and boss["kind"] == "climax"
        for intensity in [teach["intensity"], develop["intensity"], test["intensity"], 0.18, boss["intensity"], 0.12]:
            runs = runs + 1 if intensity >= 0.70 else 0
            assert runs <= 2
    assert ROUTE["final"]["intensity"] == 1.0


def seeded_pick(seed, room, purpose, count):
    data = f'{ROUTE["version"]}|{seed}|{room}|{purpose}'.encode()
    return int.from_bytes(blake2b(data, digest_size=8).digest(), "little") % count


@lru_cache(maxsize=None)
def validate_blockout(name, mirrored, boss):
    blueprint = ROUTE["layouts"][name]
    left, top, width, height = ROUTE["logical_floor"]
    spawn, exit_point, archive = (tuple(ROUTE[key]) for key in ("spawn", "exit", "archive"))
    walls = blueprint["walls"]
    points = blueprint["spawns"]
    if mirrored:
        walls = [(640 - x - w, y, w, h) for x, y, w, h in walls]
        points = [(640 - x, y) for x, y in points]
        exit_point, archive = [(640 - x, y) for x, y in (exit_point, archive)]

    def clear(point, radius):
        x, y = point
        return (left <= x <= left + width and top <= y <= top + height
                and not any(a - radius < x < a + w + radius and b - radius < y < b + h + radius
                            for a, b, w, h in walls))

    radius = ROUTE["min_clear_corridor"] / 2
    assert clear(spawn, radius), (name, "spawn footprint")
    marked = {spawn}
    pending = deque([spawn])
    while pending:
        x, y = pending.popleft()
        for point in ((x + 4, y), (x - 4, y), (x, y + 4), (x, y - 4)):
            if point not in marked and clear(point, radius):
                pending.append(point)
                marked.add(point)
    for target in (exit_point, archive):
        assert min(dist(target, point) for point in marked) <= 8, (name, mirrored, target)
    for point in points:
        assert dist(spawn, point) >= ROUTE["min_initial_enemy_distance"], (name, point)
        if not boss:
            assert clear(point, ROUTE["foot_radius"]), (name, point)


def map_signature(seed):
    choices = []
    for room in ROOMS:
        ids = room["layouts"]
        selected = ids[seeded_pick(seed, room["id"], "layout", len(ids))]
        mirrored = bool(seeded_pick(seed, room["id"], "mirror", 2))
        choices.append((selected, mirrored, room["kind"] == "climax"))
    return tuple(choices)


def endings(a, k, isolated):
    choices = {"长夜"}
    if a <= 2:
        choices.add("熄灯")
        if k == 7 and isolated == 3:
            choices.add("醒")
    if a >= 10 and isolated < 3:
        choices.add("接生")
    if a >= 8 and k >= 5:
        choices.add("成为圣骸")
    return choices


def possible_progress(initial_names):
    states = {(0, initial_names)}
    for i in range(7):
        states = {(a + gain, names | ((1 << i) if gain == 0 else 0))
                  for a, names in states for gain in (0, 1, 2)}
    return states


def validate_balance():
    for tier, zone in enumerate(ZONES):
        damage = [base + 2 * tier + (tier > 0) for base in (8, 5, 3)]
        minimum = ceil(zone["normal_hp"][0] / max(damage))
        maximum = ceil(zone["normal_hp"][1] / min(damage))
        boss_hits = [ceil(zone["boss_hp"] / value) for value in damage]
        assert (1 if tier == 0 else 2) <= minimum <= maximum <= 5
        assert 4 <= min(boss_hits) <= max(boss_hits) <= 18
        assert all(base <= value for base, value in zip((8, 5, 3), damage))
        print(f'{zone["name"]}: weapon damage {damage}, normal {minimum}–{maximum} hits, boss {boss_hits}')
    final = ROUTE["final"]
    final_hits = [ceil(final["hp"] * (1 + final["max_growth"]) / value) for value in damage]
    assert 10 <= min(final_hits) <= max(final_hits) <= 26
    assert 3 == ceil(5 / 2) and 4 == ceil(7 / 2)
    assert 3 * 6 + 12 - (12 + 10 + 6) == 2
    first_run = possible_progress(0)
    later_run = possible_progress(127)
    assert (0, 127) in first_run
    assert all("成为圣骸" not in endings(a, names.bit_count(), 0) for a, names in first_run)
    choices = set.union(*(endings(a, names.bit_count(), r) for a, names in later_run for r in range(4)))
    assert choices == {"长夜", "醒", "熄灯", "接生", "成为圣骸"}
    assert endings(0, 7, 3) == {"长夜", "熄灯", "醒"}
    assert endings(14, 0, 0) == {"长夜", "接生"}


if __name__ == "__main__":
    validate_graph()
    validate_balance()
    for seed in range(500):
        choices = map_signature(seed)
        combat_rng = random.Random(seed)
        for _ in range(seed % 31):
            combat_rng.random()
        assert choices == map_signature(seed)
        for choice in choices:
            validate_blockout(*choice)
    print(f"29 combat rooms, seven sockets and optional archives checked. {29 * 500} seeded room selections accepted.")
