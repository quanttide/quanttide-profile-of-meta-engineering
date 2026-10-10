// 议事与决议的规格（Cue 示例）。
// 示例代码，未运行。字段取值与不变量对应 index.md 规格一节。
package delib

// 产生决议的三种机构
#Org: "company" | "alliance" | "trainingBase"

// 生命周期四个相位
#Phase: "proposed" | "passed" | "certified" | "published"

// 一条决议的最小数据模型
#Resolution: {
	org:   #Org
	phase: #Phase
	// 这条决议在哪条议题下通过的，可选
	topic?: string
}

// C(r) 成立的相位：已通过且已认证
#CertifiedPhase: "certified" | "published"

// inv1：标为社区决议的，相位必须已越过认证
#CommunityResolution: {
	org:   #Org
	phase: #CertifiedPhase
	topic?: string
}

// inv2：相位是已发布的，认证必然在场（发布的前置就是 C）
#PublishedOnSite: {
	org:   #Org
	phase: "published"
	topic?: string
}

// 决议清单：条目按决议编号索引
resolutions: [string]: #Resolution

resolutions: pay-001: {
	org:   "alliance"
	phase: "published"
	topic: "退款规则修订"
}

resolutions: pay-002: {
	org:   "company"
	phase: "proposed"
}
