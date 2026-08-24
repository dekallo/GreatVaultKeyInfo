local _, GreatVaultKeyInfo = ...

-- globals
local C_MythicPlus, C_ChallengeMode, C_WeeklyRewards = C_MythicPlus, C_ChallengeMode, C_WeeklyRewards
local C_Item, DifficultyUtil, PVPUtil, CreateFrame, max, tostring, C_Timer = C_Item, DifficultyUtil, PVPUtil, CreateFrame, max, tostring, C_Timer
local WeeklyRewardsFrame, GameTooltip, Enum = WeeklyRewardsFrame, GameTooltip, Enum
local GameTooltip_SetTitle, GameTooltip_AddNormalLine, GameTooltip_AddHighlightLine, GameTooltip_AddColoredLine, GameTooltip_AddBlankLineToTooltip = GameTooltip_SetTitle, GameTooltip_AddNormalLine, GameTooltip_AddHighlightLine, GameTooltip_AddColoredLine, GameTooltip_AddBlankLineToTooltip
local WEEKLY_REWARDS_MYTHIC_TOP_RUNS, WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT, WEEKLY_REWARDS_COMPLETE_MYTHIC = WEEKLY_REWARDS_MYTHIC_TOP_RUNS, WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT, WEEKLY_REWARDS_COMPLETE_MYTHIC
local WEEKLY_REWARDS_HEROIC, WEEKLY_REWARDS_MYTHIC, WEEKLY_REWARDS_MAXED_REWARD, WEEKLY_REWARDS_CURRENT_REWARD, WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, WEEKLY_REWARDS_ITEM_LEVEL_HEROIC = WEEKLY_REWARDS_HEROIC, WEEKLY_REWARDS_MYTHIC, WEEKLY_REWARDS_MAXED_REWARD, WEEKLY_REWARDS_CURRENT_REWARD, WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, WEEKLY_REWARDS_ITEM_LEVEL_HEROIC
local GREEN_FONT_COLOR, GRAY_FONT_COLOR, GENERIC_FRACTION_STRING, GREAT_VAULT_WORLD_TIER = GREEN_FONT_COLOR, GRAY_FONT_COLOR, GENERIC_FRACTION_STRING, GREAT_VAULT_WORLD_TIER
local WeeklyRewardsUtil = WeeklyRewardsUtil
local L = LibStub("AceLocale-3.0"):GetLocale("GreatVaultKeyInfo")

-- seasonal data (access with [seasonId])
local RaidItemLevels = GreatVaultKeyInfo.RaidItemLevels
local DungeonItemLevels = GreatVaultKeyInfo.DungeonItemLevels
local WorldItemLevels = GreatVaultKeyInfo.WorldItemLevels
local ItemTierItemMinimumLevel = GreatVaultKeyInfo.ItemTierItemMinimumLevel
local ItemTierItemLevels = GreatVaultKeyInfo.ItemTierItemLevels
local ItemTierNumRanks = GreatVaultKeyInfo.ItemTierNumRanks
local ExampleRaidRewardItemID = GreatVaultKeyInfo.ExampleRaidRewardItemID

-- shared constants
local ItemTiers = GreatVaultKeyInfo.ItemTiers
local WEEKLY_MAX_DUNGEON_THRESHOLD = GreatVaultKeyInfo.WEEKLY_MAX_DUNGEON_THRESHOLD
local WEEKLY_MAX_WORLD_THRESHOLD = GreatVaultKeyInfo.WEEKLY_MAX_WORLD_THRESHOLD

-- event frame
local GreatVaultKeyInfoFrame = CreateFrame("Frame")
GreatVaultKeyInfoFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
GreatVaultKeyInfoFrame:SetScript("OnEvent", function(self, event_name, ...)
	if self[event_name] then
		return self[event_name](self, event_name, ...)
	end
end)

-- utility functions
local GetRewardSeasonID = function()
	local _, _, rewardSeasonID = C_MythicPlus.GetCurrentSeasonValues()
	return rewardSeasonID
