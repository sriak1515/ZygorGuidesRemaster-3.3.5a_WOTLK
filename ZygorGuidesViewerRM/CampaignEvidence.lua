-- Production evidence provider for the campaign's private v1 preview guides.
-- Bridges the viewer's CampaignPreview owner gates to real client observations.
--
-- Contract (CampaignPreview:SetEvidenceProvider): the provider receives an
-- identity-bound request and returns a plain table that echoes every identity
-- field, carries its own observation time, and supplies each requested gate as
-- an explicit verified fact with owner, kind and provenance. Requests,
-- bookmarks, requirements profiles and policy text are never evidence. Facts
-- the client cannot observe stay absent: absent facts deny access.
--
-- Fail-closed return path: the Blackfathom Deeps interlude (KAL-08) has no
-- playable guide and no owner records yet. The return gate therefore never
-- verifies and no return record is produced; the opening view suspends at the
-- declared pause boundary and the continuation view stays locked until KAL-08
-- exists and earns its observation checkpoint.
--
-- The gate identities here must stay byte-identical to the activating policy
-- that is delivered with the private preview. A mismatch is denied by the
-- viewer's own fact validation (fail-closed), never silently repaired.

local ZGV=ZygorGuidesViewer
if not ZGV or not ZGV.CampaignPreview or not ZGV.CampaignData then return end
local P=ZGV.CampaignPreview

-- Gate identities shared with the delivered activating policy.
local EVIDENCE={
	prior={owner='kal06',kind='external-checkpoint',checkpoint_id='KAL-06.TOWER_PROLOGUE'},
	pause={owner='campaign',kind='full-pause'},
	returned={owner='kal08',kind='return-and-readiness'},
}

-- Campaign checkpoint proofs. Leader-scoped exactly as declared in the
-- campaign route sources: the human player's character must be the named
-- leader, and every listed quest must appear in a fresh quest-history
-- observation. Keyed by stable checkpoint identity, not by compiled source.
-- Test/dev surface: the suite injects synthetic checkpoints here; runtime
-- verification semantics are unchanged.
local CHECKPOINTS={
	['KAL-06.TOWER_PROLOGUE']={player='Thaloren',quests={965,966,967}},
}

local function now() return GetTime and GetTime() end
local function call(fn,...)
	if type(fn)~='function' then return nil end
	local ok,result=pcall(fn,...)
	if ok then return result end
	return nil
end
local function yes(value) return value==true or value==1 end

-- Mirror the viewer's own roster unit enumeration: the real five-member raid
-- layout, or the actual party layout when not in a raid. Raid slot ordering is
-- never identity; the viewer proves that separately.
local function groupUnits()
	local raid=call(GetNumRaidMembers)
	if type(raid)=='number' and raid>0 then
		if raid~=5 then return nil end
		return {'raid1','raid2','raid3','raid4','raid5'}
	end
	if call(GetNumPartyMembers)~=4 then return nil end
	return {'player','party1','party2','party3','party4'}
end

-- Fresh client quest history on every request. The mutable viewer-level
-- completed-quest caches are never consulted here.
local function freshHistory()
	if type(GetQuestsCompleted)~='function' then return nil end
	local history={}
	GetQuestsCompleted(history)
	if type(history)~='table' then return nil end
	return history
end

local function checkpointVerified(definition,history,player)
	local proof=CHECKPOINTS[definition.checkpoint_id]
	if not proof or player~=proof.player then return nil end
	for _,quest in ipairs(proof.quests) do
		if not history[quest] then return nil end
	end
	return true
end

local function pauseVerified()
	local units=groupUnits()
	if not units then return nil end
	for _,unit in ipairs(units) do
		if not yes(call(UnitExists,unit)) then return nil end
		if not yes(call(UnitIsConnected,unit)) then return nil end
		if call(UnitAffectingCombat,unit) then return nil end
		if call(UnitIsDeadOrGhost,unit) then return nil end
	end
	return true
end

local function provenance(name,definition,player)
	if definition.kind=='external-checkpoint' then
		local proof=CHECKPOINTS[definition.checkpoint_id]
		return 'CampaignEvidence: fresh client quest history confirms '
			..table.concat(proof.quests,'/')..' rewarded on '..player..' ('..definition.checkpoint_id..')'
	elseif definition.kind=='full-pause' then
		return 'CampaignEvidence: live group observation, five members present, connected, out of combat and alive'
	end
	return 'CampaignEvidence: '..name
end

local function provide(request)
	if type(request)~='table' then return nil end
	local time=now()
	if type(time)~='number' or time~=time or time<0 or time==math.huge then return nil end
	local history=freshHistory()
	local player=call(UnitName,'player')
	if type(history)~='table' or type(player)~='string' or player=='' then return nil end
	local response={
		source_sha256=request.source_sha256,
		policy_version=request.policy_version,
		policy_sha256=request.policy_sha256,
		roster=request.roster,
		session=request.session,
		observed_at=time,
		gates={},
	}
	for name,definition in pairs(EVIDENCE) do
		local verified=nil
		if definition.kind=='external-checkpoint' then
			verified=checkpointVerified(definition,history,player)
		elseif definition.kind=='full-pause' then
			verified=pauseVerified()
		elseif definition.kind=='return-and-readiness' then
			-- The KAL-08 interlude owns this gate. Until that guide exists and
			-- earns its observation checkpoint, no client observation may stand
			-- in for the missing owner records.
			verified=nil
		end
		if verified then
			response.gates[name]={
				verified=true,
				owner=definition.owner,
				kind=definition.kind,
				checkpoint_id=definition.checkpoint_id,
				provenance=provenance(name,definition,player),
			}
		end
	end
	-- No return_record is supplied: CampaignPreview:ReturnEvidence denies a
	-- missing record, so the continuation view stays locked (fail-closed).
	return response
end

ZGV.CampaignEvidence={
	Gates=EVIDENCE,
	Checkpoints=CHECKPOINTS,
	Provider=provide,
}

P:SetEvidenceProvider(provide)
