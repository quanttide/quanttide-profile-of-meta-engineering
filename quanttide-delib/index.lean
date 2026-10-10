/-!
# 议事与决议的意图（Lean 形式）

示例代码，未运行。论域、判定条件、动作的前置与后置、两条不变量，
对应 `index.md` 意图一节的式子。
-/

/-- 产生决议的三种机构 -/
inductive Org where
  | company
  | alliance
  | trainingBase
  deriving Repr, DecidableEq

/-- 决议的生命周期：四个相位 -/
inductive Phase where
  | proposed
  | passed
  | certified
  | published
  deriving Repr, DecidableEq

/-- 一条决议：由某个机构通过，处在某个相位 -/
structure Resolution where
  org   : Org
  phase : Phase

/-- passed(r)：已通过（相位越过 proposed） -/
def Passed (r : Resolution) : Prop :=
  r.phase = .passed ∨ r.phase = .certified ∨ r.phase = .published

/-- certified(r)：已认证 -/
def Certified (r : Resolution) : Prop :=
  r.phase = .certified ∨ r.phase = .published

/-- C(r)：社区决议的早期判定条件——通过且认证 -/
def C (r : Resolution) : Prop := Passed r ∧ Certified r

/-- 社区决议按 C 定义 -/
def Community (r : Resolution) : Prop := C r

/-- 议事通过：pre = proposed，post = passed -/
def deliberate (r : Resolution) (_h : r.phase = .proposed) : Resolution :=
  { r with phase := .passed }

/-- 创始人认证：pre = passed，post = certified -/
def certify (r : Resolution) (_h : r.phase = .passed) : Resolution :=
  { r with phase := .certified }

/-- 官网发布：pre = C r，post = published -/
def publish (r : Resolution) (_h : C r) : Resolution :=
  { r with phase := .published }

/-- inv1：被称为社区决议 ⇒ C r（由定义直接成立） -/
theorem inv1 (r : Resolution) (h : Community r) : C r := h

/-- inv2：发在官网 ⇒ 已认证 -/
theorem inv2 (r : Resolution) (h : C r) : Certified (publish r h) := by
  simp [publish, Certified]

/-- post：认证之后相位是 certified -/
theorem certify_post (r : Resolution) (h : r.phase = .passed) :
    (certify r h).phase = .certified := rfl

/-- post：发布之后相位是 published -/
theorem publish_post (r : Resolution) (h : C r) :
    (publish r h).phase = .published := rfl

/-- C 对发布保持：发布前置立起，发布后仍满足 C -/
theorem publish_keeps_C (r : Resolution) (h : C r) : C (publish r h) := by
  rcases h with ⟨_, _⟩
  exact ⟨Or.inr rfl, Or.inr rfl⟩