end
local GetItemTierFromItemLevel = function(itemLevel)
	local rewardSeasonID = GetRewardSeasonID()
	local currentSeasonItemTiers = ItemTierItemMinimumLevel[rewardSeasonID]
	if currentSeasonItemTiers then
		for _, itemTierKey in ipairs(ItemTiers) do
			local itemTierItemLevel = currentSeasonItemTiers[itemTierKey]
			if itemLevel >= itemTierItemLevel then
				local rank = ItemTierItemLevels[rewardSeasonID][itemTierKey][itemLevel]
				local maxRank = ItemTierNumRanks[rewardSeasonID][itemTierKey]
				return ("%d - %d/%d %s"):format(itemLevel, rank, maxRank, L[itemTierKey])
			end
		end
	end
	return tostring(itemLevel)
end
local GetCurrentSeasonRewardLevels = function()
	local rewardSeasonID = GetRewardSeasonID()
	local currentSeasonRewardLevels = DungeonItemLevels[rewardSeasonID]
	if currentSeasonRewardLevels then
		return currentSeasonRewardLevels.HEROIC, currentSeasonRewardLevels.MYTHIC
	end
end
local GetExampleRaidRewardItemID = function()
	local rewardSeasonID = GetRewardSeasonID()
	return ExampleRaidRewardItemID[rewardSeasonID]
end
local GetRewardLevelFromRaidLevel = function(raidLevel, blizzItemLevel)
	local rewardSeasonID = GetRewardSeasonID()
	local currentSeasonRewardLevels = RaidItemLevels[rewardSeasonID]
	if currentSeasonRewardLevels then
		-- prefer the blizz item level because it takes into account bosses killed
		return blizzItemLevel or currentSeasonRewardLevels[raidLevel] or 0
	end
	return blizzItemLevel or 0
end
local GetRewardLevelFromKeystoneLevel = function(keystoneLevel, blizzItemLevel)
	local rewardSeasonID = GetRewardSeasonID()
	local currentSeasonRewardLevels = DungeonItemLevels[rewardSeasonID]
	if currentSeasonRewardLevels then
		if keystoneLevel > 10 then
			keystoneLevel = 10
		end
		return currentSeasonRewardLevels[keystoneLevel] or blizzItemLevel or 0
	end
	-- as a fallback use Blizzard's unreliable API
	return blizzItemLevel or C_MythicPlus.GetRewardLevelFromKeystoneLevel(keystoneLevel) or 0
end
local GetRewardLevelFromDelveLevel = function(delveLevel, blizzItemLevel)
	local rewardSeasonID = GetRewardSeasonID()
	local currentSeasonRewardLevels = WorldItemLevels[rewardSeasonID]
	if currentSeasonRewardLevels then
		if delveLevel > 8 then
			delveLevel = 8
		end
		return currentSeasonRewardLevels[delveLevel] or blizzItemLevel or 0
	end
	return blizzItemLevel or 0
end
local CompareRuns = function(entry1, entry2)
	if entry1.level == entry2.level then
		return entry1.mapChallengeModeID < entry2.mapChallengeModeID
	else
		return entry1.level > entry2.level
	end
end

-- calculate the max reward threshold
local calcMaxActivitiesThreshold = WEEKLY_MAX_DUNGEON_THRESHOLD
local calcMaxWorldThreshold = WEEKLY_MAX_WORLD_THRESHOLD
function GreatVaultKeyInfoFrame:CHALLENGE_MODE_MAPS_UPDATE()
	-- Dungeons
	calcMaxActivitiesThreshold = 0
	local activities = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Activities)
	for _, activityInfo in ipairs(activities) do
		calcMaxActivitiesThreshold = max(calcMaxActivitiesThreshold, activityInfo.threshold)
	end
	if calcMaxActivitiesThreshold == 0 then -- fallback to the default if result is empty
		calcMaxActivitiesThreshold = WEEKLY_MAX_DUNGEON_THRESHOLD
	end
	-- World
	calcMaxWorldThreshold = 0
	local world = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.World)
	for _, activityInfo in ipairs(world) do
		calcMaxWorldThreshold = max(calcMaxWorldThreshold, activityInfo.threshold)
	end
	if calcMaxWorldThreshold == 0 then -- fallback to the default if result is empty
		calcMaxWorldThreshold = WEEKLY_MAX_DUNGEON_THRESHOLD
	end
end

