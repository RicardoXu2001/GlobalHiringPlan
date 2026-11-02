extends RefCounted
## 唯一模拟状态与时间。UI 只通过这里的动作修改游戏。
## 金额均为整数分；工资按模拟日累计，60模拟日为一个财务周。

const PACE = 0.34
const SAVE_VERSION = 2
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
	state.merge({"company": content.economy.company.id, "origin": "eastAsia",
		"cash": int(content.economy.company.initialCash), "cashIn": 0, "cashOut": 0,
		"tools": {}, "order": {}, "orderSerial": 0, "completed": 0,
		"working": false, "autoOrders": false, "preference": "quick", "recruiting": false,
		"firstHire": false, "receivables": [], "arrears": 0, "rescueUntil": 0,
		"payrollUnits": 0.0, "regionUnits": 0.0, "marketUsed": 0,
		"ledger": [], "weeks": [], "weekReceipts": 0, "weekOpening": int(content.economy.company.initialCash)})
	for region in content.regions:
		state.area[region.id] = {"count": 0.0, "contact": 0.0}

func start(id: String):
	if not state.area.has(id):
		return
	reset()
	state.started = true
	state.selected = id
	state.origin = id
	state.log = "公司现在就你一个人。从看板接一单，赚取第一笔回款。"

func running() -> bool:
	return state.started and state.outcome.is_empty()

func can_act() -> bool:
	return running() and not state.eventOpen

func tool_owned(id: String) -> bool:
	return state.tools.has(id)

func order_by_id(id: String) -> Dictionary:
	for order in content.orders:
		if order.id == id:
			return order
	return {}

func market_capacity() -> int:
	var residents = 0
	for region in content.regions:
		if state.area[region.id].count > 0 or region.id == state.origin:
			residents += int(region.pop)
	return residents * int(content.economy.demandPerResident)

func order_available(id: String, automatic: bool = false) -> bool:
	return order_block_reason(id, automatic).is_empty()

func order_block_reason(id: String, automatic: bool = false) -> String:
	var order = order_by_id(id)
	if not running():
		return "请先开始一局游戏。"
	if state.eventOpen:
		return "请先处理当前职场事件。"
	if not state.order.is_empty():
		return "正在执行订单，请先完成当前订单。"
	if order.is_empty():
		return "订单不存在。"
	if order.has("req") and not tool_owned(order.req):
		return "需要先购买高效工作台。"
	var remaining = maxi(0, market_capacity() - int(state.marketUsed))
	if remaining < order.work:
		return "本周额度不足（剩%d，需要%d）；%d日后刷新。" % [remaining, order.work, days_to_bill()]
	var reserve = next_bill() if automatic and order.fee > 0 else 0
	if state.cash < order.fee:
		return "现金不足，启动本单需%s。" % money(order.fee)
	if state.cash < order.fee + reserve:
		return "需要预留下次账单%s；当前不足以支付本单启动费。" % money(reserve)
	return ""

func accept_order(id: String, automatic: bool = false) -> bool:
	if not can_act() or not order_available(id, automatic):
		return false
	var order = order_by_id(id)
	if not spend(int(order.fee), "订单启动费 · " + order.name):
		return false
	state.orderSerial += 1
	state.order = {"id": id, "serial": state.orderSerial, "progress": 0.0}
	state.marketUsed += int(order.work)
	state.working = false
	state.log = "已接下「%s」，交付报酬%s。" % [order.name, money(order.reward)]
	return true

func toggle_work():
	if can_act() and not state.order.is_empty() and state.order.progress < order_by_id(state.order.id).work:
		state.working = not state.working

func deliver() -> bool:
	if not can_act() or state.order.is_empty():
		return false
	var order = order_by_id(state.order.id)
	if state.order.progress < order.work:
		return false
	var serial = state.order.serial
	state.completed += 1
	state.order = {}
	state.working = false
	if order.delay == 0:
		receive(int(order.reward), "交付回款 · " + order.name)
		state.log = "「%s」已交付，到账%s。" % [order.name, money(order.reward)]
	else:
		state.receivables.append({"serial": serial, "name": order.name, "amount": int(order.reward), "due": state.day + int(order.delay)})
		state.log = "已交付「%s」；%s于第%d日到账，暂不可用。" % [order.name, money(order.reward), state.day + order.delay]
	return true

