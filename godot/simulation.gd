extends RefCounted
## 唯一模拟状态与时间。UI 只通过这里的动作修改游戏。
## 招聘规则沿用浏览器原型；财务与方针尚未接入。

const PACE = 0.34
const SAVE_VERSION = 1
var content: Dictionary
var state: Dictionary
var rng = RandomNumberGenerator.new()
var total_population = 0.0

func _init():
	content = JSON.parse_string(FileAccess.get_file_as_string("res://data/content.json"))
	for region in content.regions:
		total_population += region.pop
	reset()

func reset():
	rng.seed = 20261013
	state = {"version": SAVE_VERSION, "started": false, "day": 0, "points": 6,
		"awareness": 0.0, "resistance": 0.0, "selected": "eastAsia", "speed": 1,
		"paused": false, "upgrades": {}, "area": {}, "bubble": "", "bubbleAt": 18,
		"eventIndex": 0, "eventOpen": false, "outcome": {}, "lastMilestone": 0,
		"log": "选择起点，给地球发出第一张工牌。"}
	for region in content.regions:
		state.area[region.id] = {"count": 0.0, "contact": 0.0}

func start(id: String):
	if not state.area.has(id):
		return
	reset()
	state.started = true
	state.selected = id
	state.area[id].count = 1.0
	state.log = "%s的第一位员工已经入职。" % region_by_id(id).name

func region_by_id(id: String) -> Dictionary:
	for region in content.regions:
		if region.id == id:
			return region
	return {}

func owned(id: String) -> bool:
	return state.upgrades.has(id)

func headcount() -> float:
	var count = 0.0
	for area in state.area.values():
		count += area.count
	return count

func covered() -> int:
	var count = 0
	for area in state.area.values():
		if area.count > 0:
			count += 1
	return count

func purchase(id: String) -> bool:
	if not state.started or not state.outcome.is_empty():
		return false
	for card in content.cards:
		if card.id != id:
			continue
		if owned(id) or (card.has("req") and not owned(card.req)) or state.points < card.cost:
			return false
		state.points -= int(card.cost)
		state.upgrades[id] = true
		state.log = "总部启用「%s」。" % card.name
		return true
	return false

func collect_bubble():
	if state.bubble.is_empty() or not state.outcome.is_empty():
		return
	state.points += 3
	state.bubble = ""
	state.bubbleAt = state.day + 27
	state.log = "收到一份闪闪发光的简历，招聘点 +3。"

func choose(index: int):
	if not state.eventOpen or state.eventIndex >= content.events.size():
		return
	var event = content.events[state.eventIndex]
	if index < 0 or index >= event.choices.size():
		return
	var choice = event.choices[index]
	state.points = maxi(0, state.points + int(choice.get("points", 0)))
	state.awareness = clampf(state.awareness + choice.get("awareness", 0), 0, 100)
	state.resistance = clampf(state.resistance + choice.get("resistance", 0), 0, 100)
	state.eventIndex += 1
	state.eventOpen = false
	state.log = "职场快讯：「%s」——%s。" % [event.title, choice.name]

func bonus(id: String, amount: float) -> float:
	return amount if owned(id) else 0.0