-- reward progress tooltips (for unearned tiers)
local HandleInProgressDungeonRewardTooltip = function(self)
	GameTooltip_SetTitle(GameTooltip, L.reward_locked)
	local runHistory = C_MythicPlus.GetRunHistory(false, true)
	local numHeroic, numMythic, numMythicPlus = C_WeeklyRewards.GetNumCompletedDungeonRuns()
	local numDungeons = numHeroic + numMythic + numMythicPlus
	GameTooltip_AddNormalLine(GameTooltip, string.format(L.run_to_unlock, self.info.threshold - numDungeons))
	if numDungeons > 0 then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		if self.info.threshold == calcMaxActivitiesThreshold then
			GameTooltip_AddHighlightLine(GameTooltip, string.format(numDungeons == 1 and L.run_this_week or L.runs_this_week, numDungeons))
		else
			GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, self.info.threshold))
		end
	end
	if #runHistory > 0 then
		table.sort(runHistory, CompareRuns)
		for i = 1, #runHistory do
			if runHistory[i] then
				local runInfo = runHistory[i]
				local name = C_ChallengeMode.GetMapUIInfo(runInfo.mapChallengeModeID)
				local rewardLevel = GetRewardLevelFromKeystoneLevel(runInfo.level)
				if i == #runHistory or i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$s) %1$d - %2$s", runInfo.level, name, GetItemTierFromItemLevel(rewardLevel)), GREEN_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%3$s) %1$d - %2$s", runInfo.level, name, GetItemTierFromItemLevel(rewardLevel)))
				end
			end
		end
	end
	if numMythic > 0 or numHeroic > 0 then
		local HEROIC_ITEM_LEVEL, MYTHIC_ITEM_LEVEL = GetCurrentSeasonRewardLevels()
		if numMythic > 0 then
			for i = 1, numMythic do
				if i == numMythicPlus + numMythic or i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), GetItemTierFromItemLevel(MYTHIC_ITEM_LEVEL)), GREEN_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), GetItemTierFromItemLevel(MYTHIC_ITEM_LEVEL)))
				end
			end
		end
		if numHeroic > 0 then
			for i = 1, numHeroic do
				if i == numMythicPlus + numMythic + numHeroic or i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_HEROIC, GetItemTierFromItemLevel(HEROIC_ITEM_LEVEL)), GREEN_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_HEROIC, GetItemTierFromItemLevel(HEROIC_ITEM_LEVEL)))
				end
			end
		end
	end
end