func buy_tool(id: String) -> bool:
	if not can_act() or tool_owned(id):
		return false
	for tool in content.tools:
		if tool.id == id:
			if tool.has("req") and not tool_owned(tool.req):
				return false
			if not spend(int(tool.cost), "工具投资 · " + tool.name):
				return false
			state.tools[id] = true
			state.log = "已启用「%s」。" % tool.name
			return true
	return false

func hire_first() -> bool:
	if not can_act() or state.firstHire or not spend(int(content.economy.hireCost), "首雇与入职准备"):
		return false
	state.firstHire = true
	state.area[state.origin].count = 1.0
	state.log = "第一位员工入职！已接订单会自动执行与交付；工资按在岗时间累计。"
	return true

func toggle_auto():
	if can_act() and state.firstHire and tool_owned("workflow"):
		state.autoOrders = not state.autoOrders

func toggle_recruiting():
	if can_act() and state.firstHire:
		state.recruiting = not state.recruiting
		state.log = "地图招聘已开启：新增员工会形成工资支出。" if state.recruiting else "已暂停新增招聘；现有员工继续工作并计薪。"

func change_preference():
	var ids = ["quick", "batch", "enterprise"]
	state.preference = ids[(ids.find(state.preference) + 1) % ids.size()]

func money(cents) -> String:
	return "¥%.2f" % (float(cents) / 100.0)

func ledger_entry(amount: int, label: String):
	state.ledger.append({"day": state.day, "amount": amount, "label": label, "balance": state.cash})
	if state.ledger.size() > 12:
		state.ledger.pop_front()

func spend(amount: int, label: String) -> bool:
	if amount < 0 or state.cash < amount:
		return false
	if amount > 0:
		state.cash -= amount
		state.cashOut += amount
		ledger_entry(-amount, label)
	return true

func receive(amount: int, label: String):
	state.cash += amount
	state.cashIn += amount
	state.weekReceipts += amount
	ledger_entry(amount, label)
	pay_arrears()

func pay_arrears():
	var payment = mini(int(state.cash), int(state.arrears))
	if payment > 0:
		spend(payment, "补付到期欠款")
		state.arrears -= payment
	if state.arrears == 0:
		state.rescueUntil = 0

func days_to_bill() -> int:
	return int(content.economy.weekDays) - int(state.day) % int(content.economy.weekDays)

func wage_estimate(days: int) -> int:
	return roundi(headcount() * content.economy.weeklyWage * days / content.economy.weekDays)

func next_bill() -> int:
	var days = days_to_bill()
	var wages = roundi((state.payrollUnits + headcount() * days) * content.economy.weeklyWage / content.economy.weekDays)
	var regions = roundi((state.regionUnits + maxi(1, covered()) * days) * content.economy.regionCost / content.economy.weekDays)
	return wages + regions + int(content.economy.baseCost)

func receivable_total() -> int:
	var total = 0
	for payment in state.receivables:
		total += int(payment.amount)
	return total

func forecast() -> Array:
	var rows = []
	var balance = int(state.cash) - int(state.arrears)
	var previous_day = int(state.day)
	for i in range(3):
		var due = int(state.day) + days_to_bill() + i * int(content.economy.weekDays)
		var receipts = 0
		for payment in state.receivables:
			if payment.due > previous_day and payment.due <= due:
				receipts += int(payment.amount)
		var bill = next_bill() if i == 0 else wage_estimate(int(content.economy.weekDays)) + int(content.economy.baseCost) + maxi(1, covered()) * int(content.economy.regionCost)
		balance += receipts - bill
		rows.append({"due": due, "receipts": receipts, "bill": bill, "balance": balance})
		previous_day = due
	return rows

