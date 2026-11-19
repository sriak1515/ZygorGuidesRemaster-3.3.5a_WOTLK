-- Read-only snapshot for external capture tools. No work is done until called.
function ZygorRigState()
 local z=ZygorGuidesViewer
 local guide,step=z.CurrentGuide,z.CurrentStep
 local n=z.CampaignNarration
 local record,position,manual,reader,entry
 if n then record,position,manual,reader,entry=n:GetReportInternals() end
 local button=n and n.storyButton
 local char=z.db and z.db.char
 local progress=char and char.guide_progress and char.guide_progress[z.CurrentGuideName or '']
 local saved=char and char.campaignNarration
 local story=saved and saved.guides and record and saved.guides[record.guide_id]
 local passages={}
 if story and record then
  for _,p in ipairs(record.passages) do
   if (story.pending and story.pending[p.id]==p.revision) or (story.delivered and story.delivered[p.id]==p.revision) then
    passages[#passages+1]=p.id
   end
  end
 end
 local function panel(frame,overflow)
  local p={shown=not not (frame and frame:IsVisible()),overflow=not not overflow}
  if frame then
   p.left,p.bottom,p.width,p.height=frame:GetLeft(),frame:GetBottom(),frame:GetWidth(),frame:GetHeight()
   p.scale=frame:GetEffectiveScale()
  end
  return p
 end
 local function overflow(frame)
  if not frame or not frame:IsVisible() then return false end
  for _,region in ipairs({frame:GetRegions()}) do
   if region:IsObjectType('FontString') and region:IsVisible() and region:GetStringHeight() > region:GetHeight()+0.5 then return true end
  end
  for _,child in ipairs({frame:GetChildren()}) do if overflow(child) then return true end end
  return false
 end
 local storyOverflow=overflow(reader) or (reader and reader:IsVisible() and reader.body and reader.scroll and reader.body:GetStringHeight()>reader.scroll:GetHeight()+0.5)
 local goals={}
 for i,g in ipairs(step and step.goals or {}) do
  goals[i]={index=i,done=g.status=='complete',status=g.status or 'unknown'}
 end
 return {screen_height=GetScreenHeight()*UIParent:GetEffectiveScale(),guide_id=record and record.guide_id or (guide and guide.title),guide_title=guide and guide.title,
  step_count=guide and guide.steps and #guide.steps or 0,step_index=z.CurrentStepNum,
  story_button={shown=not not (button and button:IsShown()),visible=not not (button and button:IsVisible()),enabled=not not (button and button:IsEnabled())},
  step_indicator=z.RemasterFrames and z.RemasterFrames.stepLabel and z.RemasterFrames.stepLabel:GetText(),
  step_id=position or (step and step.label),saved_step_id=progress and progress.source_step_id,
  journey_done_transient=not not manual,goals=goals,unlocked_passage_ids=passages,
  shown_passage_id=entry and entry.id,panels={journey=panel(ZygorGuidesViewerFrame,overflow(ZygorGuidesViewerFrame)),
  story=panel(reader,storyOverflow),minimap=panel(Minimap,false)}}
end