-- earned reward tooltips, as well as run history on the top tier
local HandleEarnedDungeonRewardTooltip = function(self, blizzItemLevel)
	local itemLevel
	if DifficultyUtil.ID.DungeonChallenge == C_WeeklyRewards.GetDifficultyIDForActivityTier(self.info.activityTierID) then
		itemLevel = GetRewardLevelFromKeystoneLevel(self.info.level, blizzItemLevel)
	else
		itemLevel = blizzItemLevel
	end
	if self:IsCompletedAtHeroicLevel() then
		GameTooltip_AddNormalLine(GameTooltip, string.format(WEEKLY_REWARDS_ITEM_LEVEL_HEROIC, itemLevel))
	else
		GameTooltip_AddNormalLine(GameTooltip, string.format(WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, itemLevel, self.info.level))
	end
	local hasData, nextActivityTierID, nextLevel, nextItemLevel = C_WeeklyRewards.GetNextActivitiesIncrease(self.info.activityTierID, self.info.level)
	if hasData and DifficultyUtil.ID.DungeonChallenge == C_WeeklyRewards.GetDifficultyIDForActivityTier(nextActivityTierID) then
		-- GetNextActivitiesIncrease just returns current level + 1 as next level, have to use GetNextMythicPlusIncrease to get useful data
		hasData, nextLevel, nextItemLevel = C_WeeklyRewards.GetNextMythicPlusIncrease(self.info.level)
	end
	if hasData and nextLevel and nextItemLevel then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		GameTooltip_AddColoredLine(GameTooltip, string.format(WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, nextItemLevel), GREEN_FONT_COLOR)
		if self.info.threshold == 1 then
			GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT, nextLevel))
		else
			GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_COMPLETE_MYTHIC, nextLevel, self.info.threshold))
		end
	end
	local runHistory = C_MythicPlus.GetRunHistory(false, true)
	local numHeroic, numMythic, numMythicPlus = C_WeeklyRewards.GetNumCompletedDungeonRuns()
	local numDungeons = numHeroic + numMythic + numMythicPlus
	if numDungeons > 0 then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		if self.info.threshold == calcMaxActivitiesThreshold and numDungeons > calcMaxActivitiesThreshold then
			GameTooltip_AddHighlightLine(GameTooltip, string.format(L.top_runs_this_week, self.info.threshold, numDungeons))
		elseif self.info.threshold ~= 1 then
			GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, self.info.threshold))
		end
	end
	if #runHistory > 0 then
		table.sort(runHistory, CompareRuns)
		local maxLines = self.info.threshold == calcMaxActivitiesThreshold and #runHistory or self.info.threshold
		for i = 1, maxLines do
			if runHistory[i] then
				local runInfo = runHistory[i]
				local name = C_ChallengeMode.GetMapUIInfo(runInfo.mapChallengeModeID)
				local rewardLevel = GetRewardLevelFromKeystoneLevel(runInfo.level)
				if i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$s) %1$d - %2$s", runInfo.level, name, GetItemTierFromItemLevel(rewardLevel)), GREEN_FONT_COLOR)
				elseif i > self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$s) %1$d - %2$s", runInfo.level, name, GetItemTierFromItemLevel(rewardLevel)), GRAY_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%3$s) %1$d - %2$s", runInfo.level, name, GetItemTierFromItemLevel(rewardLevel)))
				end
			end
		end
	end
	if numMythic > 0 or numHeroic > 0 then
		local HEROIC_ITEM_LEVEL, MYTHIC_ITEM_LEVEL = GetCurrentSeasonRewardLevels()
		if numMythic > 0 then
			local maxLines = self.info.threshold == calcMaxActivitiesThreshold and numMythicPlus + numMythic or self.info.threshold
			for i = numMythicPlus + 1, maxLines do
				if i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), GetItemTierFromItemLevel(MYTHIC_ITEM_LEVEL)), GREEN_FONT_COLOR)
				elseif i > self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), GetItemTierFromItemLevel(MYTHIC_ITEM_LEVEL)), GRAY_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), GetItemTierFromItemLevel(MYTHIC_ITEM_LEVEL)))
				end
			end
		end
		if numHeroic > 0 then
			local maxLines = self.info.threshold == calcMaxActivitiesThreshold and numDungeons or self.info.threshold
			for i = numMythicPlus + numMythic + 1, maxLines do
				if i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_HEROIC, GetItemTierFromItemLevel(HEROIC_ITEM_LEVEL)), GREEN_FONT_COLOR)
				elseif i > self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_HEROIC, GetItemTierFromItemLevel(HEROIC_ITEM_LEVEL)), GRAY_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_HEROIC, GetItemTierFromItemLevel(HEROIC_ITEM_LEVEL)))
				end
			end
		end
	end
end

local AddWorldProgress = function(threshold)
	local sortedProgress = C_WeeklyRewards.GetSortedProgressForActivity(Enum.WeeklyRewardChestThresholdType.World, true)
	if not sortedProgress or #sortedProgress == 0 then
		return
	end
	GameTooltip_AddBlankLineToTooltip(GameTooltip)
	if threshold == calcMaxWorldThreshold then
		local numWorld = 0
		for i = 1, #sortedProgress do
			numWorld = numWorld + sortedProgress[i].numPoints
		end
		if numWorld > calcMaxWorldThreshold then
			GameTooltip_AddHighlightLine(GameTooltip, string.format(L.top_runs_this_week, threshold, numWorld))
		else
			GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, threshold))
		end
	else
		GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, threshold))
	end
	local linesAdded = 0
	for i = 1, #sortedProgress do
		local entry = sortedProgress[i]
		local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(entry.activityTierID)
		local itemLevel = itemLink and C_Item.GetDetailedItemLevelInfo(itemLink) or nil
		local reward = GetItemTierFromItemLevel(GetRewardLevelFromDelveLevel(entry.difficulty, itemLevel))
		local tier = GREAT_VAULT_WORLD_TIER:format(entry.difficulty)
		local rewardText = string.format("(%s) %s", reward, tier)
		for j = 1, entry.numPoints do
			linesAdded = linesAdded + 1
			if linesAdded == threshold or (linesAdded < threshold and i == #sortedProgress and j == entry.numPoints) then
				GameTooltip_AddColoredLine(GameTooltip, rewardText, GREEN_FONT_COLOR)
				if threshold ~= calcMaxWorldThreshold then
					return
				end
			elseif linesAdded < threshold then
				GameTooltip_AddHighlightLine(GameTooltip, rewardText)
			else
				GameTooltip_AddColoredLine(GameTooltip, rewardText, GRAY_FONT_COLOR)
			end
		end
	end
end

local ShowIncompleteWorldTooltip = function(self, title, description)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -7, -11)
	GameTooltip_SetTitle(GameTooltip, title)
	GameTooltip_AddNormalLine(GameTooltip, description:format(self.info.threshold - self.info.progress))
	AddWorldProgress(self.info.threshold)
	GameTooltip:Show()