func tick_economy():
	# 同日先收款、履约，再结工资；所有到期点逐日执行，快进不跳账。
	for i in range(state.receivables.size() - 1, -1, -1):
		var payment = state.receivables[i]
		if payment.due <= state.day:
			state.receivables.remove_at(i)
			receive(int(payment.amount), "应收到账 · " + payment.name)
	if state.order.is_empty() and state.autoOrders and headcount() > 0:
		accept_automatic()
	var production = headcount() * content.economy.workerRate
	if state.working:
		production += content.economy.founderRate * (2.0 if tool_owned("desk") else 1.0)
	while production > 0 and not state.order.is_empty():
		var required = order_by_id(state.order.id).work - state.order.progress
		var applied = minf(production, required)
		state.order.progress += applied
		production -= applied
		if state.order.progress < order_by_id(state.order.id).work or headcount() <= 0:
			break
		deliver()
		if state.autoOrders:
			accept_automatic()
	state.payrollUnits += headcount()
	state.regionUnits += maxi(1, covered())
	if int(state.day) % int(content.economy.weekDays) == 0:
		var wages = roundi(state.payrollUnits * content.economy.weeklyWage / content.economy.weekDays)
		var operations = int(content.economy.baseCost) + roundi(state.regionUnits * content.economy.regionCost / content.economy.weekDays)
		var bill = wages + operations
		var paid = mini(int(state.cash), bill)
		spend(paid, "周结工资%s / 运营%s" % [money(wages), money(operations)])
		state.arrears += bill - paid
		if state.arrears > 0 and state.rescueUntil == 0:
			state.rescueUntil = state.day + int(content.economy.weekDays * content.economy.graceWeeks)
		state.weeks.append({"day": state.day, "opening": state.weekOpening, "receipts": state.weekReceipts, "wages": wages, "operations": operations, "paid": paid, "arrears": state.arrears, "closing": state.cash})
		if state.weeks.size() > 6:
			state.weeks.pop_front()
		state.weekOpening = state.cash
		state.weekReceipts = 0
		state.payrollUnits = 0.0
		state.regionUnits = 0.0
		state.marketUsed = 0
	pay_arrears()
	if state.arrears > 0 and state.day >= state.rescueUntil:
		finish(false, "到期欠款%s在两周救援期内未补齐。可提前暂停招聘、接快回款订单或保留工资储备。" % money(state.arrears))

func accept_automatic():
	# ponytail: 单一共享订单队列；需要独立地区业务时再拆队列。
	var id = automatic_order_id()
	if not id.is_empty():
		accept_order(id, true)

func automatic_order_id() -> String:
	if order_available(state.preference, true):
		return state.preference
	var preferred = order_by_id(state.preference)
	# 内容表按工作量由小到大排列；优先补接可执行的较大档小单。
	for i in range(content.orders.size() - 1, -1, -1):
		var order = content.orders[i]
		if order.work < preferred.work and order_available(order.id, true):
			return order.id
	return ""

func automatic_status() -> String:
	if not state.autoOrders:
		return "自动接单已关闭；从上方选择订单，首雇后自动执行与交付。"
	if headcount() <= 0:
		return "自动接单等待：需要有员工在岗。"
	var next = automatic_order_id()
	if next.is_empty():
		return "自动接单等待：" + order_block_reason(state.preference, true)
	var action = "将优先接" if next == state.preference else "偏好订单暂不可接，将补接"
	return ("已暂停；恢复后" if state.paused else "自动接单：") + action + "「%s」。" % order_by_id(next).name

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
	tick_economy()
	if not state.outcome.is_empty():
		return
	if state.firstHire:
		tick_hiring()

