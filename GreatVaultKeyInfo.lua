-- globals
local C_MythicPlus, C_ChallengeMode, C_WeeklyRewards = C_MythicPlus, C_ChallengeMode, C_WeeklyRewards
local C_Item, DifficultyUtil, PVPUtil, CreateFrame, max, tostring = C_Item, DifficultyUtil, PVPUtil, CreateFrame, max, tostring
local WeeklyRewardsFrame, GameTooltip, Enum = WeeklyRewardsFrame, GameTooltip, Enum
local GameTooltip_SetTitle, GameTooltip_AddNormalLine, GameTooltip_AddHighlightLine, GameTooltip_AddColoredLine, GameTooltip_AddBlankLineToTooltip = GameTooltip_SetTitle, GameTooltip_AddNormalLine, GameTooltip_AddHighlightLine, GameTooltip_AddColoredLine, GameTooltip_AddBlankLineToTooltip
local WEEKLY_REWARDS_MYTHIC_TOP_RUNS, WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT, WEEKLY_REWARDS_COMPLETE_MYTHIC = WEEKLY_REWARDS_MYTHIC_TOP_RUNS, WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT, WEEKLY_REWARDS_COMPLETE_MYTHIC
local WEEKLY_REWARDS_HEROIC, WEEKLY_REWARDS_MYTHIC, WEEKLY_REWARDS_MAXED_REWARD, WEEKLY_REWARDS_CURRENT_REWARD, WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, WEEKLY_REWARDS_ITEM_LEVEL_HEROIC = WEEKLY_REWARDS_HEROIC, WEEKLY_REWARDS_MYTHIC, WEEKLY_REWARDS_MAXED_REWARD, WEEKLY_REWARDS_CURRENT_REWARD, WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, WEEKLY_REWARDS_ITEM_LEVEL_HEROIC
local GREEN_FONT_COLOR, GRAY_FONT_COLOR, GENERIC_FRACTION_STRING = GREEN_FONT_COLOR, GRAY_FONT_COLOR, GENERIC_FRACTION_STRING
local WeeklyRewardsUtil = WeeklyRewardsUtil
local L = LibStub("AceLocale-3.0"):GetLocale("GreatVaultKeyInfo")

-- locals
-- this is from https://wago.tools/db2/MythicPlusSeasonRewardLevels?page=1&sort[WeeklyRewardLevel]=asc&filter[MythicPlusSeasonID]=99
local DungeonItemLevelsBySeason = {
	-- The War Within Season 1
	[99] = {
		["HEROIC"] = 593,
		["MYTHIC"] = 603,
		[2] = 606,
		[3] = 610,
		[4] = 610,
		[5] = 613,
		[6] = 613,
		[7] = 616,
		[8] = 619,
		[9] = 619,
		[10] = 623,
	},
}
local WorldItemLevelsBySeason = {
	-- The War Within Season 1
	[99] = {
		[1] = 584,
		[2] = 587,
		[3] = 590,
		[4] = 593,
		[5] = 600,
		[6] = 606,
		[7] = 610,
		[8] = 616,
	},
}
local ItemTiers = {
	"myth",
	"hero",
	"champion",
	"veteran",
	"adventurer",
	-- explorer we don't care about because it can't be rewarded in the vault
}
-- this is the minimum starting item level to go up a tier
local ItemTierItemMinimumLevelBySeason = {
	-- The War Within Season 1
	[99] = {
		["myth"] = 623,
		["hero"] = 610,
		["champion"] = 597,
		["veteran"] = 584,
		["adventurer"] = 571,
	},
}
-- ranks within each tier
local ItemTierItemLevelsBySeason = {
	-- The War Within Season 1
	[99] = {
		["myth"] = {
			[623] = 1,
			[626] = 2,
			[629] = 3,
			[632] = 4,
			[636] = 5,
			[639] = 6,
		},
		["hero"] = {
			[610] = 1,
			[613] = 2,
			[616] = 3,
			[619] = 4,
			[623] = 5,
			[626] = 6,
		},
		["champion"] = {
			[597] = 1,
			[600] = 2,
			[603] = 3,
			[606] = 4,
			[610] = 5,
			[613] = 6,
			[616] = 7,
			[619] = 8,
		},
		["veteran"] = {
			[584] = 1,
			[587] = 2,
			[590] = 3,
			[593] = 4,
			[597] = 5,
			[600] = 6,
			[603] = 7,
			[606] = 8,
		},
		["adventurer"] = {
			[571] = 1,
			[574] = 2,
			[577] = 3,
			[580] = 4,
			[584] = 5,
			[587] = 6,
			[590] = 7,
			[593] = 8,
		},
	},
}
local ItemTierNumRanksBySeason = {
	-- The War Within Season 1
	[99] = {
		["myth"] = 6,
		["hero"] = 6,
		["champion"] = 8,
		["veteran"] = 8,
		["adventurer"] = 8,
	},
}
-- fallback value
local WEEKLY_MAX_DUNGEON_THRESHOLD = 8

