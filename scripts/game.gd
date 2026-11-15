extends Node2D

const SPEED := 270.0
const MAX_HP := 100
var player := Vector2(170, 330)
var hp := MAX_HP
var score := 0
var gems := 0
var wave := 1
var enemies: Array[Dictionary] = []
var move := Vector2.ZERO
var joy_id := -1
var joy_origin := Vector2(120, 420)
var joy_delta := Vector2.ZERO
var attack_cd := 0.0
var attack_fx := 0.0
var hurt_flash := 0.0
var ended := false
var victory := false
var notice := "تحرك بعصا التحكم، واضغط ضربة لهزيمة الأعداء"
var notice_t := 4.0

func _ready():
    _new_wave()

func _new_wave():
    enemies.clear()
    var count := 3 + wave * 2
    for i in range(count):
        var boss := wave % 3 == 0 and i == count - 1
        enemies.append({
            "p": Vector2(510 + (i % 4) * 90, 150 + (i % 3) * 135),
            "hp": 180 if boss else 45 + wave * 5,
            "max": 180 if boss else 45 + wave * 5,
            "speed": 42.0 + wave * 3.0 if boss else 52.0 + wave * 2.0,
            "boss": boss,
            "cool": 0.0
        })
    notice = "الموجة %d بدأت! %s" % [wave, "ظهر الزعيم!" if wave % 3 == 0 else "اهزم جميع الأعداء"]
    notice_t = 3.0

func _process(dt):
    if ended:
        queue_redraw()
        return
    attack_cd = maxf(0.0, attack_cd - dt)
    attack_fx = maxf(0.0, attack_fx - dt)
    hurt_flash = maxf(0.0, hurt_flash - dt)
    notice_t = maxf(0.0, notice_t - dt)

    player += move.limit_length(1.0) * SPEED * dt
    player.x = clampf(player.x, 35, 925)
    player.y = clampf(player.y, 105, 505)

    for e in enemies:
        var ep: Vector2 = e.p
        var diff := player - ep
        if diff.length() > 42:
            ep += diff.normalized() * float(e.speed) * dt
        e.p = ep
        e.cool = maxf(0.0, float(e.cool) - dt)
        if diff.length() < (52.0 if e.boss else 40.0) and e.cool <= 0.0:
            hp -= 15 if e.boss else 8
            e.cool = 1.0 if e.boss else 0.85
            hurt_flash = 0.2
            notice = "تلقيت ضربة! ابتعد عن الأعداء"
            notice_t = 1.1
            if hp <= 0:
                hp = 0
                ended = true
                victory = false
                notice = "انتهت المغامرة"
                break

    if enemies.is_empty() and not ended:
        if wave >= 6:
            ended = true
            victory = true
        else:
            wave += 1
            hp = mini(MAX_HP, hp + 20)
            _new_wave()
    queue_redraw()

func attack():
    if ended or attack_cd > 0:
        return
    attack_cd = 0.38
    attack_fx = 0.22
    var idx := -1
    var nearest := 125.0
    for i in range(enemies.size()):
        var d: float = player.distance_to(enemies[i].p)
        if d < nearest:
            nearest = d
            idx = i
    if idx == -1:
        notice = "اقترب أكثر من العدو!"
    else:
        enemies[idx].hp -= 35
        if enemies[idx].hp <= 0:
            score += 100 if not enemies[idx].boss else 500
            gems += 1 if not enemies[idx].boss else 5
            enemies.remove_at(idx)
            notice = "أحسنت! +نقاط وكنوز"
        else:
            notice = "ضربة ناجحة!"
    notice_t = 0.9

func _input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_W, KEY_UP: move.y = -1
            KEY_S, KEY_DOWN: move.y = 1
            KEY_A, KEY_LEFT: move.x = -1
            KEY_D, KEY_RIGHT: move.x = 1
            KEY_SPACE: attack()
            KEY_R:
                if ended: _restart()
    if event is InputEventKey and not event.pressed:
        match event.keycode:
            KEY_W, KEY_UP:
                if move.y < 0: move.y = 0
            KEY_S, KEY_DOWN:
                if move.y > 0: move.y = 0
            KEY_A, KEY_LEFT:
                if move.x < 0: move.x = 0
            KEY_D, KEY_RIGHT:
                if move.x > 0: move.x = 0
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.distance_to(Vector2(840, 430)) < 78:
                attack()
            elif event.position.x < 275 and event.position.y > 285:
                joy_id = event.index
                joy_origin = event.position
                _joy(event.position)
            elif ended and Rect2(330, 285, 300, 100).has_point(event.position):
                _restart()
        elif event.index == joy_id:
            joy_id = -1
            joy_delta = Vector2.ZERO
            move = Vector2.ZERO
    if event is InputEventScreenDrag and event.index == joy_id:
        _joy(event.position)

func _joy(p):
    joy_delta = (p - joy_origin).limit_length(60)
    move = joy_delta / 60.0