end

local HandlePreviewWorldRewardTooltip = function(self, itemLevel, upgradeItemLevel, nextLevel)
	GameTooltip_AddNormalLine(GameTooltip, string.format(WEEKLY_REWARDS_ITEM_LEVEL_WORLD, itemLevel, self.info.level))
	if upgradeItemLevel then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		GameTooltip_AddColoredLine(GameTooltip, string.format(WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, upgradeItemLevel), GREEN_FONT_COLOR)
		GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_COMPLETE_WORLD, nextLevel))
	end
	AddWorldProgress(self.info.threshold)
end

-- overrides CanShowPreviewItemTooltip
-- original: https://github.com/BigWigsMods/WoWUI/blob/live/AddOns/Blizzard_WeeklyRewards/Blizzard_WeeklyRewards.lua
local CanShowPreviewItemTooltip = function(self)
	return self.info and not C_WeeklyRewards.CanClaimRewards()
end

-- overrides ShowPreviewItemTooltip
-- original: https://github.com/BigWigsMods/WoWUI/blob/live/AddOns/Blizzard_WeeklyRewards/Blizzard_WeeklyRewards.lua
local ShowPreviewItemTooltip = function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -7, -11)
	GameTooltip_SetTitle(GameTooltip, WEEKLY_REWARDS_CURRENT_REWARD)
	local itemLink, upgradeItemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(self.info.id)
	local itemLevel, upgradeItemLevel
	if itemLink then
		itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
	end
	if upgradeItemLink then
		upgradeItemLevel = C_Item.GetDetailedItemLevelInfo(upgradeItemLink)
	end
	if not itemLevel and not self.unlocked then
		if self.info.type == Enum.WeeklyRewardChestThresholdType.Activities then
			HandleInProgressDungeonRewardTooltip(self)
		elseif self.info.type == Enum.WeeklyRewardChestThresholdType.World then
			local description = GREAT_VAULT_REWARDS_WORLD_INCOMPLETE
			if self.info.index == 2 then
				description = GREAT_VAULT_REWARDS_WORLD_COMPLETED_FIRST
			elseif self.info.index == 3 then
				description = GREAT_VAULT_REWARDS_WORLD_COMPLETED_SECOND
			end
			ShowIncompleteWorldTooltip(self, WEEKLY_REWARDS_UNLOCK_REWARD, description)
		end
	else
		self.UpdateTooltip = nil
		if self.info.type == Enum.WeeklyRewardChestThresholdType.Raid then
			self:HandlePreviewRaidRewardTooltip(itemLevel, upgradeItemLevel)
		elseif self.info.type == Enum.WeeklyRewardChestThresholdType.Activities then
			HandleEarnedDungeonRewardTooltip(self, itemLevel)
		elseif self.info.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
			self:HandlePreviewPvPRewardTooltip(itemLevel, upgradeItemLevel)
		elseif self.info.type == Enum.WeeklyRewardChestThresholdType.World then
			local hasData, _, nextLevel, nextItemLevel = C_WeeklyRewards.GetNextActivitiesIncrease(self.info.activityTierID, self.info.level)
			if hasData then
				upgradeItemLevel = nextItemLevel
			else
				nextLevel = self.info.level + 1
			end
			HandlePreviewWorldRewardTooltip(self, itemLevel, upgradeItemLevel, nextLevel)
		end
		if not upgradeItemLevel then
			GameTooltip_AddBlankLineToTooltip(GameTooltip)
			GameTooltip_AddHighlightLine(GameTooltip, WEEKLY_REWARDS_MAXED_REWARD)
		end
	end
	GameTooltip:Show()
end

local pendingActivity = {}
function GreatVaultKeyInfoFrame:ITEM_DATA_LOAD_RESULT(event, id, success)
	local exampleRaidRewardItemID = GetExampleRaidRewardItemID()
	if not exampleRaidRewardItemID or id == exampleRaidRewardItemID then
		self:UnregisterEvent(event)
		if id == exampleRaidRewardItemID and success then
			for i = 1, #pendingActivity do
				pendingActivity[i]:Refresh(pendingActivity[i].info)
			end
			pendingActivity = {}
		end
	end
