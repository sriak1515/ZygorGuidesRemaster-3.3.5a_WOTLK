-- Predicate truth tables are tested independently of native mutable quest caches.
local root=arg[1] or 'ZygorGuidesViewerRM'
ZygorGuidesViewer={}
assert(loadfile(root..'/CampaignAdmission.lua'))()
local evaluate=ZygorGuidesViewer.CampaignAdmission.Evaluate
local facts={log={[1]={goals={{num=2,needed=3},{num=4,needed=4}}}},known={[1]=true,[2]=true},rewards={[1]=false,[2]=true}}
local t,f,u={quest_rewarded=2},{quest_rewarded=1},{quest_rewarded=3}
assert(evaluate(nil,{})==true)
assert(evaluate(t,facts)==true and evaluate(f,facts)==false and evaluate(u,facts)==nil)
assert(evaluate({['not']=t},facts)==false)
assert(evaluate({['not']=f},facts)==true)
assert(evaluate({['not']=u},facts)==nil)
assert(evaluate({['not']={['not']=u}},facts)==nil)
assert(evaluate({all={t,t}},facts)==true)
assert(evaluate({all={t,u}},facts)==nil)
assert(evaluate({all={u,f}},facts)==false)
assert(evaluate({any={f,f}},facts)==false)
assert(evaluate({any={f,u}},facts)==nil)
assert(evaluate({any={u,t}},facts)==true)
assert(evaluate({quest_active=1},facts)==true)
assert(evaluate({quest_active=2},facts)==false)
assert(evaluate({quest_active=3},facts)==nil)
assert(evaluate({['not']={quest_active=3}},facts)==nil)
assert(evaluate({quest_objective_complete={quest_id=1,objective_index=1}},facts)==false)
assert(evaluate({quest_objective_complete={quest_id=1,objective_index=2}},facts)==true)
assert(evaluate({quest_objective_complete={quest_id=1,objective_index=3}},facts)==nil)
assert(evaluate({quest_objective_complete={quest_id=2,objective_index=1}},facts)==nil)
for _,condition in ipairs({{class_is='Druid'},{race_is='NightElf'},{level_at_least={actor='leader',level=1}},{has_item={item_id=1,count=1}}}) do
 assert(evaluate(condition,facts)==nil and evaluate({['not']=condition},facts)==nil)
end
print('PASS narrative predicates: true/false/unknown, nested negation, conjunction/disjunction, unwatched/absent/missing objectives and unsupported observation denial')