-- event frame
local GreatVaultKeyInfoFrame = CreateFrame("Frame")
GreatVaultKeyInfoFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
GreatVaultKeyInfoFrame:SetScript("OnEvent", function(self, event_name, ...)
	if self[event_name] then
		return self[event_name](self, event_name, ...)
	end
end)

-- utility functions
local GetItemTierFromItemLevel = function(itemLevel)
	local _, _, rewardSeasonID = C_MythicPlus.GetCurrentSeasonValues()
	local currentSeasonItemTiers = ItemTierItemMinimumLevelBySeason[rewardSeasonID]
	if currentSeasonItemTiers then
		for _, itemTierKey in ipairs(ItemTiers) do
			local itemTierItemLevel = currentSeasonItemTiers[itemTierKey]
			if itemLevel >= itemTierItemLevel then
				local rank = ItemTierItemLevelsBySeason[rewardSeasonID][itemTierKey][itemLevel]
				local maxRank = ItemTierNumRanksBySeason[rewardSeasonID][itemTierKey]
				return ("%d - %d/%d %s"):format(itemLevel, rank, maxRank, L[itemTierKey])
			end
		end
	end
	return tostring(itemLevel)
end
local GetCurrentSeasonRewardLevels = function()
	local _, _, rewardSeasonID = C_MythicPlus.GetCurrentSeasonValues()
	local currentSeasonRewardLevels = DungeonItemLevelsBySeason[rewardSeasonID]
	if currentSeasonRewardLevels then
		return currentSeasonRewardLevels.HEROIC, currentSeasonRewardLevels.MYTHIC
	end
end
local GetRewardLevelFromKeystoneLevel = function(keystoneLevel, blizzItemLevel)
	local rewardLevel = C_MythicPlus.GetRewardLevelFromKeystoneLevel(keystoneLevel)
	if rewardLevel == 0 then
		-- sometimes Blizzard forgets to make their code work properly
		local _, _, rewardSeasonID = C_MythicPlus.GetCurrentSeasonValues()
		local currentSeasonRewardLevels = DungeonItemLevelsBySeason[rewardSeasonID]
		if currentSeasonRewardLevels then
			if keystoneLevel > 10 then
				keystoneLevel = 10
			end
			return currentSeasonRewardLevels[keystoneLevel] or blizzItemLevel or 0
		end
	end
	return rewardLevel
end
local GetRewardLevelFromDelveLevel = function(delveLevel, blizzItemLevel)
	local _, _, rewardSeasonID = C_MythicPlus.GetCurrentSeasonValues()
	local currentSeasonRewardLevels = WorldItemLevelsBySeason[rewardSeasonID]
	if currentSeasonRewardLevels then
		if delveLevel > 8 then
			delveLevel = 8
		end
		return currentSeasonRewardLevels[delveLevel] or blizzItemLevel or 0
	end
	return blizzItemLevel or 0
end
local comparison = function(entry1, entry2)
	if entry1.level == entry2.level then
		return entry1.mapChallengeModeID < entry2.mapChallengeModeID
	else
		return entry1.level > entry2.level
	end
end

