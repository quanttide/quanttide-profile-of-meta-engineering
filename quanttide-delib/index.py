"""议事与决议的实现示例（Python）。

示例代码，未运行。三个动作各带前置检查，发布入口只放行满足 C(r) 的决议，
对应 index.md 规格与实现两节。
"""

from dataclasses import dataclass
from enum import Enum

# 机构取值只认这三个，对着仓库里的主体名录
ORGS = ("company", "alliance", "trainingBase")


class Phase(Enum):
    PROPOSED = "proposed"
    PASSED = "passed"
    CERTIFIED = "certified"
    PUBLISHED = "published"


@dataclass(frozen=True)
class Resolution:
    org: str
    phase: Phase = Phase.PROPOSED


def is_passed(r: Resolution) -> bool:
    return r.phase in (Phase.PASSED, Phase.CERTIFIED, Phase.PUBLISHED)


def is_certified(r: Resolution) -> bool:
    return r.phase in (Phase.CERTIFIED, Phase.PUBLISHED)


def C(r: Resolution) -> bool:
    """社区决议的早期判定条件：通过且认证。"""
    return is_passed(r) and is_certified(r)


def deliberate(r: Resolution) -> Resolution:
    """议事通过：前置 state = proposed。"""
    if r.phase is not Phase.PROPOSED:
        raise ValueError(f"议事前置不满足：当前相位 {r.phase.value}")
    return Resolution(r.org, Phase.PASSED)


def certify(r: Resolution) -> Resolution:
    """创始人认证：前置 state = passed。"""
    if r.org not in ORGS:
        raise ValueError(f"机构取值不合法：{r.org}")
    if r.phase is not Phase.PASSED:
        raise ValueError(f"认证前置不满足：当前相位 {r.phase.value}")
    return Resolution(r.org, Phase.CERTIFIED)


def publish(r: Resolution) -> Resolution:
    """官网发布：前置 C(r)，inv2 的闸门设在这里。"""
    if not C(r):
        raise ValueError("官网只收满足 C(r) 的决议")
    return Resolution(r.org, Phase.PUBLISHED)