func tick():
	if not state.started or state.paused or state.eventOpen or not state.outcome.is_empty():
		return
	state.day += 1
	for region in content.regions:
		var area = state.area[region.id]
		if area.count <= 0:
			continue
		var fit = region.fit * (1.32 if region.fit < 0.8 and owned("local") else 1.0)
		var grow = (0.035 + area.count * 0.018) * (1 - 0.88 * area.count / region.pop) * fit
		grow *= 1 + bonus("referral", 0.25) + bonus("campus", 0.45) + bonus("coffee", 0.1) + bonus("slogan", 0.55) + bonus("globalHR", 0.18)
		var loss = area.count * (0.00055 + bonus("slogan", 0.0022))
		loss *= (0.6 if owned("flex") else 1.0) * (0.6 if owned("shares") else 1.0)
		loss *= (0.8 if owned("globalHR") else 1.0) * (1.4 if state.resistance > 60 else 1.0)
		area.count = clampf(area.count + (grow - loss) * PACE, 0, region.pop)
		if region.pop - area.count < 0.65 and grow > loss:
			area.count = region.pop
	for region in content.regions:
		var area = state.area[region.id]
		if area.count > 0:
			continue
		var contact = 0.0
		for source_id in region.links:
			contact += state.area[source_id].count / region_by_id(source_id).pop * 0.07
		var rate = 1 + bonus("headhunt", 0.55) + bonus("remote", 0.42)
		rate *= 0.45 if region.id == "oceania" and not owned("remote") else 1.0
		rate *= 0.65 if region.id == "northAsia" and not owned("remote") else 1.0
		area.contact += contact * PACE * rate
		if area.contact >= 1:
			area.count = 1.0
			area.contact = 0.0
			state.points += 4
			state.log = "公司进入%s！招聘点 +4。" % region.name
	var hires = headcount()
	var share = hires / total_population
	var milestone = int(hires / 20)
	if milestone > state.lastMilestone:
		state.points += milestone - state.lastMilestone
		state.lastMilestone = milestone
	state.awareness = clampf(state.awareness + (0.006 + share * 0.055 + bonus("coffee", 0.009) + bonus("slogan", 0.1)) * (0.8 if owned("flex") else 1.0), 0, 100)
	if state.awareness > 22:
		var resistance = 0.006 + share * 0.052 + state.awareness * 0.00025 + bonus("slogan", 0.09)
		resistance *= (0.65 if owned("legal") else 1.0) * (0.68 if owned("roundtable") and state.resistance > 35 else 1.0) * (0.9 if owned("flex") else 1.0)
		state.resistance = clampf(state.resistance + resistance, 0, 100)
	if state.bubble.is_empty() and state.day >= state.bubbleAt:
		var active = []
		for region in content.regions:
			if state.area[region.id].count > 0:
				active.append(region.id)
		state.bubble = active[rng.randi_range(0, active.size() - 1)]
		state.bubbleAt = state.day + 28
	if not state.bubble.is_empty() and state.day >= state.bubbleAt + 26:
		state.bubble = ""
		state.bubbleAt = state.day + 15
	if state.resistance >= 100:
		finish(false, "世界反制完成，公司被拆分。试试更早改善待遇和合规。")
	elif hires >= total_population:
		finish(true, "最后一位居民签完协议。地球人事部：现在全世界都要参加周一例会。")
	elif state.eventIndex < content.events.size() and state.day >= content.events[state.eventIndex].day:
		state.eventOpen = true

func finish(win: bool, message: String):
	state.outcome = {"win": win, "body": message, "day": state.day, "hires": int(headcount())}
	state.eventOpen = false
	state.paused = true

func save_game(path: String) -> Error:
	var snapshot = state.duplicate(true)
	# JSON 浮点不能保真 64 位 RNG 状态，存成字符串。
	snapshot.rngState = str(rng.state)
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path)

func load_game(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var candidate = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not valid_save(candidate):
		return false
	state = candidate
	rng.state = int(state.get("rngState", "0"))
	return true

func valid_save(candidate) -> bool:
	if not candidate is Dictionary or candidate.get("version") != SAVE_VERSION:
		return false
	# 检查所有运行时会读取的字段，不覆盖损坏或未来版本存档。
	for key in state:
		if not candidate.has(key):
			return false
	for key in ["area", "upgrades", "outcome"]:
		if not candidate[key] is Dictionary:
			return false
	for key in ["day", "points", "awareness", "resistance", "speed", "bubbleAt", "eventIndex", "lastMilestone"]:
		if not (candidate[key] is float or candidate[key] is int) or not is_finite(float(candidate[key])):
			return false
	for key in ["started", "paused", "eventOpen"]:
		if not candidate[key] is bool:
			return false
	for key in ["selected", "bubble", "log", "rngState"]:
		if not candidate.get(key) is String:
			return false
	if not candidate.rngState.is_valid_int() or candidate.day < 0 or candidate.points < 0:
		return false
	if not candidate.selected in state.area or candidate.speed != int(candidate.speed) or not int(candidate.speed) in [1, 2, 4]:
		return false
	if candidate.eventIndex < 0 or candidate.eventIndex > content.events.size():
		return false
	if candidate.eventOpen and candidate.eventIndex >= content.events.size():
		return false
	if candidate.awareness < 0 or candidate.awareness > 100 or candidate.resistance < 0 or candidate.resistance > 100:
		return false
	if candidate.bubble != "" and not candidate.bubble in state.area:
		return false
	for region in content.regions:
		var area = candidate.area.get(region.id)
		if not area is Dictionary:
			return false
		for key in ["count", "contact"]:
			if not (area.get(key) is float or area.get(key) is int) or not is_finite(float(area[key])) or area[key] < 0:
				return false
		if area.count > region.pop:
			return false
	if not candidate.outcome.is_empty():
		if not candidate.outcome.get("win") is bool or not candidate.outcome.get("body") is String:
			return false
	return true
