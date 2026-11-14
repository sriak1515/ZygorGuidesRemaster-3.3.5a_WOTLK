-- Pure delivery tests use the real admission state and simulated reader visibility.
-- test_presentation also exercises the real UI's first-visible commit path.
local root=arg[1] or 'ZygorGuidesViewerRM'
local char={}
local combat,casting=false,false
InCombatLockdown=function()return combat end
UnitCastingInfo=function()return casting and 'Casting' or nil end
ZygorGuidesViewer={CurrentGuideName='reg',db={char=char,profile={}},Frame={IsVisible=function()return true end,GetAlpha=function()return 1 end},
 Presentation={mode='live',storyOpen=false}}
local ZGV=ZygorGuidesViewer
assert(loadfile(root..'/CampaignAdmission.lua'))()
assert(loadfile(root..'/CampaignDelivery.lua'))()
local D=ZGV.CampaignDelivery
local metadata={guide={id='pilot'},narration={
 {id='context',revision='r1',at_step='a',type='context',title='Context',text='Admitted context.'},
 {id='moment',revision='r2',at_step='b',type='moment',title='Moment',text='Admitted moment.'},
 {id='chapter',revision='r3',at_step='c',type='chapter',title='Chapter',text='Admitted chapter.'},
 {id='future',revision='r4',at_step='d',type='chapter',title='SECRET TITLE',text='SECRET PROSE'},
}}
local controller=ZGV.CampaignAdmission.New(metadata,char)
ZGV.CampaignData={CollectAdmitted=function()return controller:Collect()end,
 CollectPresented=function()return controller:History()end,
 MarkPresented=function(_,_,id,revision)return controller:MarkPresented(id,revision)end}
local function admit(step)
 local arrivals=controller:Observe({{source_step_id=step,kind='accept',quest_id=1}},{})
 for _,arrival in ipairs(arrivals)do D:OnAdmission('reg',arrival)end
end
local function context()return D:Context('reg')end
local function visible()
 local entry=context();ZGV.Presentation.storyEntry=entry;ZGV.Presentation.storyOpen=true
 assert(D:MarkVisible(entry));return entry
end
local function close(interrupted)
 D:Close(context(),interrupted);ZGV.Presentation.storyOpen=false
end
for _,kind in ipairs({'context','moment','chapter'})do assert(D:Mode(kind)=='cue')end
assert(not D:SetMode('future','open') and not D:SetMode('moment','invalid'))
assert(D:SetMode('moment','open') and D:SetMode('chapter','open'))
admit('a');assert(context().id=='context' and not context().autoOpen)
assert(#controller:History()==0,'snapshot marked presentation')
assert(not D:RecallPrevious('reg'),'unpresented passage entered recall')
-- A quiet context backlog must not prevent a newly configured moment opening.
admit('b');assert(context().id=='moment' and context().autoOpen)
local moment=visible();assert(#controller:History()==1)
local order=char.campaignAdmission.guides.pilot.passages.moment.presented_order
assert(D:MarkVisible(moment) and char.campaignAdmission.guides.pilot.passages.moment.presented_order==order)
-- New arrivals never replace an open reader or drain automatically on close.
admit('c');assert(context().id=='moment' and not context().autoOpen)
close(false);assert(context().id=='context' and not context().autoOpen)
visible();close(false);assert(context().id=='chapter' and not context().autoOpen)
-- Recall excludes eligible-but-unpresented and future passages.
assert(D:RecallPrevious('reg'));assert(context().id=='context')
visible();assert(#controller:History()==2)
close(false);assert(context().id=='chapter')
visible();assert(#controller:History()==3)
local history=controller:History()
assert(history[1].id=='moment' and history[2].id=='context' and history[3].id=='chapter')
for _,entry in ipairs(history)do assert(entry.id~='future' and entry.body~='SECRET PROSE')end
-- Combat tucks the selected passage without replacing it or forcing a reopen.
combat=true;close(true);assert(context().id=='chapter' and not context().autoOpen)
assert(not D:RecallPrevious('reg'))
combat=false;assert(context().id=='chapter' and not context().autoOpen)
-- Activation/reload folds history, with preferences and first-presentation order intact.
ZGV.Presentation.storyOpen=false;D:BeginSession();assert(not context().autoOpen)
assert(loadfile(root..'/CampaignDelivery.lua'))();D=ZGV.CampaignDelivery
assert(D:Mode('moment')=='open' and not context().autoOpen and #controller:History()==3)
-- Guide switching cannot carry an automatic request into a later visit.
char={};ZGV.db.char=char;controller=ZGV.CampaignAdmission.New(metadata,char)
D:BeginSession();admit('b');assert(context().autoOpen)
D:Context('other');assert(not context().autoOpen)
D:BeginSession();D:OnAdmission('other',{id='moment',revision='r2',live=true})
assert(not D:Context('other').autoOpen)
-- Keep an existing legacy reader stable when compiled arrivals become available.
ZGV.Presentation.storyOpen=true;ZGV.Presentation.storyEntry={id='legacy',persistent=true}
assert(not context())
ZGV.Presentation.storyOpen=false;ZGV.Presentation.storyEntry=nil
-- Busy arrivals are quiet; clearing the interruption does not force them open.
for _,busy in ipairs({'combat','casting','dialog','hidden'})do
 char={};ZGV.db.char=char;controller=ZGV.CampaignAdmission.New(metadata,char)
 ZGV.Presentation.storyOpen=false;D:BeginSession()
 combat=busy=='combat';casting=busy=='casting'
 QuestFrame=busy=='dialog' and {IsShown=function()return true end} or nil
 ZGV.Frame.IsVisible=function()return busy~='hidden' end
 admit('b');assert(not context().autoOpen and #controller:History()==0)
 combat=false;casting=false;QuestFrame=nil;ZGV.Frame.IsVisible=function()return true end
 assert(not context().autoOpen)
end
-- A pending encounter restored after reload can become eligible, but stays quiet.
char={};ZGV.db.char=char;D:BeginSession()
local gated={guide={id='pilot'},narration={{id='pending',revision='r5',at_step='a',type='moment',text='Safe pending',requires={quest_rewarded=1}}}}
controller=ZGV.CampaignAdmission.New(gated,char)
controller:Observe({{source_step_id='a',kind='accept',quest_id=1}},{rewards={[1]=false}})
controller=ZGV.CampaignAdmission.New(gated,char)
local arrivals=controller:Observe({},{rewards={[1]=true}})
assert(#arrivals==1 and not arrivals[1].live)
D:OnAdmission('reg',arrivals[1]);assert(not context().autoOpen)
-- Revised prose has neither inherited history nor a recall route.
gated.narration[1].revision='changed';controller=ZGV.CampaignAdmission.New(gated,char)
assert(#controller:History()==0 and not context() and not D:RecallPrevious('reg'))
print('PASS delivery: per-type persistence, opt-in live opening, quiet backlog, stable reader, combat/busy/reload deferral, presented-only recall/order and revision safety')

char={};ZGV.db.char=char;controller=ZGV.CampaignAdmission.New(metadata,char)
ZGV.Presentation.storyOpen=false;D:BeginSession();admit('a');admit('b')
visible();close(false);visible();close(false)
assert(context().id=='context','default reread did not select most recently presented passage')
