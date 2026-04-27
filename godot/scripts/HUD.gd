extends CanvasLayer
## Top-bar character info, target frame, action bar, level toast.

@export var player_path: NodePath
var player: Node = null

@onready var hp_bar: ProgressBar = $Top/Bars/HpBar
@onready var hp_label: Label = $Top/Bars/HpBar/Label
@onready var mp_bar: ProgressBar = $Top/Bars/MpBar
@onready var mp_label: Label = $Top/Bars/MpBar/Label
@onready var xp_bar: ProgressBar = $Top/Bars/XpBar
@onready var xp_label: Label = $Top/Bars/XpBar/Label
@onready var char_label: Label = $Top/CharLabel
@onready var gold_label: Label = $Top/GoldLabel
@onready var target_panel: PanelContainer = $TargetPanel
@onready var target_name: Label = $TargetPanel/V/TargetName
@onready var target_hp: ProgressBar = $TargetPanel/V/TargetHp
@onready var toast: Label = $Toast
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var potions_label: Label = $Top/PotionsLabel
@onready var quest_label: Label = $Top/QuestLabel

var target_ref: Node = null

func _ready() -> void:
    player = get_node_or_null(player_path)
    if player == null:
        player = get_tree().get_first_node_in_group("player")
    if player:
        player.stats_changed.connect(_refresh)
        player.target_changed.connect(_on_target_changed)
        player.level_up.connect(_on_level_up)
        player.floating_text.connect(_on_floating_text)
    target_panel.visible = false
    toast.visible = false
    shop_panel.visible = false
    var ab := get_node_or_null("ActionBar")
    if ab:
        ab.get_node("BtnAttack").pressed.connect(_on_btn_attack_pressed)
        ab.get_node("BtnPower").pressed.connect(_on_btn_power_pressed)
        ab.get_node("BtnHeal").pressed.connect(_on_btn_heal_pressed)
        ab.get_node("BtnSit").pressed.connect(_on_btn_sit_pressed)
        ab.get_node("BtnPotionHp").pressed.connect(_on_btn_potion_hp)
        ab.get_node("BtnPotionMp").pressed.connect(_on_btn_potion_mp)
    var sp := shop_panel
    if sp:
        sp.get_node("V/BuyHp").pressed.connect(_on_buy_hp)
        sp.get_node("V/BuyMp").pressed.connect(_on_buy_mp)
        sp.get_node("V/QuestBtn").pressed.connect(_on_quest_btn)
        sp.get_node("V/WeaponBtn").pressed.connect(_on_weapon_btn)
        sp.get_node("V/Close").pressed.connect(close_shop)
    var q := get_node_or_null("/root/Quests")
    if q:
        q.quest_updated.connect(_on_quest_changed)
    _refresh()
    _refresh_quest_label()

const HP_POT_COST := 25
const MP_POT_COST := 35
const HP_POT_HEAL := 60
const MP_POT_RESTORE := 50

func _process(_delta: float) -> void:
    if target_ref != null and is_instance_valid(target_ref) and not target_ref.dead:
        target_hp.max_value = target_ref.max_hp
        target_hp.value = target_ref.hp
    elif target_ref != null:
        target_panel.visible = false
        target_ref = null

func _refresh() -> void:
    if player == null: return
    hp_bar.max_value = player.max_hp; hp_bar.value = player.hp
    hp_label.text = "%d / %d" % [player.hp, player.max_hp]
    mp_bar.max_value = player.max_mp; mp_bar.value = player.mp
    mp_label.text = "%d / %d" % [player.mp, player.max_mp]
    xp_bar.max_value = player.xp_next; xp_bar.value = player.xp
    xp_label.text = "XP %d / %d" % [player.xp, player.xp_next]
    char_label.text = "%s · %s · ур.%d %s" % [player.race.name, player.klass.name, player.level, ("(сидит)" if player.sitting else "")]
    gold_label.text = "💰 %d" % player.gold
    potions_label.text = "🧪 HP: %d   💧 MP: %d" % [player.hp_potions, player.mp_potions]

func _on_target_changed(t) -> void:
    target_ref = t
    if t == null:
        target_panel.visible = false
        return
    target_panel.visible = true
    target_name.text = "%s · ур.%d" % [t.kind.name, t.kind.level]

func _on_level_up(lvl: int) -> void:
    toast.text = "Уровень %d!" % lvl
    toast.visible = true
    toast.modulate = Color(1, 1, 0.5, 1)
    var tw := create_tween()
    tw.tween_property(toast, "modulate:a", 0.0, 2.5)
    tw.tween_callback(func(): toast.visible = false)

func _on_floating_text(text, color, world_pos) -> void:
    var lbl := Label3D.new()
    lbl.text = text
    lbl.modulate = color
    lbl.font_size = 36
    lbl.outline_size = 10
    lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lbl.no_depth_test = true
    lbl.position = world_pos
    var world := get_tree().current_scene
    world.add_child(lbl)
    var tw := create_tween()
    tw.tween_property(lbl, "position:y", world_pos.y + 1.4, 1.0)
    tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
    tw.tween_callback(lbl.queue_free)