func _restart():
    player = Vector2(170, 330)
    hp = MAX_HP
    score = 0
    gems = 0
    wave = 1
    ended = false
    victory = false
    _new_wave()

func _draw():
    draw_rect(Rect2(0,0,960,540), Color("#172936"))
    draw_rect(Rect2(0,90,960,450), Color("#315642"))
    for x in range(0,960,58):
        for y in range(100,540,58):
            draw_circle(Vector2(x+13,y+17), 2, Color(0.8,0.85,0.62,0.12))
    draw_rect(Rect2(0,245,960,115), Color("#89785d"))
    for x in range(0,960,85):
        draw_rect(Rect2(x,258,65,3), Color("#b7a17e"))
        draw_rect(Rect2(x+28,320,44,3), Color("#6e604e"))
    for p in [Vector2(55,145),Vector2(900,145),Vector2(80,480),Vector2(885,480)]:
        draw_circle(p,26,Color("#173b2d"))
        draw_circle(p+Vector2(-6,-8),16,Color("#286044"))

    draw_rect(Rect2(0,0,960,88),Color(0.035,0.055,0.09,0.96))
    draw_string(ThemeDB.fallback_font,Vector2(22,34),"SAHM ADVENTURE",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#f5d98b"))
    draw_string(ThemeDB.fallback_font,Vector2(22,63),"الغابة المفقودة  |  الموجة %d / 6" % wave,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(650,34),"النقاط: %d   الكنوز: %d" % [score,gems],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
    draw_rect(Rect2(650,48,270,17),Color("#482d36"),true,7)
    draw_rect(Rect2(650,48,270.0*float(hp)/MAX_HP,17),Color("#e65c58"),true,7)
    draw_string(ThemeDB.fallback_font,Vector2(650,80),"الصحة %d%%" % hp,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)

    for e in enemies:
        var p: Vector2 = e.p
        var boss: bool = e.boss
        var radius := 28.0 if boss else 19.0
        draw_circle(p+Vector2(0,20),radius+3,Color(0,0,0,0.25))
        draw_circle(p,radius,Color("#693a83") if boss else Color("#a44440"))
        draw_circle(p+Vector2(-7,-4),4,Color.WHITE)
        draw_circle(p+Vector2(7,-4),4,Color.WHITE)
        draw_circle(p+Vector2(-7,-4),2,Color.BLACK)
        draw_circle(p+Vector2(7,-4),2,Color.BLACK)
        draw_rect(Rect2(p.x-radius,p.y-radius-12,radius*2,5),Color("#352b35"))
        draw_rect(Rect2(p.x-radius,p.y-radius-12,radius*2*float(e.hp)/float(e.max),5),Color("#ef745f"))
        if boss:
            draw_string(ThemeDB.fallback_font,p+Vector2(-23,-38),"BOSS",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#ffe18c"))

    draw_circle(player+Vector2(0,22),23,Color(0,0,0,0.25))
    draw_circle(player,20,Color("#e6b44f"))
    draw_circle(player+Vector2(0,-5),12,Color("#f4d5a2"))
    draw_rect(Rect2(player.x-14,player.y+7,28,18),Color("#3569a0"),true,5)
    draw_line(player+Vector2(12,4),player+Vector2(31,-10),Color("#d9e1e8"),5)
    if attack_fx > 0:
        draw_arc(player,75,-1.0,1.25,28,Color("#fff0a6"),8)

    var center := joy_origin if joy_id >= 0 else Vector2(120,425)
    draw_circle(center,58,Color(0.04,0.07,0.1,0.34))
    draw_circle(center+(joy_delta if joy_id >= 0 else Vector2.ZERO),25,Color(0.82,0.88,0.95,0.58))
    draw_circle(Vector2(840,430),58,Color(0.68,0.17,0.13,0.8))
    draw_string(ThemeDB.fallback_font,Vector2(805,438),"ضربة",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)

    if notice_t > 0:
        draw_rect(Rect2(250,98,460,42),Color(0.03,0.05,0.08,0.78),true,12)
        draw_string(ThemeDB.fallback_font,Vector2(480,126),notice,HORIZONTAL_ALIGNMENT_CENTER,440,17,Color("#fff0c9"))
    if ended:
        draw_rect(Rect2(0,0,960,540),Color(0,0,0,0.7))
        draw_string(ThemeDB.fallback_font,Vector2(480,218),"انتصرت في المغامرة!" if victory else "انتهت اللعبة",HORIZONTAL_ALIGNMENT_CENTER,-1,40,Color("#ffe3a0"))
        draw_string(ThemeDB.fallback_font,Vector2(480,264),"نتيجتك: %d   |   الكنوز: %d" % [score,gems],HORIZONTAL_ALIGNMENT_CENTER,-1,22,Color.WHITE)
        draw_rect(Rect2(330,290,300,66),Color("#b87535"),true,14)
        draw_string(ThemeDB.fallback_font,Vector2(480,332),"العب من جديد",HORIZONTAL_ALIGNMENT_CENTER,-1,23,Color.WHITE)
