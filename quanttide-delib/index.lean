/-!
# 议事与决议的意图（Lean 形式）

示例代码，未运行。议题、草案、决议三个类型与四个动作的前置后置、
三条不变量，对应 `index.md` 概念与意图两节的式子。
-/

/-- 产生决议的三种机构 -/
inductive Org where
  | company
  | alliance
  | trainingBase
  deriving Repr, DecidableEq

/-- 决议的相位：能成为决议，通过是前提，故从待认证起 -/
inductive Phase where
  | pending
  | certified
  | published
  deriving Repr, DecidableEq

/-- 草案的相位 -/
inductive DraftState where
  | submitted
  | onTable
  | passed
  | rejected
  deriving Repr, DecidableEq

/-- 议题：议程上的条目，有编号有摘要 -/
structure AgendaItem where
  id       : String
  summary  : String
  onAgenda : Bool

/-- 草案：只挂一条议题，带提案国与版本 -/
structure Draft where
  item     : String
  text     : Nat                     -- 版本号，每次修订 +1
  sponsors : List String             -- 提案国，可增可撤
  state    : DraftState

/-- 决议：表决通过才发号 -/
structure Resolution where
  id    : String                     -- 一号一命
  item  : String
  org   : Org
  phase : Phase

/-- certified(r)：认证在场（已认证或已发布） -/
def Certified (r : Resolution) : Prop :=
  r.phase = .certified ∨ r.phase = .published

/-- C(r)：社区决议的早期判定条件——认证在场 -/
def C (r : Resolution) : Prop := Certified r

/-- review：pre 议题在议程上且有提案国，post 草案上桌 -/
def review (a : AgendaItem) (d : Draft)
    (_h : a.onAgenda = true ∧ d.sponsors ≠ []) : Draft :=
  { d with state := .onTable }

/-- deliberate：表决在桌草案，通过则发号产生决议（否决分支示例略） -/
def deliberate (d : Draft) (resId : String) (org : Org)
    (_h : d.state = .onTable) : Resolution :=
  { id := resId, item := d.item, org := org, phase := .pending }

/-- certify：pre 待认证，post 已认证 -/
def certify (r : Resolution) (_h : r.phase = .pending) : Resolution :=
  { r with phase := .certified }

/-- publish：pre C(r)，post 已发布 -/
def publish (r : Resolution) (_h : C r) : Resolution :=
  { r with phase := .published }

/-- inv1：能成为决议，通过是前提；再走认证才满足 C -/
def Community (r : Resolution) : Prop := C r

theorem inv1 (r : Resolution) (h : Community r) : C r := h

/-- inv2：发在官网 ⇒ 已认证 -/
theorem inv2 (r : Resolution) (h : C r) : Certified (publish r h) := by
  simp [publish, Certified]

/-- post：认证之后相位是 certified -/
theorem certify_post (r : Resolution) (h : r.phase = .pending) :
    (certify r h).phase = .certified := rfl

/-- post：发布之后相位是 published -/
theorem publish_post (r : Resolution) (h : C r) :
    (publish r h).phase = .published := rfl

/-- inv3：review 之后草案在桌上，其议题必已上议程（前置所保） -/
theorem inv3 (a : AgendaItem) (d : Draft)
    (h : a.onAgenda = true ∧ d.sponsors ≠ []) :
    (review a d h).state = .onTable := rfl