func _on_btn_attack_pressed() -> void:
    pass
func _on_btn_power_pressed() -> void:
    if player: player.use_skill_power()
func _on_btn_heal_pressed() -> void:
    if player: player.use_skill_heal()
func _on_btn_sit_pressed() -> void:
    if player: player.toggle_sit()
func _on_btn_potion_hp() -> void:
    if player: player.use_hp_potion()
func _on_btn_potion_mp() -> void:
    if player: player.use_mp_potion()

func open_shop() -> void:
    shop_panel.visible = true
    _refresh_weapon_btn()
    _refresh_quest_label()

func close_shop() -> void:
    shop_panel.visible = false

func _on_buy_hp() -> void:
    if player == null: return
    if player.gold < HP_POT_COST:
        toast.text = "Не хватает золота!"
        toast.visible = true
        var tw := create_tween()
        tw.tween_interval(1.0)
        tw.tween_callback(func(): toast.visible = false)
        return
    player.gold -= HP_POT_COST
    player.hp_potions += 1
    player.emit_signal("stats_changed")
    player._save_progress()

func _on_buy_mp() -> void:
    if player == null: return
    if player.gold < MP_POT_COST:
        toast.text = "Не хватает золота!"
        toast.visible = true
        var tw := create_tween()
        tw.tween_interval(1.0)
        tw.tween_callback(func(): toast.visible = false)
        return
    player.gold -= MP_POT_COST
    player.mp_potions += 1
    player.emit_signal("stats_changed")
    player._save_progress()

func _on_quest_btn() -> void:
    var q := get_node_or_null("/root/Quests")
    if q == null or player == null: return
    if q.is_completable():
        var done: Dictionary = q.turn_in()
        if not done.is_empty():
            player._gain_xp(int(done.reward_xp))
            player.add_gold(int(done.reward_gold))
            _flash_toast("Квест выполнен! +%d 💰 +%d XP" % [int(done.reward_gold), int(done.reward_xp)])
        _refresh_quest_label()
    elif q.has_active():
        var aq: Dictionary = q.active_quest()
        _flash_toast("Прогресс: %d / %d" % [q.active_progress, int(aq.target_count)])
    else:
        var qid: String = q.next_offerable()
        if qid == "":
            _flash_toast("Все квесты выполнены — герой!")
        else:
            q.accept(qid)
            var aq2: Dictionary = q.active_quest()
            _flash_toast("Принят квест: %s" % aq2.name)
        _refresh_quest_label()

func _on_quest_changed(_qid) -> void:
    _refresh_quest_label()

func _refresh_quest_label() -> void:
    var q := get_node_or_null("/root/Quests")
    if q == null:
        quest_label.text = ""
        return
    if not q.has_active():
        quest_label.text = "📜 Зайди к торговцу — есть квест"
        return
    var aq: Dictionary = q.active_quest()
    quest_label.text = "📜 %s — %d / %d" % [aq.name, q.active_progress, int(aq.target_count)]
    if q.is_completable():
        quest_label.text += "  ✅"
    var sp := shop_panel
    if sp:
        var btn: Button = sp.get_node("V/QuestBtn") as Button
        if btn:
            if q.is_completable():
                btn.text = "✅ Сдать «%s» (+%d 💰 / +%d XP)" % [aq.name, int(aq.reward_gold), int(aq.reward_xp)]
            elif q.has_active():
                btn.text = "📜 «%s»: %d / %d" % [aq.name, q.active_progress, int(aq.target_count)]
            else:
                btn.text = "📜 Получить новый квест"

func _on_weapon_btn() -> void:
    if player == null: return
    if not player.can_upgrade_weapon():
        _flash_toast("Уже мифрилл — лучше нет!")
        return
    var cost: int = player.next_weapon_cost()
    if player.gold < cost:
        _flash_toast("Не хватает %d 💰" % (cost - player.gold))
        return
    if player.upgrade_weapon():
        var tier_name: String = String(player.WEAPON_TIERS[player.weapon_tier].name)
        _flash_toast("Оружие улучшено: %s" % tier_name)
        _refresh_weapon_btn()

func _refresh_weapon_btn() -> void:
    var sp := shop_panel
    if sp == null or player == null: return
    var btn: Button = sp.get_node("V/WeaponBtn") as Button
    if btn == null: return
    if not player.can_upgrade_weapon():
        btn.text = "⚔ Оружие максимально (мифрилл)"
        btn.disabled = true
        return
    var nxt: int = player.weapon_tier + 1
    var tier_name: String = String(player.WEAPON_TIERS[nxt].name)
    var bonus: int = int(player.WEAPON_TIERS[nxt].bonus) - int(player.WEAPON_TIERS[player.weapon_tier].bonus)
    var cost: int = player.next_weapon_cost()
    btn.text = "⚔ %s (+%d атк) — %d 💰" % [tier_name, bonus, cost]
    btn.disabled = false

func _flash_toast(msg: String) -> void:
    toast.text = msg
    toast.visible = true
    var tw := create_tween()
    tw.tween_interval(2.0)
    tw.tween_callback(func(): toast.visible = false)