func tick_hiring():
	for region in content.regions:
		var area = state.area[region.id]
		if area.count <= 0:
			continue
		var fit = region.fit * (1.32 if region.fit < 0.8 and owned("local") else 1.0)
		var grow = (0.035 + area.count * 0.018) * (1 - 0.88 * area.count / region.pop) * fit
		grow *= 1 + bonus("referral", 0.25) + bonus("campus", 0.45) + bonus("coffee", 0.1) + bonus("slogan", 0.55) + bonus("globalHR", 0.18)
		if not state.recruiting:
			grow = 0.0
		var loss = area.count * (0.00055 + bonus("slogan", 0.0022))
		loss *= (0.6 if owned("flex") else 1.0) * (0.6 if owned("shares") else 1.0)
		loss *= (0.8 if owned("globalHR") else 1.0) * (1.4 if state.resistance > 60 else 1.0)
		area.count = clampf(area.count + (grow - loss) * PACE, 0, region.pop)
		if state.recruiting and region.pop - area.count < 0.65 and grow > loss:
			area.count = region.pop
	for region in content.regions:
		var area = state.area[region.id]
		if area.count > 0 or not state.recruiting:
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
		if not active.is_empty():
			state.bubble = active[rng.randi_range(0, active.size() - 1)]
		state.bubbleAt = state.day + 28
	if not state.bubble.is_empty() and state.day >= state.bubbleAt + 26:
		state.bubble = ""
		state.bubbleAt = state.day + 15
	if state.resistance >= 100:
		finish(false, "世界反制完成，公司被拆分。试试更早改善待遇和合规。")
	elif hires >= total_population and state.arrears == 0:
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
	for key in ["day", "points", "speed", "bubbleAt", "eventIndex", "lastMilestone", "cash", "cashIn", "cashOut", "orderSerial", "completed", "arrears", "rescueUntil", "marketUsed", "weekReceipts", "weekOpening"]:
		state[key] = int(state[key])
	rng.state = int(state.get("rngState", "0"))
	return true

func valid_save(candidate) -> bool:
	if not candidate is Dictionary or candidate.get("version") != SAVE_VERSION:
		return false
	# 检查所有运行时会读取的字段，不覆盖损坏或未来版本存档。
	for key in state:
		if not candidate.has(key):
			return false
	for key in ["area", "upgrades", "outcome", "tools", "order"]:
		if not candidate[key] is Dictionary:
			return false
	for key in ["day", "points", "awareness", "resistance", "speed", "bubbleAt", "eventIndex", "lastMilestone"]:
		if not (candidate[key] is float or candidate[key] is int) or not is_finite(float(candidate[key])):
			return false
	for key in ["started", "paused", "eventOpen", "working", "autoOrders", "recruiting", "firstHire"]:
		if not candidate[key] is bool:
			return false
	for key in ["selected", "bubble", "log", "rngState", "origin", "company", "preference"]:
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
	if not candidate.origin in state.area or candidate.company != content.economy.company.id or order_by_id(candidate.preference).is_empty():
		return false
	for key in ["cash", "cashIn", "cashOut", "orderSerial", "completed", "arrears", "rescueUntil", "marketUsed", "weekReceipts", "weekOpening"]:
		if not valid_number(candidate[key], true):
			return false
	for key in ["payrollUnits", "regionUnits"]:
		if not valid_number(candidate[key]):
			return false
	if candidate.cash != content.economy.company.initialCash + candidate.cashIn - candidate.cashOut:
		return false
	if (candidate.arrears == 0) != (candidate.rescueUntil == 0):
		return false
	if candidate.autoOrders and (not candidate.firstHire or not candidate.tools.has("workflow")):
		return false
	if not candidate.order.is_empty():
		var order = order_by_id(candidate.order.get("id", ""))
		if order.is_empty() or not valid_number(candidate.order.get("progress")) or candidate.order.progress > order.work:
			return false
		if not valid_number(candidate.order.get("serial"), true) or candidate.order.serial > candidate.orderSerial:
			return false
	for key in ["receivables", "ledger", "weeks"]:
		if not candidate[key] is Array:
			return false
	var serials = []
	for payment in candidate.receivables:
		if not payment is Dictionary or not payment.get("name") is String:
			return false
		for key in ["amount", "due", "serial"]:
			if not valid_number(payment.get(key), true):
				return false
		if payment.serial > candidate.orderSerial or payment.serial in serials or payment.due <= candidate.day:
			return false
		serials.append(payment.serial)
	for entry in candidate.ledger:
		if not entry is Dictionary or not entry.get("label") is String or not valid_number(entry.get("day"), true) or not valid_number(entry.get("balance"), true):
			return false
		if not (entry.get("amount") is float or entry.get("amount") is int) or not is_finite(float(entry.amount)) or entry.amount != int(entry.amount):
			return false
	for week in candidate.weeks:
		if not week is Dictionary:
			return false
		for key in ["day", "opening", "receipts", "wages", "operations", "paid", "arrears", "closing"]:
			if not valid_number(week.get(key), true):
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

func valid_number(value, whole: bool = false) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value >= 0 and (not whole or value == int(value))
