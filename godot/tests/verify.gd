extends SceneTree
## 无依赖的机制回归。真实窗口与玩家输入须另做实机验证。
const Simulation = preload("res://simulation.gd")
var failures = []

func check(condition: bool, message: String):
	if not condition:
		failures.append(message)
		push_error(message)

func _init():
	var game = Simulation.new()
	game.start("eastAsia")
	check(game.state.area.eastAsia.count == 1, "起点应只有第一位员工")
	check(not game.purchase("remote"), "不能跳过升级前置")
	check(game.purchase("referral") and game.state.points == 0, "升级应扣点")
	check(not game.purchase("referral"), "不能重复购买")
	game.state.paused = true
	game.tick()
	check(game.state.day == 0, "暂停不推进时间")
	game.state.paused = false
	for i in range(600):
		game.tick()
		if game.state.eventOpen:
			var day = game.state.day
			game.tick()
			check(game.state.day == day, "事件阅读时不推进")
			game.choose(0)
	check(game.covered() > 1, "招聘应沿路线进入其他地区")
	var save_path = "res://tests/test-save.json"
	check(game.save_game(save_path) == OK, "存档写入失败")
	var loaded = Simulation.new()
	check(loaded.load_game(save_path), "存档读取失败")
	var expected = game.state.duplicate(true)
	expected.rngState = str(game.rng.state)
	check(JSON.parse_string(JSON.stringify(expected)) == loaded.state, "存档状态应一致")
	for i in range(60):
		game.tick()
		loaded.tick()
	check(game.state.bubble == loaded.state.bubble and game.state.day == loaded.state.day, "随机与模拟进度应一致")
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string('{"version":999}')
	file.close()
	var before = loaded.state.duplicate(true)
	check(not loaded.load_game(save_path) and loaded.state == before, "拒绝未知版本且保留当前状态")
	DirAccess.remove_absolute(save_path)
	var route = ["referral", "headhunt", "remote", "coffee", "flex", "local", "legal", "roundtable", "campus", "shares", "globalHR"]
	var winner = play(route, false)
	check(not winner.state.outcome.is_empty() and winner.state.outcome.win, "稳健路线应完成全球入职")
	check(winner.state.day >= 1200 and winner.state.day <= 1500, "旧规则自动演练目标应为20–25分钟")
	check(winner.headcount() == winner.total_population, "最后一人必须可达")
	var loser = play(["coffee", "slogan", "referral", "headhunt", "remote", "campus"], true)
	check(not loser.state.outcome.is_empty() and not loser.state.outcome.win, "高压路线应触发反制失败")
	winner.reset()
	check(not winner.state.started and winner.headcount() == 0 and winner.state.upgrades.is_empty(), "重开恢复初态")
	var report = {"status": "PASS" if failures.is_empty() else "FAIL", "failures": failures,
		"stableRouteDay": last_win_day, "recklessRouteDay": loser.state.day,
		"engine": Engine.get_version_info().string, "runtime": "Godot Windows headless",
		"scope": "模拟与存档回归；不证明真实画面、系统输入或导出包"}
	var output = FileAccess.open("res://../qa/evidence/mechanisms.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

var last_win_day = 0

func play(route: Array, reckless: bool):
	var game = Simulation.new()
	game.start("eastAsia")
	for i in range(2400):
		game.tick()
		if not game.state.outcome.is_empty():
			break
		if game.state.eventOpen:
			game.choose(1 if reckless or game.state.resistance <= 45 else 0)
		if not game.state.bubble.is_empty():
			game.collect_bubble()
		if i % 10 == 0:
			for id in route:
				if not game.owned(id):
					game.purchase(id)
					break
	if not reckless:
		last_win_day = game.state.day
	return game