-- calculate the max reward threshold
local calcMaxRewardThreshold = WEEKLY_MAX_DUNGEON_THRESHOLD
function GreatVaultKeyInfoFrame:CHALLENGE_MODE_MAPS_UPDATE()
	calcMaxRewardThreshold = 0
	local activities = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Activities)
	for _, activityInfo in ipairs(activities) do
		calcMaxRewardThreshold = max(calcMaxRewardThreshold, activityInfo.threshold)
	end
	-- fallback to the default if result is empty
	if calcMaxRewardThreshold == 0 then
		calcMaxRewardThreshold = WEEKLY_MAX_DUNGEON_THRESHOLD
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
		if self.info.threshold == calcMaxRewardThreshold then
			GameTooltip_AddHighlightLine(GameTooltip, string.format(numDungeons == 1 and L.run_this_week or L.runs_this_week, numDungeons))
		else
			GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, self.info.threshold))
		end
	end
	if #runHistory > 0 then
		table.sort(runHistory, comparison)
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
		if self.info.threshold == calcMaxRewardThreshold and numDungeons > calcMaxRewardThreshold then
			GameTooltip_AddHighlightLine(GameTooltip, string.format(L.top_runs_this_week, self.info.threshold, numDungeons))
		elseif self.info.threshold ~= 1 then
			GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, self.info.threshold))
		end
	end
	if #runHistory > 0 then
		table.sort(runHistory, comparison)
		local maxLines = self.info.threshold == calcMaxRewardThreshold and #runHistory or self.info.threshold
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
			local maxLines = self.info.threshold == calcMaxRewardThreshold and numMythicPlus + numMythic or self.info.threshold
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
			local maxLines = self.info.threshold == calcMaxRewardThreshold and numDungeons or self.info.threshold
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
	local activities = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.World)
	local activity = activities[1]
	if activity and activity.level and activity.level > 0 then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, threshold))
		local previousActivityLevel = 12
		local previousActivityProgress = 0
		for i = 1, 3 do
			activity = activities[i]
			if activity and activity.level and activity.level > 0 and activity.level < previousActivityLevel and previousActivityProgress < threshold then
				local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activity.id)
				local itemLevel = itemLink and C_Item.GetDetailedItemLevelInfo(itemLink) or nil
				local reward = GetItemTierFromItemLevel(GetRewardLevelFromDelveLevel(activity.level, itemLevel))
				local tier = GREAT_VAULT_WORLD_TIER:format(activity.level)
				local rewardText = string.format("(%s) %s", reward, tier)
				local maxLines = min(activity.progress, threshold)
				for i = previousActivityProgress + 1, maxLines do
					if i == threshold or i == activities[3].progress then
						GameTooltip_AddColoredLine(GameTooltip, rewardText, GREEN_FONT_COLOR)
					else
						GameTooltip_AddHighlightLine(GameTooltip, rewardText)
					end
				end
				previousActivityLevel = activity.level
				previousActivityProgress = activity.progress
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

-- overrides SetProgressText
-- original: https://github.com/BigWigsMods/WoWUI/blob/live/AddOns/Blizzard_WeeklyRewards/Blizzard_WeeklyRewards.lua
local SetProgressText = function(self, text)
	local activityInfo = self.info
	if text then
		self.Progress:SetText(text)
	elseif self.hasRewards then
		self.Progress:SetText(nil)
	elseif self.unlocked then
		if activityInfo.type == Enum.WeeklyRewardChestThresholdType.Raid then
			local name = DifficultyUtil.GetDifficultyName(activityInfo.level)
			self.Progress:SetText(name)
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
			local itemLevel
			if itemLink then
				itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
			end
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

-- Dungeons
WeeklyRewardsFrame.Activities[5].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[5].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[5].SetProgressText = SetProgressText
WeeklyRewardsFrame.Activities[6].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[6].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[6].SetProgressText = SetProgressText
WeeklyRewardsFrame.Activities[7].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[7].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[7].SetProgressText = SetProgressText

-- World
WeeklyRewardsFrame.Activities[8].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[8].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[8].SetProgressText = SetProgressText
WeeklyRewardsFrame.Activities[9].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[9].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[9].SetProgressText = SetProgressText
WeeklyRewardsFrame.Activities[10].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[10].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[10].SetProgressText = SetProgressText