end

-- overrides SetProgressText
-- original: https://github.com/BigWigsMods/WoWUI/blob/live/AddOns/Blizzard_WeeklyRewards/Blizzard_WeeklyRewards.lua
local SetProgressText = function(self, text, isRetry)
	local activityInfo = self.info
	if text then
		self.Progress:SetText(text)
	elseif self.hasRewards then
		self.Progress:SetText(nil)
	elseif self.unlocked then
		if activityInfo.type == Enum.WeeklyRewardChestThresholdType.Raid then
			local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activityInfo.id)
			local detailedItemLevelInfo = itemLink and C_Item.GetDetailedItemLevelInfo(itemLink)
			if not detailedItemLevelInfo then
				pendingActivity[#pendingActivity + 1] = self
				if #pendingActivity == 1 then
					local exampleRaidRewardItemID = GetExampleRaidRewardItemID()
					if exampleRaidRewardItemID then
						GreatVaultKeyInfoFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
						C_Item.RequestLoadItemDataByID(exampleRaidRewardItemID)
					elseif not isRetry then
						-- missing season data, try again once
						pendingActivity = {}
						C_Timer.After(2, function()
							self:SetProgressText(nil, true)
						end)
					end
				end
			end
			local itemLevel = itemLink and detailedItemLevelInfo or nil
			local rewardLevel = GetRewardLevelFromRaidLevel(activityInfo.level, itemLevel)
			self.Progress:SetJustifyH("RIGHT")
			self.Progress:SetFormattedText("%s\n%s", DifficultyUtil.GetDifficultyName(activityInfo.level), GetItemTierFromItemLevel(rewardLevel))
		elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.Activities then
			local HEROIC_ITEM_LEVEL, MYTHIC_ITEM_LEVEL = GetCurrentSeasonRewardLevels()
			self.Progress:SetJustifyH("RIGHT")
			if self:IsCompletedAtHeroicLevel() then
				self.Progress:SetFormattedText("%s\n%s", WEEKLY_REWARDS_HEROIC, GetItemTierFromItemLevel(HEROIC_ITEM_LEVEL))
			elseif activityInfo.level >= 2 then
				local rewardLevel = GetRewardLevelFromKeystoneLevel(activityInfo.level)
				self.Progress:SetFormattedText("+%d\n%s", activityInfo.level, GetItemTierFromItemLevel(rewardLevel))
			else
				local rewardLevel = MYTHIC_ITEM_LEVEL
				self.Progress:SetFormattedText("%s\n%s", WEEKLY_REWARDS_MYTHIC:format(activityInfo.level), GetItemTierFromItemLevel(rewardLevel))
			end
		elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
			self.Progress:SetText(PVPUtil.GetTierName(activityInfo.level))
		elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.World then
			local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activityInfo.id)
			local itemLevel = itemLink and C_Item.GetDetailedItemLevelInfo(itemLink) or nil
			local rewardLevel = GetRewardLevelFromDelveLevel(activityInfo.level, itemLevel)
			self.Progress:SetJustifyH("RIGHT")
			self.Progress:SetFormattedText("%s\n%s", GREAT_VAULT_WORLD_TIER:format(activityInfo.level), GetItemTierFromItemLevel(rewardLevel))
		end
	else
		if C_WeeklyRewards.CanClaimRewards() then
			-- no progress on incomplete activites during claiming
			self.Progress:SetText(nil)
		else
			self.Progress:SetFormattedText(GENERIC_FRACTION_STRING, activityInfo.progress, activityInfo.threshold)
		end
	end
end

-- iterate and hook activity frames by type
for _, frame in ipairs(WeeklyRewardsFrame.Activities) do
	local frameType = frame.type
	if frameType == Enum.WeeklyRewardChestThresholdType.Raid then
		frame.SetProgressText = SetProgressText
	elseif frameType == Enum.WeeklyRewardChestThresholdType.Activities or frameType == Enum.WeeklyRewardChestThresholdType.World then
		frame.CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
		frame.ShowPreviewItemTooltip = ShowPreviewItemTooltip
		frame.SetProgressText = SetProgressText
	end
end
